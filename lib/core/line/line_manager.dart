import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../http/api_result.dart';
import '../utils/app_logger.dart';
import 'line_config.dart';

/// 线路探活与择优。对应 im-uniapp `common/line-manager.js`。
/// 用 `/system/config` 作为探活端点（无需登录态即可访问）。
class LineManager {
  /// 最近一次探活成功的本地开发线路（127.0.0.1 或局域网 IP）。
  LineConfig? resolvedLocalDevLine;

  /// 探测线路 HTTPS 是否可用。对应 probeLine()。
  Future<bool> isAvailable(
    LineConfig line, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final ms = await probe(line, timeout: timeout);
    return ms != null;
  }

  /// 探活单条线路，返回往返耗时(ms)；不可用返回 null。
  Future<int?> probe(
    LineConfig line, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (kDebugMode && line.id == kLocalDevLine.id) {
      return probeLocalDev(timeout: timeout);
    }
    return _probeSingle(line, timeout: timeout);
  }

  /// 本地开发：依次尝试 127.0.0.1（adb reverse）与局域网 IP。
  Future<int?> probeLocalDev({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    resolvedLocalDevLine = null;
    for (final host in kLocalDevProbeHosts) {
      final line = localDevLineForHost(host);
      final ms = await _probeSingle(line, timeout: timeout);
      if (ms != null) {
        resolvedLocalDevLine = line;
        return ms;
      }
    }
    return null;
  }

  Future<int?> _probeSingle(
    LineConfig line, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
    ));
    final sw = Stopwatch()..start();
    try {
      final res = await dio.get<dynamic>('${line.baseUrl}/system/config');
      sw.stop();
      if (res.statusCode != 200) return null;
      final body = ApiResponse.fromBody(res.data);
      if (!body.isOk) return null;
      log.i('[Line] probe ${line.name} (${line.host}): ok ${sw.elapsedMilliseconds}ms');
      return sw.elapsedMilliseconds;
    } catch (e) {
      log.w('[Line] probe ${line.id}@${line.host} failed: $e');
      return null;
    } finally {
      dio.close();
    }
  }

  /// 并发探活所有线路，返回延迟最低的可用线路；全部不可用返回 null。
  Future<LineConfig?> pickFastest({List<LineConfig>? lines}) async {
    final targetLines = lines ?? kLines;
    final results = await Future.wait(
      targetLines.map((l) async => (line: l, ms: await probe(l))),
    );
    LineConfig? best;
    var bestMs = 1 << 30;
    for (final r in results) {
      final ms = r.ms;
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
