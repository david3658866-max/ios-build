import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../http/api_result.dart';
import '../utils/app_logger.dart';
import '../utils/line_error_util.dart';
import 'line_config.dart';
import 'line_probe_outcome.dart';

/// 取 host 注册域族（如 `zenty.dvdda.com` → `dvdda.com`），用于探活打散。
String lineHostFamily(String host) {
  final parts = host.toLowerCase().split('.').where((e) => e.isNotEmpty);
  final list = parts.toList();
  if (list.length >= 2) {
    return '${list[list.length - 2]}.${list[list.length - 1]}';
  }
  return host.toLowerCase();
}

/// 同档内按域名族 round-robin，避免首批全撞同一套坏 DNS。
List<LineConfig> diversifyByHostFamily(
  List<LineConfig> lines,
  Random random,
) {
  if (lines.length <= 1) return List<LineConfig>.from(lines);
  final buckets = <String, List<LineConfig>>{};
  for (final line in lines) {
    final key = lineHostFamily(line.host);
    (buckets[key] ??= <LineConfig>[]).add(line);
  }
  for (final bucket in buckets.values) {
    bucket.shuffle(random);
  }
  final keys = buckets.keys.toList()..shuffle(random);
  final out = <LineConfig>[];
  var progressed = true;
  while (progressed) {
    progressed = false;
    for (final key in keys) {
      final bucket = buckets[key]!;
      if (bucket.isEmpty) continue;
      out.add(bucket.removeAt(0));
      progressed = true;
    }
  }
  return out;
}

/// 通线记忆超过此时长视为过期，需重探（不稳定线避免长期霸榜）。
const Duration kProbeHealthyMaxAge = Duration(minutes: 30);

/// 近期失败冷却：冷却期内排到最后；过期后当未知再给机会。
const Duration kProbeFailCooldown = Duration(minutes: 12);

/// 按健康分档排序，同档内优先池在前，再按域名族打散：
/// 通+优先 > 通+其它 > 未知+优先 > 未知+其它 > 失败+优先 > 失败+其它。
///
/// [priorHealth] 带时间衰减：过期通线降为未知，冷却中失败置底。
List<LineConfig> orderLinesForProbe(
  List<LineConfig> lines,
  Map<String, LineProbeCacheEntry?> priorHealth,
  Random random, {
  DateTime? now,
  Duration healthyMaxAge = kProbeHealthyMaxAge,
  Duration failCooldown = kProbeFailCooldown,
}) {
  final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final healthyPreferred = <LineConfig>[];
  final healthyOther = <LineConfig>[];
  final unknownPreferred = <LineConfig>[];
  final unknownOther = <LineConfig>[];
  final failedPreferred = <LineConfig>[];
  final failedOther = <LineConfig>[];
  for (final line in lines) {
    final preferred = isPreferredBuiltinLine(line.id);
    final tier = classifyProbeHealth(
      priorHealth[line.id],
      nowMs: nowMs,
      healthyMaxAge: healthyMaxAge,
      failCooldown: failCooldown,
    );
    switch (tier) {
      case ProbeHealthTier.healthy:
        (preferred ? healthyPreferred : healthyOther).add(line);
      case ProbeHealthTier.unknown:
        (preferred ? unknownPreferred : unknownOther).add(line);
      case ProbeHealthTier.failed:
        (preferred ? failedPreferred : failedOther).add(line);
    }
  }
  return [
    ...diversifyByHostFamily(healthyPreferred, random),
    ...diversifyByHostFamily(healthyOther, random),
    ...diversifyByHostFamily(unknownPreferred, random),
    ...diversifyByHostFamily(unknownOther, random),
    ...diversifyByHostFamily(failedPreferred, random),
    ...diversifyByHostFamily(failedOther, random),
  ];
}

/// 探活缓存时间衰减后的分档。
enum ProbeHealthTier { healthy, unknown, failed }

/// 将探活缓存归为 healthy / unknown / failed（含过期与冷却）。
ProbeHealthTier classifyProbeHealth(
  LineProbeCacheEntry? entry, {
  required int nowMs,
  Duration healthyMaxAge = kProbeHealthyMaxAge,
  Duration failCooldown = kProbeFailCooldown,
}) {
  if (entry == null) return ProbeHealthTier.unknown;
  final age = nowMs - entry.checkedAtMs;
  if (age < 0) return ProbeHealthTier.unknown;
  if (entry.ok) {
    return age <= healthyMaxAge.inMilliseconds
        ? ProbeHealthTier.healthy
        : ProbeHealthTier.unknown;
  }
  return age <= failCooldown.inMilliseconds
      ? ProbeHealthTier.failed
      : ProbeHealthTier.unknown;
}

