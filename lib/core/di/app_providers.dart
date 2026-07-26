import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_controller.dart';
import '../../services/line_event_queue.dart';
import '../../stores/config_store.dart';
import '../http/dio_client.dart';
import '../line/line_config.dart';
import '../line/line_manager.dart';
import '../line/line_probe_outcome.dart';
import '../line/line_repository.dart';
import '../line/public_net_probe.dart';
import '../storage/app_database.dart';
import '../storage/kv_store.dart';
import '../utils/app_logger.dart';
import '../utils/line_switch_util.dart';
import '../ws/ws_event.dart';
import '../ws/ws_manager.dart';

/// KvStore：需在 main 中 `KvStore.open()` 后通过 override 注入。
final kvStoreProvider = Provider<KvStore>(
  (ref) => throw UnimplementedError('kvStoreProvider 未初始化（需在 main override）'),
);

/// 全局 drift 数据库。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 全局唯一 WebSocket 管理器。
final wsManagerProvider = Provider<WsManager>((ref) {
  final ws = WsManager();
  ref.onDispose(ws.dispose);
  return ws;
});

/// forceReconnect / 主动切线导致的短暂 disconnected 计数，不计入 WS 切线 streak。
class ExpectedWsReconnectNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void note() => state++;

  /// 消费一次；若无可消费返回 false。
  bool consume() {
    if (state <= 0) return false;
    state--;
    return true;
  }

  void reset() => state = 0;
}

final expectedWsReconnectProvider =
    NotifierProvider<ExpectedWsReconnectNotifier, int>(
  ExpectedWsReconnectNotifier.new,
);

/// 当前线路。初值读 KV，切换时写回 KV 并强制 WS 重连到新线路。
class LineNotifier extends Notifier<LineConfig> {
  Future<bool>? _lineCheckFuture;

  /// 探活世代：手切 / 自动切线时递增，作废仍在飞的后台探活，避免把 chip 重新打成「连接中」。
  int _probeEpoch = 0;

  /// 最近一次并发探活中可用的线路（按延迟升序）。供注册/登录失败换线使用。
  List<LineConfig> lastHealthyLines = const [];

  /// API 连接失败自动切线：单飞，并行失败共用一次切线结果。
  Future<bool>? _apiFailoverFuture;

  /// 静默探活单飞。
  Future<void>? _silentProbeFuture;

  /// 登录/面板/failover 批量探活是否进行中（供静默探避让）。
  bool _batchProbeBusy = false;

  /// 静默探冷却（与任意批量探活共用）。
  static const Duration silentProbeCooldown = Duration(minutes: 5);

  /// 静默合并时，旧通线缓存有效期。
  static const Duration silentHealthyTtl = Duration(minutes: 10);

  /// 本波已试过的线路（含失败的当前线）；请求成功后清空。
  final Set<String> _apiFailoverTriedIds = {};

  /// 本波已成功自动切线次数（限制连跳，避免多次 WS 重连）。
  int _apiFailoverSwitchCount = 0;

  /// 上一波自动切线成功并恢复请求后的冷却截止时间。
  DateTime? _apiFailoverCooldownUntil;

  /// WS 连续断开自动切线单飞。
  Future<bool>? _wsFailoverFuture;

  /// WS 自动切线冷却截止。
  DateTime? _wsFailoverCooldownUntil;

  void _bumpProbeEpoch() => _probeEpoch++;

  @override
  LineConfig build() {
    final kv = ref.read(kvStoreProvider);
    LineRepository.instance.bindKv(kv);
    // Debug 本机联调：强制本地线路（避免 Hive 残留 de010 线路 id）
    if (kDebugMode) {
      return kLocalDevLine;
    }
    return lineById(kv.getLineId());
  }

  /// 拉取远程线路表；若当前线被移除则切到新表第一条。
  ///
  /// [baseUrl] 非空时走该绝对 API 根（`https://host/api`），不依赖当前 Dio baseUrl。
  /// 返回是否成功打到服务端（含 notModified）。
  Future<bool> refreshRemoteLineConfig({String? baseUrl}) async {
    if (!ref.mounted) return false;
    final dio = ref.read(dioClientProvider).dio;
    final beforeVersion = LineRepository.instance.configVersion;
    final beforeIds =
        LineRepository.instance.productionLines.map((e) => e.id).join(',');
    final reached = await LineRepository.instance.refreshFromRemote(
      dio,
      baseUrl: baseUrl,
    );
    if (!ref.mounted || !reached) return reached;
    final afterVersion = LineRepository.instance.configVersion;
    final afterIds =
        LineRepository.instance.productionLines.map((e) => e.id).join(',');
    final changed =
        beforeVersion != afterVersion || beforeIds != afterIds;
    if (!changed) return true;
    final currentId = state.id;
    if (currentId == kLocalDevLine.id) return true;
    final still = LineRepository.instance.productionLines
        .any((e) => e.id == currentId);
    if (still) {
      // 同 id 可能换了 host：刷新 state
      state = lineById(currentId);
      return true;
    }
    final next = LineRepository.instance.defaultLine;
    final kv = ref.read(kvStoreProvider);
    await kv.setLineId(next.id);
    if (!ref.mounted) return true;
    state = next;
    log.i('[Line] current removed by remote, switch -> ${next.id}');
    final token = kv.accessToken;
    if (token != null && token.isNotEmpty) {
      await onLineSwitched();
    }
    return true;
  }

