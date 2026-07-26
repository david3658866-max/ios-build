import 'package:dio/dio.dart';

/// 统一业务异常。对应后端 `{code, data, message}` 中 code != 200 的情况，
/// 以及网络错误。UI 层统一 toast（silent 时跳过）。
class ApiException implements Exception {
  ApiException(this.code, this.message);

  final int code;
  final String message;

  /// 是否需要静默（不弹 toast）。由请求时 `silent: true` 透传。
  bool silent = false;

  /// 常见网络错误。
  factory ApiException.network([String? msg]) =>
      ApiException(-1, msg ?? '网络似乎有点不给力哟');

  @override
  String toString() => 'ApiException(code: $code, message: $message)';
}

/// 后端统一响应包：`{code:int, data:T, message:String}`，code=200 成功。
class ApiResponse {
  ApiResponse({required this.code, required this.data, required this.message});

  final int code;
  final dynamic data;
  final String message;

  bool get isOk => code == 200;

  factory ApiResponse.fromBody(dynamic body) {
    if (body is Map) {
      return ApiResponse(
        code: (body['code'] as num?)?.toInt() ?? -1,
        data: body['data'],
        message: (body['message'] ?? body['msg'] ?? '').toString(),
      );
    }
    // 非标准响应体，直接当作 data 透传
    return ApiResponse(code: 200, data: body, message: '');
  }
}

/// 把 [ApiException] 包成 DioException，便于在拦截器中 reject 后由调用方捕获。
DioException toDioError(RequestOptions options, ApiException e) {
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    error: e,
    message: e.message,
  );
}

/// 从任意捕获到的异常中提取 [ApiException]。
ApiException asApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return inner;
    // 对齐 uniapp request.js fail()：网络/超时统一提示，不暴露 Dio 英文原文。
    if (isConnectionDioError(error)) {
      return ApiException.network();
    }
    return ApiException.network();
  }
  return ApiException.network();
}

/// 是否为可触发线路切换重试的网络错误。
bool isNetworkApiError(ApiException api) => api.code == -1;

/// 是否为连接类错误（DNS/超时/断网等），用于线路回退与友好提示。
bool isConnectionDioError(DioException err) {
  switch (err.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.unknown:
      return true;
    default:
      break;
  }
  final msg = err.message?.toLowerCase() ?? '';
  return msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('connection errored') ||
      msg.contains('connection took longer') ||
      msg.contains('socketexception');
}

/// 是否值得触发「换线路」重试。
///
/// 比 [isConnectionDioError] 更严：`receiveTimeout` 多为业务慢/服务端慢，
/// 不代表当前线路 Host 不可达，自动切线只会白白重连 WS、伤体验。
bool isLineFailoverDioError(DioException err) {
  switch (err.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
      return true;
    case DioExceptionType.receiveTimeout:
      return false;
    case DioExceptionType.unknown:
      break;
    default:
      return false;
  }
  final msg = err.message?.toLowerCase() ?? '';
  return msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('connection errored') ||
      msg.contains('connection took longer') ||
      msg.contains('socketexception');
}