/// 线路探活与择优。对应 im-uniapp `common/line-manager.js`。
/// 用轻量 `/line/ping` 作为探活端点（无需登录态即可访问）。
class LineManager {
  /// 手切/同线重连：短超时快失败，避免用户干等。
  static const Duration manualProbeTimeout = Duration(seconds: 3);
  static const int manualProbeMaxAttempts = 2;
  static const Duration manualProbeRetryDelay = Duration(milliseconds: 400);

  /// 日常单线探活（启动/保活）。
  static const Duration defaultProbeTimeout = Duration(seconds: 4);
  static const int defaultProbeMaxAttempts = 2;
  static const Duration defaultProbeRetryDelay = Duration(milliseconds: 400);

  /// 「重新检测」并发探活：再短一点，全挂时体感约 3~7s。
  static const Duration batchProbeTimeout = Duration(seconds: 3);
  static const int batchProbeMaxAttempts = 2;
  static const Duration batchProbeRetryDelay = Duration(milliseconds: 300);

  /// 登录/自动切线：每批并发条数；凑满通线数即停。
  static const int batchProbeSize = 5;
  static const int batchProbeStopWhenHealthy = 5;

  /// 日常分批探活批数硬顶（5×3=15）：全不通时禁止掏空候选池。
  static const int dailyBatchMaxBatches = 3;

  /// 系统判定无网时：满 [offlineStopAfterBatches] 批 0 通则停，且登录阶段不扩兜底。
  static const int offlineStopAfterBatches = 1;

  /// 登录/注册首次探活：通 1 条立刻可选线，缩短「连接中」。
  /// 超时偏短；优先池/兜底都限批，避免客户干等十几秒。
  static const Duration authBatchProbeTimeout = Duration(milliseconds: 1500);
  static const int authBatchProbeMaxAttempts = 1;
  static const int authBatchProbeSize = 6;
  static const int authBatchProbeStopWhenHealthy = 1;

  /// 优先池最多探批数（约 12 条好线）；再不通立刻扩兜底。
  static const int authPreferredMaxBatches = 2;

  /// 兜底最多探批数（约 12 条种子）；与优先合计全挂约 ≤24，加上无网熔断更短。
  static const int authFallbackMaxBatches = 2;

  /// 最近一次探活成功的本地开发线路（127.0.0.1 或局域网 IP）。
  LineConfig? resolvedLocalDevLine;

  /// 探测线路 HTTPS 是否可用。对应 probeLine()。
  Future<bool> isAvailable(
    LineConfig line, {
    Duration timeout = defaultProbeTimeout,
  }) async {
    final outcome = await probeDetailed(line, timeout: timeout);
    return outcome.ok;
  }

  /// 探活单条线路，返回往返耗时(ms)；不可用返回 null。
  Future<int?> probe(
    LineConfig line, {
    Duration timeout = defaultProbeTimeout,
    int maxAttempts = defaultProbeMaxAttempts,
    Duration retryDelay = defaultProbeRetryDelay,
  }) async {
    final outcome = await probeDetailed(
      line,
      timeout: timeout,
      maxAttempts: maxAttempts,
      retryDelay: retryDelay,
    );
    return outcome.latencyMs;
  }

  /// 探活单条线路（含失败分类）。
  ///
  /// 失败后短间隔重试，过滤 CDN 偶发 abort；[maxAttempts] 含首次。
  Future<LineProbeOutcome> probeDetailed(
    LineConfig line, {
    Duration timeout = defaultProbeTimeout,
    int maxAttempts = defaultProbeMaxAttempts,
    Duration retryDelay = defaultProbeRetryDelay,
  }) async {
    if (kDebugMode && line.id == kLocalDevLine.id) {
      return probeLocalDevDetailed(
        timeout: timeout,
        maxAttempts: maxAttempts,
        retryDelay: retryDelay,
      );
    }
    return _probeWithRetry(
      line,
      timeout: timeout,
      maxAttempts: maxAttempts,
      retryDelay: retryDelay,
    );
  }

  /// 本地开发：依次尝试 127.0.0.1（adb reverse）与局域网 IP。
  Future<int?> probeLocalDev({
    Duration timeout = defaultProbeTimeout,
    int maxAttempts = defaultProbeMaxAttempts,
    Duration retryDelay = defaultProbeRetryDelay,
  }) async {
    final outcome = await probeLocalDevDetailed(
      timeout: timeout,
      maxAttempts: maxAttempts,
      retryDelay: retryDelay,
    );
    return outcome.latencyMs;
  }

