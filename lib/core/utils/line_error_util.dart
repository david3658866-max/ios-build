import 'package:dio/dio.dart';

import '../http/api_result.dart';

/// 线路/网络错误分类（上报与排障用）。
///
/// 约定主类：`dns` / `tls` / `timeout` / `http`；
/// 其余：`connection` / `network` / `business` / `unknown`。
///
/// 排障结论 [failReason]：成功不写；系统无网时优先 `device_offline`，否则回落为 [errorCategory]。
abstract final class LineErrorUtil {
  /// 系统报无网，且错误属于「连不上」类时，判定为疑似本机离线。
  static bool offlineLikely({
    String? networkType,
    String? errorCategory,
  }) {
    if (networkType != 'none') return false;
    const cats = {
      'dns',
      'connection',
      'network',
      'timeout',
      'unknown',
    };
    if (errorCategory == null || errorCategory.isEmpty) return true;
    return cats.contains(errorCategory);
  }

  /// 探测失败的排障结论：`device_offline` / 原 [errorCategory] / `unknown`。
  static String? failReason({
    required bool success,
    String? networkType,
    String? errorCategory,
  }) {
    if (success) return null;
    if (offlineLikely(
      networkType: networkType,
      errorCategory: errorCategory,
    )) {
      return 'device_offline';
    }
    if (errorCategory != null && errorCategory.isNotEmpty) {
      return errorCategory;
    }
    return 'unknown';
  }

  /// 写入 `extraJson` 的探测诊断字段。
  static Map<String, dynamic> probeDiagnosisExtra({
    required bool success,
    required String networkType,
    String? errorCategory,
  }) {
    final reason = failReason(
      success: success,
      networkType: networkType,
      errorCategory: errorCategory,
    );
    return {
      if (reason != null) 'failReason': reason,
      'offlineLikely': offlineLikely(
        networkType: networkType,
        errorCategory: errorCategory,
      ),
    };
  }

  static String? classify(
    Object? error, {
    int? httpStatus,
    bool? bizOk,
  }) {
    if (httpStatus != null && httpStatus != 200) return 'http';
    if (bizOk == false) return 'http';
    if (error == null) return null;

    if (error is ApiException) {
      return error.code == -1 ? 'network' : 'business';
    }

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'timeout';
        case DioExceptionType.badCertificate:
          return 'tls';
        case DioExceptionType.connectionError:
          return _fromMessage(error.message) ??
              _fromMessage(error.error?.toString()) ??
              'connection';
        case DioExceptionType.badResponse:
          return 'http';
        default:
          break;
      }
      return _fromMessage(error.message) ??
          _fromMessage(error.error?.toString()) ??
          'network';
    }

    return _fromMessage(error.toString()) ?? 'unknown';
  }

  static String? _fromMessage(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final msg = raw.toLowerCase();
    if (msg.contains('failed host lookup') ||
        msg.contains('nodename nor servname') ||
        msg.contains('name not resolved') ||
        msg.contains('dns')) {
      return 'dns';
    }
    if (msg.contains('certificate') ||
        msg.contains('handshake') ||
        msg.contains('ssl') ||
        msg.contains('tls')) {
      return 'tls';
    }
    if (msg.contains('timed out') ||
        msg.contains('timeout') ||
        msg.contains('took longer')) {
      return 'timeout';
    }
    if (msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('network is unreachable') ||
        msg.contains('socketexception')) {
      return 'connection';
    }
    return null;
  }
}