import 'package:dio/dio.dart';

import '../../models/login_info.dart';
import '../storage/kv_store.dart';
import '../utils/app_logger.dart';
import 'api_result.dart';
import 'token_interceptor.dart';
import 'line_fallback_interceptor.dart';

/// 构建全局 Dio 实例。
///
/// - baseUrl 在每次请求时从 [getBaseUrl] 动态取（支持运行时切换线路）。
/// - 注入 [TokenInterceptor] 做 token 头、统一解包、401 单飞刷新。
class DioClient {
  DioClient({
    required this.kv,
    required this.getBaseUrl,
    required this.onAuthFail,
    this.onLineFallback,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: getBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 25),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ));
    // Token 先加、线路回退后加 → 出错时 LineFallback 先执行，再交给 Token 处理。
    _dio.interceptors.add(TokenInterceptor(TokenInterceptorDeps(
      getBaseUrl: getBaseUrl,
      getAccessToken: () => kv.accessToken,
      refreshToken: _refreshToken,
      onAuthFail: onAuthFail,
      getDio: () => _dio,
    )));
    if (onLineFallback != null) {
      _dio.interceptors.add(LineFallbackInterceptor(
        tryFallback: onLineFallback!,
        getBaseUrl: getBaseUrl,
        getDio: () => _dio,
      ));
    }
  }

  final KvStore kv;
  final String Function() getBaseUrl;
  final void Function() onAuthFail;
  final Future<bool> Function()? onLineFallback;

  late final Dio _dio;
  Dio get dio => _dio;

  /// 冷启动主动刷新 token。对应 App.vue onLaunch refreshToken。
  Future<bool> refreshSession() => _refreshToken();

  /// 用裸 Dio（不带 token 拦截器）刷新令牌，避免递归 401。
  /// 复刻 request.js 的 reqRefreshToken：PUT /refreshToken，header 带 refreshToken。
  Future<bool> _refreshToken() async {
    final info = kv.getLoginInfo();
    if (info == null) return false;
    final bare = Dio(BaseOptions(
      baseUrl: getBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 25),
    ));
    try {
      final res = await bare.put(
        '/refreshToken',
        options: Options(headers: {'refreshToken': info.refreshToken}),
      );
      final api = ApiResponse.fromBody(res.data);
      if (api.isOk && api.data is Map) {
        final parsed =
            LoginInfo.fromJson((api.data as Map).cast<String, dynamic>());
        final newInfo = LoginInfo(
          accessToken: parsed.accessToken,
          refreshToken: parsed.refreshToken,
          userId: parsed.userId != 0 ? parsed.userId : info.userId,
          accessTokenExpiresIn: parsed.accessTokenExpiresIn,
          refreshTokenExpiresIn: parsed.refreshTokenExpiresIn,
          deviceId: (parsed.deviceId != null && parsed.deviceId!.isNotEmpty)
              ? parsed.deviceId
              : info.deviceId,
        );
        await kv.setLoginInfo(newInfo);
        log.i('[Http] token refreshed');
        return true;
      }
      log.w('[Http] refresh rejected: code=${api.code}');
      return false;
    } catch (e) {
      log.w('[Http] refresh error: $e');
      return false;
    } finally {
      bare.close();
    }
  }

  // ---- 便捷方法：返回已解包的 data ----

  Future<T> get<T>(String path,
      {Map<String, dynamic>? query, bool silent = false}) async {
    return _unwrap<T>(_dio.get(path,
        queryParameters: query, options: _opts(silent)));
  }

  Future<T> post<T>(String path,
      {Object? data,
      Map<String, dynamic>? query,
      bool silent = false,
      Options? options}) async {
    final opts = options ?? Options();
    opts.extra = {...?opts.extra, 'silent': silent};
    return _unwrap<T>(_dio.post(path,
        data: data, queryParameters: query, options: opts));
  }

  Future<T> put<T>(String path,
      {Object? data, Map<String, dynamic>? query, bool silent = false}) async {
    return _unwrap<T>(_dio.put(path,
        data: data, queryParameters: query, options: _opts(silent)));
  }

  Future<T> delete<T>(String path,
      {Object? data, Map<String, dynamic>? query, bool silent = false}) async {
    return _unwrap<T>(_dio.delete(path,
        data: data, queryParameters: query, options: _opts(silent)));
  }

  Options _opts(bool silent) => Options(extra: {'silent': silent});

  Future<T> _unwrap<T>(Future<Response> future) async {
    try {
      final res = await future;
      return res.data as T;
    } catch (e) {
      throw asApiException(e);
    }
  }
}