  Future<LineProbeOutcome> probeLocalDevDetailed({
    Duration timeout = defaultProbeTimeout,
    int maxAttempts = defaultProbeMaxAttempts,
    Duration retryDelay = defaultProbeRetryDelay,
  }) async {
    resolvedLocalDevLine = null;
    LineProbeOutcome last = LineProbeOutcome.failedUnknown;
    for (final host in kLocalDevProbeHosts) {
      final line = localDevLineForHost(host);
      final outcome = await _probeWithRetry(
        line,
        timeout: timeout,
        maxAttempts: maxAttempts,
        retryDelay: retryDelay,
      );
      last = outcome;
      if (outcome.ok) {
        resolvedLocalDevLine = line;
        return outcome;
      }
    }
    return last;
  }

  Future<LineProbeOutcome> _probeWithRetry(
    LineConfig line, {
    required Duration timeout,
    required int maxAttempts,
    required Duration retryDelay,
  }) async {
    final attempts = maxAttempts < 1 ? 1 : maxAttempts;
    LineProbeOutcome last = LineProbeOutcome.failedUnknown;
    for (var i = 1; i <= attempts; i++) {
      last = await _probeOnce(line, timeout: timeout);
      if (last.ok) return last;
      // DNS 解析失败重试几乎无效，直接换下一条。
      if (last.errorCategory == 'dns') return last;
      if (i < attempts) {
        log.w(
          '[Line] probe ${line.id}@${line.host} '
          'attempt $i/$attempts failed(${last.errorCategory}), '
          'retry in ${retryDelay.inMilliseconds}ms',
        );
        await Future<void>.delayed(retryDelay);
      }
    }
    return last;
  }

  Future<LineProbeOutcome> _probeOnce(
    LineConfig line, {
    required Duration timeout,
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
    ));
    final sw = Stopwatch()..start();
    try {
      final res = await dio.get<dynamic>('${line.baseUrl}/line/ping');
      sw.stop();
      final status = res.statusCode;
      if (status != 200) {
        return LineProbeOutcome(
          httpStatus: status,
          errorCategory: LineErrorUtil.classify(null, httpStatus: status),
          errorMessage: 'HTTP $status',
        );
      }
      final body = ApiResponse.fromBody(res.data);
      if (!body.isOk) {
        return LineProbeOutcome(
          httpStatus: status,
          errorCategory:
              LineErrorUtil.classify(null, httpStatus: status, bizOk: false),
          errorMessage:
              body.message.isEmpty ? 'biz_code_${body.code}' : body.message,
        );
      }
      log.i(
        '[Line] probe ${line.name} (${line.host}): ok ${sw.elapsedMilliseconds}ms',
      );
      return LineProbeOutcome(
        latencyMs: sw.elapsedMilliseconds,
        httpStatus: status,
      );
    } catch (e) {
      sw.stop();
      final category = LineErrorUtil.classify(e);
      log.w('[Line] probe ${line.id}@${line.host} failed($category): $e');
      return LineProbeOutcome(
        errorCategory: category ?? 'unknown',
        errorMessage: e.toString().length > 240
            ? e.toString().substring(0, 240)
            : e.toString(),
      );
    } finally {
      dio.close();
    }
  }

  /// 全量并发探活（面板「重新检测」用，保证每条都有通/不通状态）。
  Future<List<({LineConfig line, LineProbeOutcome outcome})>> probeAll({
    List<LineConfig>? lines,
    Duration timeout = batchProbeTimeout,
    int maxAttempts = batchProbeMaxAttempts,
    Duration retryDelay = batchProbeRetryDelay,
  }) async {
    final targetLines = lines ?? kLines;
    final results = await Future.wait(
      targetLines.map(
        (l) async => (
          line: l,
          outcome: await probeDetailed(
            l,
            timeout: timeout,
            maxAttempts: maxAttempts,
            retryDelay: retryDelay,
          ),
        ),
      ),
    );
    final ok = results.where((r) => r.outcome.ok).length;
    log.i('[Line] probeAll $ok/${results.length} ok');
    return results;
  }

  /// 分批探活：健康优先、域名族打散、每批 [batchSize] 条，凑满 [stopWhenHealthy] 通即停。
  ///
  /// 登录/自动切线用，缩短「连接中」；未探到的线不出现在结果里。
  /// 默认最多 [dailyBatchMaxBatches] 批；[deviceNetworkType]==none 时还可无网熔断。
  Future<List<({LineConfig line, LineProbeOutcome outcome})>> probeAllBatched({
    List<LineConfig>? lines,
    Map<String, LineProbeCacheEntry?> priorHealth = const {},
    int batchSize = batchProbeSize,
    int stopWhenHealthy = batchProbeStopWhenHealthy,
    int maxBatches = dailyBatchMaxBatches,
    String? deviceNetworkType,
    Random? random,
    Duration timeout = batchProbeTimeout,
    int maxAttempts = batchProbeMaxAttempts,
    Duration retryDelay = batchProbeRetryDelay,
  }) {
    return runBatchedProbe(
      lines: lines ?? kLines,
      priorHealth: priorHealth,
      batchSize: batchSize,
      stopWhenHealthy: stopWhenHealthy,
      maxBatches: maxBatches,
      deviceNetworkType: deviceNetworkType,
      random: random,
      probe: (line) => probeDetailed(
        line,
        timeout: timeout,
        maxAttempts: maxAttempts,
        retryDelay: retryDelay,
      ),
    );
  }

  /// 登录/注册页快速探活：通 1 条即停，短超时、不重试。
  ///
  /// 先探 [kPreferredBuiltinLineIds] 优先池；全不通再扩到其余内置。
  /// [deviceNetworkType]==none 时优先池 1 批即停且不扩兜底。
  Future<List<({LineConfig line, LineProbeOutcome outcome})>>
      probeAllBatchedForAuth({
    List<LineConfig>? lines,
    Map<String, LineProbeCacheEntry?> priorHealth = const {},
    String? deviceNetworkType,
    Random? random,
  }) {
    return runAuthTwoPhaseBatchedProbe(
      lines: lines ?? kLines,
      priorHealth: priorHealth,
      deviceNetworkType: deviceNetworkType,
      random: random,
      probe: (line) => probeDetailed(
        line,
        timeout: authBatchProbeTimeout,
        maxAttempts: authBatchProbeMaxAttempts,
      ),
    );
  }

  /// 并发探活所有线路，返回延迟最低的可用线路；全部不可用返回 null。
  Future<LineConfig?> pickFastest({
    List<LineConfig>? lines,
    Duration timeout = batchProbeTimeout,
  }) async {
    final results = await probeAll(lines: lines, timeout: timeout);
    LineConfig? best;
    var bestMs = 1 << 30;
    for (final r in results) {
      final ms = r.outcome.latencyMs;
      if (ms != null && ms < bestMs) {
        bestMs = ms;
        best = r.line;
      }
    }
    if (best != null) log.i('[Line] fastest=${best.id} ${bestMs}ms');
    return best;
  }
}

