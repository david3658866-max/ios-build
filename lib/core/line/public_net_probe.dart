import 'package:dio/dio.dart';

import '../utils/app_logger.dart';
import '../utils/line_error_util.dart';

/// Domestic-only public internet contrast probe (not a business line probe).
///
/// Used when all IM lines fail in one round, to distinguish:
/// - device/local network down (public also fails)
/// - IM domain/CDN issue (public ok, lines fail)
class PublicNetProbe {
  PublicNetProbe._();

  static const Duration timeout = Duration(seconds: 2);

  /// China-reachable lightweight targets only. Never use overseas endpoints.
  static const List<String> _targets = [
    'https://www.baidu.com/favicon.ico',
    'https://www.qq.com/favicon.ico',
  ];

  /// Domestic gate: UTC+8 timezone required.
  /// Explicit non-+86 phone => skip. Missing/CN-looking phone + UTC+8 => allow.
  static bool isDomesticEligible({String? loginPhone}) {
    final offsetHours = DateTime.now().timeZoneOffset.inHours;
    if (offsetHours != 8) return false;

    final phone = (loginPhone ?? '').trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) return true;

    if (phone.startsWith('+') && !phone.startsWith('+86')) return false;
    if (phone.startsWith('00') && !phone.startsWith('0086')) return false;
    return true;
  }

  /// Probe first reachable domestic target; returns first success or last failure.
  static Future<PublicProbeResult> probe() async {
    PublicProbeResult? lastFail;
    for (final url in _targets) {
      final one = await _probeOnce(url);
      if (one.ok) return one;
      lastFail = one;
    }
    return lastFail ??
        const PublicProbeResult(
          ok: false,
          host: '',
          errorCategory: 'unknown',
        );
  }

  static Future<PublicProbeResult> _probeOnce(String url) async {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? url;
    final sw = Stopwatch()..start();
    final dio = Dio(
      BaseOptions(
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (code) => code != null && code >= 200 && code < 400,
      ),
    );
    try {
      final res = await dio.get<List<int>>(url);
      sw.stop();
      return PublicProbeResult(
        ok: true,
        host: host,
        latencyMs: sw.elapsedMilliseconds,
        httpStatus: res.statusCode,
      );
    } catch (e) {
      sw.stop();
      final category = LineErrorUtil.classify(e);
      log.i('[PublicProbe] fail $host cat=$category');
      return PublicProbeResult(
        ok: false,
        host: host,
        latencyMs: sw.elapsedMilliseconds,
        errorCategory: category ?? 'unknown',
        errorMessage: e.toString(),
      );
    } finally {
      dio.close();
    }
  }
}

class PublicProbeResult {
  const PublicProbeResult({
    required this.ok,
    required this.host,
    this.latencyMs,
    this.httpStatus,
    this.errorCategory,
    this.errorMessage,
  });

  final bool ok;
  final String host;
  final int? latencyMs;
  final int? httpStatus;
  final String? errorCategory;
  final String? errorMessage;

  Map<String, dynamic> toExtra({
    required int lineCount,
    required int okCount,
    required int failCount,
    required String triggerSource,
    bool domesticEligible = true,
    String? skipReason,
  }) {
    if (skipReason != null) {
      return {
        'lineCount': lineCount,
        'okCount': okCount,
        'failCount': failCount,
        'triggerSource': triggerSource,
        'domesticEligible': domesticEligible,
        'publicSkipped': true,
        'publicSkipReason': skipReason,
      };
    }
    return {
      'lineCount': lineCount,
      'okCount': okCount,
      'failCount': failCount,
      'triggerSource': triggerSource,
      'domesticEligible': domesticEligible,
      'publicOk': ok,
      'publicHost': host,
      'publicLatencyMs': latencyMs,
      if (httpStatus != null) 'publicHttpStatus': httpStatus,
      if (!ok && errorCategory != null) 'publicErrorCategory': errorCategory,
      if (!ok && errorMessage != null) 'publicErrorMessage': errorMessage,
    };
  }
}