  /// 当前线拉配置失败时，用已探通线路的绝对 baseUrl 补拉。
  Future<bool> _refreshRemoteConfigFromHealthy(
    List<LineConfig> healthy,
  ) async {
    if (!ref.mounted || healthy.isEmpty) return false;
    final preferred = <LineConfig>[
      if (healthy.any((e) => e.id == state.id))
        healthy.firstWhere((e) => e.id == state.id),
      ...healthy.where((e) => e.id != state.id),
    ];
    for (final line in preferred) {
      if (line.id == kLocalDevLine.id) continue;
      final ok = await refreshRemoteLineConfig(baseUrl: line.baseUrl);
      if (!ref.mounted) return false;
      if (ok) {
        log.i('[Line] remote config via healthy ${line.id}@${line.host}');
        return true;
      }
    }
    return false;
  }

  /// 登出时回主线路（保留本地开发线路；仅清理不可用的备用线路场景）。
  Future<void> resetToPrimaryLine() async {
    if (state.id == kLocalDevLine.id || state.id == kDefaultLine.id) return;
    final kv = ref.read(kvStoreProvider);
    await kv.setLineId(kDefaultLine.id);
    if (!ref.mounted) return;
    state = kDefaultLine;
    log.i('[Line] reset -> ${kDefaultLine.id}');
  }

  /// 登录前探测当前线路（不自动改线路）。
  Future<bool> ensureAvailableLine() => checkCurrentLineStatus();

  /// 切换线路。对齐 uniapp：先应用线路，再探活；失败仅 chip 显示连接失败。
  Future<LineSwitchOutcome> switchTo(String lineId) async {
    _bumpProbeEpoch();
    final line = lineById(lineId);
    final fromLine = state;
    final kv = ref.read(kvStoreProvider);
    final token = kv.accessToken;
    final isLoggedIn = token != null && token.isNotEmpty;
    final config = ref.read(configStoreProvider);
    final chipStatus = LineSwitchUtil.chipStatus(
      isAuthenticated: isLoggedIn,
      lineStatus: config.lineStatus,
      wsStatus: config.wsStatus,
    );

    if (line.id == state.id) {
      if (LineSwitchUtil.shouldReconnectSameLine(
        isAuthenticated: isLoggedIn,
        chipStatus: chipStatus,
      )) {
        final ok = await _probeLineWithStatus(line, triggerSource: 'same_line_reconnect');
        if (!ref.mounted) {
          return LineSwitchOutcome(success: false, switched: false, line: line);
        }
        await ref.read(lineEventQueueProvider).record(
              eventType: 'line_switch',
              triggerSource: 'same_line_reconnect',
              line: line,
              fromLineId: fromLine.id,
              toLineId: line.id,
              success: ok,
            );
        if (ok) unawaited(ref.read(lineEventQueueProvider).flush());
        if (ok && isLoggedIn) await onLineSwitched();
        return LineSwitchOutcome(success: ok, switched: false, line: line);
      }
      return LineSwitchOutcome(success: true, switched: false, line: line);
    }

    await _applyLineId(line, kv: kv);
    final ok = await _probeLineWithStatus(line, triggerSource: 'manual_switch');
    if (!ref.mounted) {
      return LineSwitchOutcome(success: false, switched: true, line: line);
    }
    await ref.read(lineEventQueueProvider).record(
          eventType: 'line_switch',
          triggerSource: 'manual_switch',
          line: line,
          fromLineId: fromLine.id,
          toLineId: line.id,
          success: ok,
        );
    if (ok) unawaited(ref.read(lineEventQueueProvider).flush());
    if (ok && isLoggedIn) {
      await onLineSwitched();
    }
    return LineSwitchOutcome(success: ok, switched: true, line: line);
  }

  /// 采用已探通线路：只切线、不重探，避免 chip 再闪「连接中」。
  /// 用于手切失败后的倒计时自动切线。
  Future<LineSwitchOutcome> adoptHealthyLine(
    String lineId, {
    String triggerSource = 'manual_fail_autofailover',
  }) async {
    _bumpProbeEpoch();
    final line = lineById(lineId);
    final fromLine = state;
    final kv = ref.read(kvStoreProvider);
    final token = kv.accessToken;
    final isLoggedIn = token != null && token.isNotEmpty;

    if (line.id == state.id) {
      if (!ref.mounted) {
        return LineSwitchOutcome(success: false, switched: false, line: line);
      }
      ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connected);
      return LineSwitchOutcome(success: true, switched: false, line: line);
    }