/// 登录探活两阶段：优先池有通线则不碰兜底；优先池限批不通再短扩探。
///
/// [deviceNetworkType]==`none` 时优先池仅 1 批且不进兜底，避免无网刷满种子。
Future<List<({LineConfig line, LineProbeOutcome outcome})>>
    runAuthTwoPhaseBatchedProbe({
  required List<LineConfig> lines,
  required Future<LineProbeOutcome> Function(LineConfig line) probe,
  Map<String, LineProbeCacheEntry?> priorHealth = const {},
  String? deviceNetworkType,
  Random? random,
  bool Function(String id) isPreferred = isPreferredBuiltinLine,
}) async {
  final preferred = lines.where((l) => isPreferred(l.id)).toList();
  final others = lines.where((l) => !isPreferred(l.id)).toList();
  final offline = deviceNetworkType == 'none';
  Future<List<({LineConfig line, LineProbeOutcome outcome})>> phase(
    List<LineConfig> phaseLines, {
    required int maxBatches,
  }) {
    return runBatchedProbe(
      lines: phaseLines,
      priorHealth: priorHealth,
      batchSize: LineManager.authBatchProbeSize,
      stopWhenHealthy: LineManager.authBatchProbeStopWhenHealthy,
      maxBatches: maxBatches,
      deviceNetworkType: deviceNetworkType,
      random: random,
      probe: probe,
    );
  }

  if (preferred.isEmpty) {
    return phase(
      lines,
      maxBatches: offline ? LineManager.offlineStopAfterBatches : LineManager.authFallbackMaxBatches,
    );
  }
  final first = await phase(
    preferred,
    maxBatches: offline
        ? LineManager.offlineStopAfterBatches
        : LineManager.authPreferredMaxBatches,
  );
  if (first.any((r) => r.outcome.ok) || others.isEmpty) {
    return first;
  }
  if (offline ||
      LineErrorUtil.batchLooksDeviceOffline(
        outcomesOk: first.map((r) => r.outcome.ok),
        errorCategories: first.map((r) => r.outcome.errorCategory),
        networkType: deviceNetworkType,
      )) {
    log.i(
      '[Line] auth stop after preferred (offline/no expand) '
      'probed=${first.length}',
    );
    return first;
  }
  log.i(
    '[Line] auth preferred capped/failed '
    '(probed=${first.length}/${preferred.length}), '
    'expand to ${others.length} fallbacks',
  );
  final second = await phase(
    others,
    maxBatches: LineManager.authFallbackMaxBatches,
  );
  return [...first, ...second];
}

