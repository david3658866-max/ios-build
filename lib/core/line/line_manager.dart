import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../http/api_result.dart';
import '../utils/app_logger.dart';
import '../utils/line_error_util.dart';
import 'line_config.dart';
import 'line_probe_outcome.dart';

/// 按健康分档排序，同档内随机打乱：通 > 未知 > 失败。
List<LineConfig> orderLinesForProbe(
  List<LineConfig> lines,
  Map<String, LineProbeCacheEntry?> priorHealth,
  Random random,
) {
  final healthy = <LineConfig>[];
  final unknown = <LineConfig>[];
  final failed = <LineConfig>[];
  for (final line in lines) {
    final entry = priorHealth[line.id];
    if (entry == null) {
      unknown.add(line);
    } else if (entry.ok) {
      healthy.add(line);
    } else {
      failed.add(line);
    }
  }
  healthy.shuffle(random);
  unknown.shuffle(random);
  failed.shuffle(random);
  return [...healthy, ...unknown, ...failed];
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

  /// 分批探活：健康优先、同档随机、每批 [batchSize] 条，凑满 [stopWhenHealthy] 通即停。
  ///
  /// 登录/自动切线用，缩短「连接中」；未探到的线不出现在结果里。
  Future<List<({LineConfig line, LineProbeOutcome outcome})>> probeAllBatched({
    List<LineConfig>? lines,
    Map<String, LineProbeCacheEntry?> priorHealth = const {},
    int batchSize = batchProbeSize,
    int stopWhenHealthy = batchProbeStopWhenHealthy,
    int maxBatches = 1 << 20,
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
      random: random,
      probe: (line) => probeDetailed(
        line,
        timeout: timeout,
        maxAttempts: maxAttempts,
        retryDelay: retryDelay,
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

/// 可单测的分批探活核心（与网络解耦）。
Future<List<({LineConfig line, LineProbeOutcome outcome})>> runBatchedProbe({
  required List<LineConfig> lines,
  required Future<LineProbeOutcome> Function(LineConfig line) probe,
  Map<String, LineProbeCacheEntry?> priorHealth = const {},
  int batchSize = LineManager.batchProbeSize,
  int stopWhenHealthy = LineManager.batchProbeStopWhenHealthy,
  int maxBatches = 1 << 20,
  Random? random,
}) async {
  if (lines.isEmpty) return const [];
  final size = batchSize < 1 ? 1 : batchSize;
  final stopAt = stopWhenHealthy < 1 ? 1 : stopWhenHealthy;
  final batchLimit = maxBatches < 1 ? 1 : maxBatches;
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
    if (healthyCount >= stopAt || batches >= batchLimit) {
      log.i(
        '[Line] probeAllBatched stop '
        'ok=$healthyCount probed=${results.length}/${ordered.length} '
        'batches=$batches',
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