    await _applyLineId(line, kv: kv);
    if (!ref.mounted) {
      return LineSwitchOutcome(success: false, switched: true, line: line);
    }
    ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connected);
    await ref.read(lineEventQueueProvider).record(
          eventType: 'line_switch',
          triggerSource: triggerSource,
          line: line,
          fromLineId: fromLine.id,
          toLineId: line.id,
          success: true,
        );
    unawaited(ref.read(lineEventQueueProvider).flush());
    if (isLoggedIn) await onLineSwitched();
    log.i('[Line] adopt healthy ${fromLine.id} -> ${line.id} (no reprobe)');
    return LineSwitchOutcome(success: true, switched: true, line: line);
  }

  /// 线路切换后重连 WS。对齐 uniapp：不切回「正在初始化」，仅用 chatSyncLoading。
  Future<void> onLineSwitched() async {
    final kv = ref.read(kvStoreProvider);
    final token = kv.accessToken;
    if (token == null || token.isEmpty) return;
    final config = ref.read(configStoreProvider.notifier);
    config.setChatSyncLoading(true);
    unawaited(config.loadConfig());
    // forceReconnect 会先发 disconnected 再 connecting：忽略这次断开，避免误计 WS 切线 streak。
    ref.read(expectedWsReconnectProvider.notifier).note();
    ref.read(wsManagerProvider).forceReconnect(
          wsUrl: state.wsUrl,
          token: token,
          devId: kv.effectiveDevId,
        );
    unawaited(_clearLineSwitchLoadingLater());
  }

  /// WS 长时间未连上时结束顶部 loading，避免一直转圈。
  Future<void> _clearLineSwitchLoadingLater() async {
    await Future<void>.delayed(const Duration(seconds: 12));
    if (!ref.mounted) return;
    final cfg = ref.read(configStoreProvider);
    if (!cfg.chatSyncLoading) return;
    ref.read(configStoreProvider.notifier).setChatSyncLoading(false);
    ref.read(configStoreProvider.notifier).setAppInit(true);
  }

  /// API 连接类失败时静默切到已探通线路；无候选 / 无网 / 冷却则返回 false。
  Future<bool> fallbackOnConnectionError() async {
    final existing = _apiFailoverFuture;
    if (existing != null) return existing;
    final future = _runApiConnectionFailover();
    _apiFailoverFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_apiFailoverFuture, future)) {
        _apiFailoverFuture = null;
      }
    }
  }

  Future<bool> _runApiConnectionFailover() async {
    if (!ref.mounted) return false;
    final deviceOffline = await _isDeviceOffline();
    if (LineSwitchUtil.shouldSkipApiConnectionFailover(
      deviceOffline: deviceOffline,
      hasTriedInWave: _apiFailoverTriedIds.isNotEmpty,
      cooldownUntil: _apiFailoverCooldownUntil,
    )) {
      log.i(
        '[Line] api failover skipped '
        '(offline=$deviceOffline tried=${_apiFailoverTriedIds.length})',
      );
      return false;
    }

    // 本波已切过：不再连跳到第三条线（WS 重连成本高）；由拦截器靠新 baseUrl 重试。
    if (_apiFailoverSwitchCount >=
        LineSwitchUtil.apiFailoverMaxSwitchesPerWave) {
      log.i('[Line] api failover: already switched this wave, skip further');
      return false;
    }

    _apiFailoverTriedIds.add(state.id);
    final next = bestHealthyCandidate(
      excludeId: state.id,
      excludeIds: _apiFailoverTriedIds,
      requireFreshProbe: true,
    );
    if (next == null) {
      log.w('[Line] api failover: no healthy candidate');
      return false;
    }

    final outcome = await adoptHealthyLine(
      next.id,
      triggerSource: 'api_connection_failover',
    );
    if (!ref.mounted) return false;
    if (!outcome.success || !outcome.switched) {
      _apiFailoverTriedIds.add(next.id);
      log.w('[Line] api failover adopt failed -> ${next.id}');
      return false;
    }
    _apiFailoverTriedIds.add(next.id);
    _apiFailoverSwitchCount++;
    log.i('[Line] api failover -> ${next.id}');
    return true;
  }

  /// WS 连续断开（未达 connected）后自动切到已探通备用线。
  Future<bool> failoverOnWsFailure() async {
    final existing = _wsFailoverFuture;
    if (existing != null) return existing;
    final future = _runWsDisconnectFailover();
    _wsFailoverFuture = future;
    try {
      return await future;
    } finally {
      if (identical(_wsFailoverFuture, future)) {
        _wsFailoverFuture = null;
      }
    }
  }

  Future<bool> _runWsDisconnectFailover() async {
    if (!ref.mounted) return false;
    final deviceOffline = await _isDeviceOffline();
    if (deviceOffline) {
      log.i('[Line] ws failover skipped (device offline)');
      return false;
    }
    final cooldownUntil = _wsFailoverCooldownUntil;
    if (cooldownUntil != null && DateTime.now().isBefore(cooldownUntil)) {
      log.i('[Line] ws failover skipped (cooldown)');
      return false;
    }

    var next = bestHealthyCandidate(
      excludeId: state.id,
      requireFreshProbe: true,
    );
    if (next == null) {
      log.i('[Line] ws failover: refreshHealthyLines');
      await refreshHealthyLines(triggerSource: 'ws_disconnect_failover_probe');
      if (!ref.mounted) return false;
      next = bestHealthyCandidate(
        excludeId: state.id,
        requireFreshProbe: true,
      );
      next ??= bestHealthyCandidate(
        excludeId: state.id,
        requireFreshProbe: false,
      );
    }
    if (next == null) {
      log.w('[Line] ws failover: no healthy candidate');
      _wsFailoverCooldownUntil = DateTime.now().add(const Duration(seconds: 15));
      return false;
    }

    final outcome = await adoptHealthyLine(
      next.id,
      triggerSource: 'ws_disconnect_failover',
    );
    if (!ref.mounted) return false;
    if (!outcome.success || !outcome.switched) {
      log.w('[Line] ws failover adopt failed -> ${next.id}');
      _wsFailoverCooldownUntil = DateTime.now().add(const Duration(seconds: 15));
      return false;
    }
    _wsFailoverCooldownUntil = DateTime.now().add(
      LineSwitchUtil.wsDisconnectFailoverCooldown,
    );
    log.i('[Line] ws failover -> ${next.id}');
    return true;
  }

  Future<bool> _isDeviceOffline() async {
    try {
      final values = await Connectivity().checkConnectivity();
      if (values.contains(ConnectivityResult.wifi) ||
          values.contains(ConnectivityResult.mobile) ||
          values.contains(ConnectivityResult.ethernet) ||
          values.contains(ConnectivityResult.vpn)) {
        return false;
      }
      return values.isEmpty ||
          values.every((e) => e == ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  /// 请求成功：结束本波自动切线，并在本波有过切线时进入冷却。
  void clearApiFailoverWave({bool armCooldown = true}) {
    if (armCooldown &&
        (_apiFailoverTriedIds.isNotEmpty || _apiFailoverSwitchCount > 0)) {
      _apiFailoverCooldownUntil = DateTime.now().add(
        LineSwitchUtil.apiConnectionFailoverCooldown,
      );
    }
    _apiFailoverTriedIds.clear();
    _apiFailoverSwitchCount = 0;
  }

  void markCurrentLineConnected({String source = 'request_success'}) {
    // 仅 HTTP 成功结束自动切线波；WS 连上时清波会误伤并行重试 / 提前进冷却。
    if (source == 'request_success') {
      clearApiFailoverWave();
    }
    if (!ref.mounted) return;
    final config = ref.read(configStoreProvider);
    if (config.lineStatus == WsStatus.connected) return;
    ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connected);
    log.i('[Line] mark connected by $source -> ${state.id}');
  }

  Future<void> _applyLineId(LineConfig line, {required KvStore kv}) async {
    await kv.setLineId(line.id);
    if (!ref.mounted) return;
    state = line;
    log.i('[Line] switch -> ${line.id}');
    unawaited(ref.read(configStoreProvider.notifier).loadConfig());
  }

  /// 从近期探活结果里选延迟最低的可用线（排除 [excludeId] 与 [excludeIds]）。
  ///
  /// [requireFreshProbe] 为 true 时只采信 [LineSwitchUtil.apiFailoverProbeMaxAge]
  /// 内的成功探活，避免 adopt 到过期「通」缓存。
  LineConfig? bestHealthyCandidate({
    required String excludeId,
    Set<String> excludeIds = const {},
    bool requireFreshProbe = false,
  }) {
    final tried = {...excludeIds, excludeId};
    final cache = ref.read(lineProbeCacheProvider);
    bool usable(String id) {
      if (!requireFreshProbe) return true;
      final entry = cache[id];
      if (entry == null) return false;
      return LineSwitchUtil.isProbeFreshForApiFailover(entry);
    }

    final fromLast = LineSwitchUtil.nextHealthyCandidate(
      healthySortedByLatency: lastHealthyLines,
      triedIds: tried,
    );
    if (fromLast != null && usable(fromLast.id)) return fromLast;

    final healthy = <({LineConfig line, int ms})>[];
    for (final line in kVisibleLines) {
      if (tried.contains(line.id)) continue;
      final entry = cache[line.id];
      if (entry == null || !entry.ok) continue;
      if (requireFreshProbe &&
          !LineSwitchUtil.isProbeFreshForApiFailover(entry)) {
        continue;
      }
      healthy.add((line: line, ms: entry.latencyMs ?? 999999));
    }
    healthy.sort((a, b) => a.ms.compareTo(b.ms));
    return healthy.isEmpty ? null : healthy.first.line;
  }

  /// 对齐 uniapp probeLineWithStatus：更新 chip 探活状态。
  Future<bool> _probeLineWithStatus(
    LineConfig line, {
    String triggerSource = 'current_line_check',
  }) async {
    if (!ref.mounted) return false;
    final epoch = _probeEpoch;
    ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connecting);
    final manager = ref.read(lineManagerProvider);
    final manualFast = triggerSource == 'manual_switch' ||
        triggerSource == 'same_line_reconnect' ||
        triggerSource == 'manual_fail_autofailover';
    final outcome = await manager.probeDetailed(
      line,
      timeout: manualFast
          ? LineManager.manualProbeTimeout
          : LineManager.defaultProbeTimeout,
      // 本地调试会串行试多个 host；手切再降到 1 次，避免叠太久。
      maxAttempts: manualFast
          ? (line.id == kLocalDevLine.id ? 1 : LineManager.manualProbeMaxAttempts)
          : LineManager.defaultProbeMaxAttempts,
      retryDelay: manualFast
          ? LineManager.manualProbeRetryDelay
          : LineManager.defaultProbeRetryDelay,
    );
    final ok = outcome.ok;
    if (!ref.mounted) return ok;
    if (epoch != _probeEpoch) {
      log.i(
        '[Line] probe superseded ($triggerSource ${line.id}), '
        'skip status write',
      );
      return false;
    }
    _rememberProbe(line.id, outcome);
    if (ok &&
        kDebugMode &&
        line.id == kLocalDevLine.id &&
        manager.resolvedLocalDevLine != null &&
        manager.resolvedLocalDevLine!.host != state.host) {
      state = manager.resolvedLocalDevLine!;
      log.i('[Line] local dev resolved -> ${state.host}');
    }
    ref.read(configStoreProvider.notifier).setLineStatus(
          ok ? WsStatus.connected : WsStatus.disconnected,
        );
    await ref.read(lineEventQueueProvider).record(
          eventType: 'line_probe_result',
          triggerSource: triggerSource,
          line: line,
          success: ok,
          latencyMs: outcome.latencyMs,
          errorCategory: ok ? null : (outcome.errorCategory ?? 'unknown'),
          errorMessage: outcome.errorMessage,
          apiPath: '/line/ping',
          httpStatus: outcome.httpStatus,
        );
    // 成功/失败都上传：登录页未注册用户探活失败也要进后台。
    unawaited(ref.read(lineEventQueueProvider).flush());
    return ok;
  }

  void _rememberProbe(String lineId, LineProbeOutcome outcome) {
    if (!ref.mounted) return;
    ref.read(lineProbeCacheProvider.notifier).upsert(
          lineId,
          LineProbeCacheEntry.fromOutcome(outcome),
        );
  }

  /// 探测线路并更新 chip。
  ///
  /// [allowFallback]=true（登录/注册页）：并发探活全部线上线路；
  /// 当前线通则保留，否则自动切到延迟最低的可用线。
  /// Debug 本机线路优先探本地；本地不通时再探线上（方便真机无 adb 时验证）。
  /// [exhaustiveProbe]=true：全量探完每条（面板「重新检测」）；默认分批截断。
  Future<bool> checkCurrentLineStatus({
    bool allowFallback = false,
    bool exhaustiveProbe = false,
  }) {
    return _lineCheckFuture ??= () async {
      await refreshRemoteLineConfig();
      if (!allowFallback) {
        return _probeLineWithStatus(state);
      }
      if (kDebugMode && state.id == kLocalDevLine.id) {
        final localOk = await _probeLineWithStatus(
          state,
          triggerSource: 'auth_local_first',
        );
        if (localOk) return true;
        log.i('[Line] local unavailable, fallback to probeAll remotes');
      }
      return _probeAllAndSelectBest(exhaustive: exhaustiveProbe);
    }().whenComplete(() => _lineCheckFuture = null);
  }

  /// 并发探活刷新 [lastHealthyLines] 与探活缓存；不改当前线路、不改 chip 状态。
  /// 供消息页 3s 自动切线在缺少候选时补探。
  ///
  /// [exhaustive]=false：健康优先分批（每批 5、满 5 通停）；
  /// [exhaustive]=true：全量并发（面板重新检测）。
  Future<void> refreshHealthyLines({
    String triggerSource = 'autofailover_probe',
    bool exhaustive = false,
  }) async {
    if (!ref.mounted) return;
    _batchProbeBusy = true;
    try {
      final configReached = await refreshRemoteLineConfig();
      if (!ref.mounted) return;
      final manager = ref.read(lineManagerProvider);
      final prior = ref.read(lineProbeCacheProvider);
      final results = exhaustive
          ? await manager.probeAll(lines: kLines)
          : await manager.probeAllBatched(
              lines: kLines,
              priorHealth: prior,
            );
      if (!ref.mounted) return;

      final healthy = <({LineConfig line, int ms})>[];
      final cacheUpdates = <String, LineProbeCacheEntry>{};
      for (final r in results) {
        final outcome = r.outcome;
        final ms = outcome.latencyMs;
        cacheUpdates[r.line.id] = LineProbeCacheEntry.fromOutcome(outcome);
        await ref.read(lineEventQueueProvider).record(
              eventType: 'line_probe_result',
              triggerSource: triggerSource,
              line: r.line,
              success: outcome.ok,
              latencyMs: ms,
              errorCategory:
                  outcome.ok ? null : (outcome.errorCategory ?? 'unknown'),
              errorMessage: outcome.errorMessage,
              apiPath: '/line/ping',
              httpStatus: outcome.httpStatus,
            );
        if (outcome.ok && ms != null) {
          healthy.add((line: r.line, ms: ms));
        }
      }
      if (ref.mounted) {
        ref.read(lineProbeCacheProvider.notifier).upsertAll(cacheUpdates);
      }
      healthy.sort((a, b) => a.ms.compareTo(b.ms));
      lastHealthyLines = healthy.map((e) => e.line).toList(growable: false);
      // 当前线拉配置失败时：任意探通线都可补拉完整线路表。
      if (!configReached && lastHealthyLines.isNotEmpty) {
        await _refreshRemoteConfigFromHealthy(lastHealthyLines);
        if (!ref.mounted) return;
      }
      if (healthy.isEmpty && results.isNotEmpty) {
        await _recordPublicContrastRound(
          triggerSource: triggerSource,
          lineCount: results.length,
          okCount: 0,
          failCount: results.length,
        );
      }
      await ref.read(kvStoreProvider).setLastBatchProbeAtMs(
            DateTime.now().millisecondsSinceEpoch,
          );
      unawaited(ref.read(lineEventQueueProvider).flush());
    } finally {
      _batchProbeBusy = false;
    }
  }

  /// 回前台轻量静默探：最多 1 批 5 条；不切线、不改 chip、不 Toast。
  Future<void> silentProbeOnResume() {
    return _silentProbeFuture ??= () async {
      try {
        await _silentProbeOnResumeBody();
      } finally {
        _silentProbeFuture = null;
      }
    }();
  }

  Future<void> _silentProbeOnResumeBody() async {
    if (!ref.mounted) return;
    if (_lineCheckFuture != null || _batchProbeBusy) {
      log.i('[Line] silentProbe skip: batch probe busy');
      return;
    }
    if (ref.read(authControllerProvider) != AuthStatus.authenticated) {
      return;
    }
    final kv = ref.read(kvStoreProvider);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final last = kv.lastBatchProbeAtMs ?? 0;
    if (nowMs - last < silentProbeCooldown.inMilliseconds) {
      log.i('[Line] silentProbe skip: cooldown');
      return;
    }
    try {
      final values = await Connectivity().checkConnectivity();
      final offline = values.isEmpty ||
          values.every((e) => e == ConnectivityResult.none);
      if (offline) {
        log.i('[Line] silentProbe skip: offline');
        return;
      }
    } catch (_) {
      // connectivity 失败仍尝试探，由超时自然失败。
    }
    if (!ref.mounted || _lineCheckFuture != null || _batchProbeBusy) return;

    _batchProbeBusy = true;
    await kv.setLastBatchProbeAtMs(nowMs);
    try {
      final manager = ref.read(lineManagerProvider);
      final prior = ref.read(lineProbeCacheProvider);
      final results = await manager.probeAllBatched(
        lines: kLines,
        priorHealth: prior,
        maxBatches: 1,
      );
      if (!ref.mounted) return;

      final cacheUpdates = <String, LineProbeCacheEntry>{};
      var okCount = 0;
      for (final r in results) {
        final entry = LineProbeCacheEntry.fromOutcome(r.outcome);
        cacheUpdates[r.line.id] = entry;
        if (r.outcome.ok) okCount++;
        await ref.read(lineEventQueueProvider).record(
              eventType: 'line_probe_result',
              triggerSource: 'silent_resume',
              line: r.line,
              success: r.outcome.ok,
              latencyMs: r.outcome.latencyMs,
              errorCategory: r.outcome.ok
                  ? null
                  : (r.outcome.errorCategory ?? 'unknown'),
              errorMessage: r.outcome.errorMessage,
              apiPath: '/line/ping',
              httpStatus: r.outcome.httpStatus,
            );
      }
      if (ref.mounted) {
        ref.read(lineProbeCacheProvider.notifier).upsertAll(cacheUpdates);
      }
      final mergedCache = <String, LineProbeCacheEntry>{
        ...ref.read(lineProbeCacheProvider),
        ...cacheUpdates,
      };
      lastHealthyLines = mergeSilentHealthyLines(
        previousHealthy: lastHealthyLines,
        cache: mergedCache,
        batchResults: results,
        nowMs: DateTime.now().millisecondsSinceEpoch,
        ttlMs: silentHealthyTtl.inMilliseconds,
      );
      await ref.read(lineEventQueueProvider).record(
            eventType: 'line_probe_round',
            triggerSource: 'silent_resume',
            success: okCount > 0,
            extra: {
              'lineCount': results.length,
              'okCount': okCount,
              'failCount': results.length - okCount,
              'maxBatches': 1,
            },
          );
      unawaited(ref.read(lineEventQueueProvider).flush());
      log.i(
        '[Line] silentProbe probed=${results.length} ok=$okCount '
        'healthy=${lastHealthyLines.length}',
      );
    } finally {
      _batchProbeBusy = false;
    }
  }

  /// Domestic-only: when a full probe round has zero healthy lines, contrast
  /// against a China public endpoint to classify user-network vs line outage.
  Future<void> _recordPublicContrastRound({
    required String triggerSource,
    required int lineCount,
    required int okCount,
    required int failCount,
  }) async {
    if (!ref.mounted) return;
    final phone = ref.read(kvStoreProvider).loginPhone;
    final domestic = PublicNetProbe.isDomesticEligible(loginPhone: phone);
    if (!domestic) {
      await ref.read(lineEventQueueProvider).record(
            eventType: 'line_probe_round',
            triggerSource: triggerSource,
            success: false,
            extra: const PublicProbeResult(ok: false, host: '').toExtra(
              lineCount: lineCount,
              okCount: okCount,
              failCount: failCount,
              triggerSource: triggerSource,
              domesticEligible: false,
              skipReason: 'foreign_or_unknown',
            ),
          );
      return;
    }

    final public = await PublicNetProbe.probe();
    if (!ref.mounted) return;
    log.i(
      '[Line] public contrast ok=${public.ok} host=${public.host} '
      'ms=${public.latencyMs} (all lines failed)',
    );
    await ref.read(lineEventQueueProvider).record(
          eventType: 'line_probe_round',
          triggerSource: triggerSource,
          success: public.ok,
          latencyMs: public.latencyMs,
          errorCategory: public.ok ? null : public.errorCategory,
          errorMessage: public.errorMessage,
          apiPath: public.host.isEmpty ? null : 'public://${public.host}',
          httpStatus: public.httpStatus,
          extra: public.toExtra(
            lineCount: lineCount,
            okCount: okCount,
            failCount: failCount,
            triggerSource: triggerSource,
            domesticEligible: true,
          ),
        );
  }

  /// 并发探活 → 选可用线。登录页进入时用；已登录切线时会重连 WS。
  Future<bool> _probeAllAndSelectBest({bool exhaustive = false}) async {
    if (!ref.mounted) return false;
    final epoch = _probeEpoch;
    final fromLine = state;
    ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connecting);
    await refreshHealthyLines(
      triggerSource: 'auth_probe_all',
      exhaustive: exhaustive,
    );
    if (!ref.mounted) return false;
    if (epoch != _probeEpoch) {
      log.i('[Line] probeAll superseded, skip select');
      return false;
    }

    final healthy = lastHealthyLines;
    if (healthy.isEmpty) {
      if (epoch == _probeEpoch) {
        ref
            .read(configStoreProvider.notifier)
            .setLineStatus(WsStatus.disconnected);
      }
      log.w('[Line] probeAll: none available');
      return false;
    }

    final currentOk = healthy.any((e) => e.id == fromLine.id);
    final selected = currentOk ? fromLine : healthy.first;
    final selectedMs = ref.read(lineProbeCacheProvider)[selected.id]?.latencyMs;

    if (selected.id != fromLine.id) {
      final kv = ref.read(kvStoreProvider);
      await _applyLineId(selected, kv: kv);
      if (!ref.mounted) return false;
      if (epoch != _probeEpoch) {
        log.i('[Line] probeAll select superseded after apply');
        return false;
      }
      await ref.read(lineEventQueueProvider).record(
            eventType: 'line_switch',
            triggerSource: 'auto_probe_select',
            line: selected,
            fromLineId: fromLine.id,
            toLineId: selected.id,
            success: true,
            latencyMs: selectedMs,
          );
      log.i(
        '[Line] auto select ${selected.name}(${selected.host}) '
        '${selectedMs ?? '-'}ms (was ${fromLine.id})',
      );
      final token = kv.accessToken;
      if (token != null && token.isNotEmpty) {
        await onLineSwitched();
      }
    } else {
      log.i(
        '[Line] keep ${selected.id} after probeAll (${selectedMs ?? '-'}ms)',
      );
    }

    if (epoch != _probeEpoch) {
      log.i('[Line] probeAll superseded before status write');
      return false;
    }
    ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connected);
    unawaited(ref.read(lineEventQueueProvider).flush());
    return true;
  }

  /// 注册/登录请求网络失败后：切到下一条已探通且未试过的线路。
  /// 若缓存为空则重新并发探活。找不到返回 null。
  Future<LineConfig?> failoverToNextHealthyLine({
    required Set<String> triedIds,
    String triggerSource = 'auth_request_failover',
  }) async {
    if (!ref.mounted) return null;

    LineConfig? pick() => LineSwitchUtil.nextHealthyCandidate(
          healthySortedByLatency: lastHealthyLines,
          triedIds: triedIds,
        );

    var next = pick();
    if (next == null) {
      log.i('[Line] failover: refresh probeAll (tried=$triedIds)');
      await _probeAllAndSelectBest();
      if (!ref.mounted) return null;
      next = pick();
    }
    if (next == null) {
      log.w('[Line] failover: no remaining healthy line');
      return null;
    }
    if (next.id == state.id) {
      // 探活又选回当前线，但当前已在 tried 里；强制应用到下一条候选。
      final forced = lastHealthyLines.where((l) => !triedIds.contains(l.id));
      next = forced.isEmpty ? null : forced.first;
      if (next == null) return null;
    }

    final fromLine = state;
    final kv = ref.read(kvStoreProvider);
    await _applyLineId(next, kv: kv);
    if (!ref.mounted) return null;
    ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connected);
    await ref.read(lineEventQueueProvider).record(
          eventType: 'line_switch',
          triggerSource: triggerSource,
          line: next,
          fromLineId: fromLine.id,
          toLineId: next.id,
          success: true,
        );
    unawaited(ref.read(lineEventQueueProvider).flush());
    log.i(
      '[Line] auth failover ${fromLine.id} -> ${next.id} (${next.host})',
    );
    return next;
  }
}

