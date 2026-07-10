import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_controller.dart';
import '../../stores/config_store.dart';
import '../http/dio_client.dart';
import '../line/line_config.dart';
import '../line/line_manager.dart';
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

/// 当前线路。初值读 KV，切换时写回 KV 并强制 WS 重连到新线路。
class LineNotifier extends Notifier<LineConfig> {
  Future<bool>? _lineCheckFuture;

  @override
  LineConfig build() {
    final kv = ref.read(kvStoreProvider);
    // Debug 本机联调：强制本地线路（避免 Hive 残留 de010 线路 id）
    if (kDebugMode) {
      return kLocalDevLine;
    }
    return lineById(kv.getLineId());
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
    final line = lineById(lineId);
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
        final ok = await _probeLineWithStatus(line);
        if (!ref.mounted) {
          return LineSwitchOutcome(success: false, switched: false, line: line);
        }
        if (ok && isLoggedIn) await onLineSwitched();
        return LineSwitchOutcome(success: ok, switched: false, line: line);
      }
      return LineSwitchOutcome(success: true, switched: false, line: line);
    }

    await _applyLineId(line, kv: kv);
    final ok = await _probeLineWithStatus(line);
    if (!ref.mounted) {
      return LineSwitchOutcome(success: false, switched: true, line: line);
    }
    if (ok && isLoggedIn) {
      await onLineSwitched();
    }
    return LineSwitchOutcome(success: ok, switched: true, line: line);
  }

  /// 线路切换后重连 WS。对齐 uniapp：不切回「正在初始化」，仅用 chatSyncLoading。
  Future<void> onLineSwitched() async {
    final kv = ref.read(kvStoreProvider);
    final token = kv.accessToken;
    if (token == null || token.isEmpty) return;
    final config = ref.read(configStoreProvider.notifier);
    config.setChatSyncLoading(true);
    unawaited(config.loadConfig());
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

  /// 对齐 uniapp：API 失败不自动改线路，由用户在面板手动切换。
  Future<bool> fallbackOnConnectionError() async => false;

  Future<void> _applyLineId(LineConfig line, {required KvStore kv}) async {
    await kv.setLineId(line.id);
    if (!ref.mounted) return;
    state = line;
    log.i('[Line] switch -> ${line.id}');
    unawaited(ref.read(configStoreProvider.notifier).loadConfig());
  }

  /// 对齐 uniapp probeLineWithStatus：更新 chip 探活状态。
  Future<bool> _probeLineWithStatus(LineConfig line) async {
    if (!ref.mounted) return false;
    ref.read(configStoreProvider.notifier).setLineStatus(WsStatus.connecting);
    final manager = ref.read(lineManagerProvider);
    final ok = await manager.isAvailable(line);
    if (!ref.mounted) return ok;
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
    return ok;
  }

  /// 探测当前线路 HTTPS 并更新 chip 状态。对齐 uniapp checkCurrentLineStatus。
  Future<bool> checkCurrentLineStatus({bool allowFallback = false}) {
    return _lineCheckFuture ??= _probeLineWithStatus(state).whenComplete(
      () => _lineCheckFuture = null,
    );
  }
}

final lineProvider =
    NotifierProvider<LineNotifier, LineConfig>(LineNotifier.new);

/// 全局 Dio 客户端（含 token 单飞刷新）。baseUrl 随当前线路动态变化。
final dioClientProvider = Provider<DioClient>((ref) {
  final kv = ref.read(kvStoreProvider);
  return DioClient(
    kv: kv,
    getBaseUrl: () => ref.read(lineProvider).baseUrl,
    onLineFallback: () =>
        ref.read(lineProvider.notifier).fallbackOnConnectionError(),
    onAuthFail: () {
      kv.clearLoginInfo();
      ref.read(authControllerProvider.notifier).handleSessionExpired();
      log.w('[Auth] 登录已过期，已退出登录');
    },
  );
});