/// 可单测的分批探活核心（与网络解耦）。
Future<List<({LineConfig line, LineProbeOutcome outcome})>> runBatchedProbe({
  required List<LineConfig> lines,
  required Future<LineProbeOutcome> Function(LineConfig line) probe,
  Map<String, LineProbeCacheEntry?> priorHealth = const {},
  int batchSize = LineManager.batchProbeSize,
  int stopWhenHealthy = LineManager.batchProbeStopWhenHealthy,
  int maxBatches = LineManager.dailyBatchMaxBatches,
  int offlineStopAfterBatches = LineManager.offlineStopAfterBatches,
  String? deviceNetworkType,
  Random? random,
}) async {
  if (lines.isEmpty) return const [];
  final size = batchSize < 1 ? 1 : batchSize;
  final stopAt = stopWhenHealthy < 1 ? 1 : stopWhenHealthy;
  final batchLimit = maxBatches < 1 ? 1 : maxBatches;
  final offlineBatchLimit =
      offlineStopAfterBatches < 1 ? 1 : offlineStopAfterBatches;
  final ordered = orderLinesForProbe(
    lines,
    priorHealth,
    random ?? Random(),
  );
  final results = <({LineConfig line, LineProbeOutcome outcome})>[];
  var healthyCount = 0;
  var batches = 0;
  for (var i = 0; i < ordered.length; i += size) {
    batches++;
    final end = i + size > ordered.length ? ordered.length : i + size;
    final batch = ordered.sublist(i, end);
    final batchResults = await Future.wait(
      batch.map((l) async => (line: l, outcome: await probe(l))),
    );
    results.addAll(batchResults);
    for (final r in batchResults) {
      if (r.outcome.ok) healthyCount++;
    }
    final offlineCap = LineErrorUtil.batchLooksDeviceOffline(
          outcomesOk: batchResults.map((r) => r.outcome.ok),
          errorCategories: batchResults.map((r) => r.outcome.errorCategory),
          networkType: deviceNetworkType,
        ) &&
        healthyCount == 0 &&
        batches >= offlineBatchLimit;
    if (healthyCount >= stopAt || batches >= batchLimit || offlineCap) {
      log.i(
        '[Line] probeAllBatched stop '
        'ok=$healthyCount probed=${results.length}/${ordered.length} '
        'batches=$batches'
        '${offlineCap ? ' offlineCap' : ''}',
      );
      break;
    }
  }
  final ok = results.where((r) => r.outcome.ok).length;
  log.i(
    '[Line] probeAllBatched $ok/${results.length} ok '
    '(of ${ordered.length} candidates)',
  );
  return results;
}

/// 静默探结果合并：本批覆盖同 id；未过期的旧通线保留。
List<LineConfig> mergeSilentHealthyLines({
  required List<LineConfig> previousHealthy,
  required Map<String, LineProbeCacheEntry> cache,
  required List<({LineConfig line, LineProbeOutcome outcome})> batchResults,
  required int nowMs,
  int ttlMs = 10 * 60 * 1000,
}) {
  final byId = <String, LineConfig>{};
  for (final line in previousHealthy) {
    final entry = cache[line.id];
    if (entry != null &&
        entry.ok &&
        nowMs - entry.checkedAtMs <= ttlMs) {
      byId[line.id] = line;
    }
  }
  for (final r in batchResults) {
    if (r.outcome.ok) {
      byId[r.line.id] = r.line;
    } else {
      byId.remove(r.line.id);
    }
  }
  final list = byId.values.toList();
  list.sort((a, b) {
    final ma = cache[a.id]?.latencyMs ?? 1 << 30;
    final mb = cache[b.id]?.latencyMs ?? 1 << 30;
    return ma.compareTo(mb);
  });
  return list;
}

final lineManagerProvider = Provider<LineManager>((ref) => LineManager());