final lineProvider =
    NotifierProvider<LineNotifier, LineConfig>(LineNotifier.new);

/// 最近一次各线路探活缓存（面板展示通/不通/延迟；Hive 持久化供下次优先探通线）。
class LineProbeCacheNotifier extends Notifier<Map<String, LineProbeCacheEntry>> {
  @override
  Map<String, LineProbeCacheEntry> build() {
    return _loadFromKv(ref.read(kvStoreProvider));
  }

  static Map<String, LineProbeCacheEntry> _loadFromKv(KvStore kv) {
    final raw = kv.lineProbeHealthRaw;
    if (raw.isEmpty) return const {};
    final out = <String, LineProbeCacheEntry>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is! Map) continue;
      final map = Map<String, dynamic>.from(v);
      final ok = map['ok'] == true;
      final checkedAtMs = (map['checkedAtMs'] is num)
          ? (map['checkedAtMs'] as num).toInt()
          : 0;
      final latencyMs = map['latencyMs'] is num
          ? (map['latencyMs'] as num).toInt()
          : null;
      out[e.key] = LineProbeCacheEntry(
        ok: ok,
        checkedAtMs: checkedAtMs,
        latencyMs: latencyMs,
        errorCategory: map['errorCategory']?.toString(),
      );
    }
    return out;
  }

  Future<void> _persist() async {
    final kv = ref.read(kvStoreProvider);
    final map = <String, dynamic>{};
    for (final e in state.entries) {
      map[e.key] = {
        'ok': e.value.ok,
        'checkedAtMs': e.value.checkedAtMs,
        'latencyMs': e.value.latencyMs,
        if (e.value.errorCategory != null)
          'errorCategory': e.value.errorCategory,
      };
    }
    await kv.setLineProbeHealthJson(jsonEncode(map));
  }

  void upsert(String lineId, LineProbeCacheEntry entry) {
    state = {...state, lineId: entry};
    unawaited(_persist());
  }

  void upsertAll(Map<String, LineProbeCacheEntry> entries) {
    if (entries.isEmpty) return;
    state = {...state, ...entries};
    unawaited(_persist());
  }
}

