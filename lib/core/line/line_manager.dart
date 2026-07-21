import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../http/api_result.dart';
import '../utils/app_logger.dart';
import '../utils/line_error_util.dart';
import 'line_config.dart';
import 'line_probe_outcome.dart';

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
          errorCategory: LineErrorUtil.classify(null, httpStatus: status, bizOk: false),
          errorMessage: body.message.isEmpty ? 'biz_code_${body.code}' : body.message,
        );
      }
      log.i('[Line] probe ${line.name} (${line.host}): ok ${sw.elapsedMilliseconds}ms');
      return LineProbeOutcome(latencyMs: sw.elapsedMilliseconds, httpStatus: status);
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

  /// 并发探活多条线路。
  ///
  /// 并发场景用较短超时，避免全挂时「连接中」拖太久。
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

final lineManagerProvider = Provider<LineManager>((ref) => LineManager());