final lineProbeCacheProvider =
    NotifierProvider<LineProbeCacheNotifier, Map<String, LineProbeCacheEntry>>(
  LineProbeCacheNotifier.new,
);

final lineEventQueueProvider = Provider<LineEventQueue>((ref) {
  return LineEventQueue(
    kv: ref.read(kvStoreProvider),
    getLine: () => ref.read(lineProvider),
    getBaseUrl: () => ref.read(lineProvider).baseUrl,
  );
});

/// 全局 Dio 客户端（含 token 单飞刷新）。baseUrl 随当前线路动态变化。
final dioClientProvider = Provider<DioClient>((ref) {
  final kv = ref.read(kvStoreProvider);
  return DioClient(
    kv: kv,
    getBaseUrl: () => ref.read(lineProvider).baseUrl,
    onLineFallback: () =>
        ref.read(lineProvider.notifier).fallbackOnConnectionError(),
    onRequestSuccess: () {
      ref.read(lineProvider.notifier).markCurrentLineConnected();
      return ref.read(lineEventQueueProvider).flush();
    },
    onConnectionError: (err) => ref.read(lineEventQueueProvider).record(
          eventType: 'api_connection_failure',
          triggerSource: 'dio',
          success: false,
          error: err,
          apiPath: err.requestOptions.path,
          httpStatus: err.response?.statusCode,
        ),
    onAuthFail: () {
      unawaited(kv.clearLoginInfo());
      unawaited(kv.clearStoredPassword());
      ref.read(authControllerProvider.notifier).handleSessionExpired();
      log.w('[Auth] 登录已过期，已退出登录');
    },
  );
});
