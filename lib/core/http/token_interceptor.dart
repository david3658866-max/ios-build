import 'dart:async';

import 'package:dio/dio.dart';

import 'api_result.dart';

class TokenInterceptorDeps {
  TokenInterceptorDeps({
    required this.getBaseUrl,
    required this.getAccessToken,
    required this.refreshToken,
    required this.onAuthFail,
    required this.getDio,
  });

  final String Function() getBaseUrl;

  final String? Function() getAccessToken;

  final Future<bool> Function() refreshToken;

  final void Function() onAuthFail;

  final Dio Function() getDio;
}

class TokenInterceptor extends Interceptor {
  TokenInterceptor(this.deps);

  final TokenInterceptorDeps deps;

  Completer<bool>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.baseUrl = deps.getBaseUrl();
    final token = deps.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['accessToken'] = token;
    }
    options.headers['X-IM-Client-Stack'] = 'flutter';
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // 仅处理已被本拦截器重放过、标记为已解包的响应：直接放行。
    if (response.requestOptions.extra['_unwrapped'] == true) {
      handler.next(response);
      return;
    }

    final api = ApiResponse.fromBody(response.data);
    final silent = response.requestOptions.extra['silent'] == true;

    if (api.isOk) {
      response.data = api.data;
      response.requestOptions.extra['_unwrapped'] = true;
      handler.next(response);
      return;
    }

    if (api.code == 401) {
      await _handle401(response, handler, silent);
      return;
    }

    // 400 业务错误 / 429 频率限制 / 其它
    final msg = api.code == 429
        ? (api.message.isEmpty ? '请求过于频繁，请稍后再试' : api.message)
        : (api.message.isEmpty ? '请求失败' : api.message);
    final e = ApiException(api.code, msg)..silent = silent;
    handler.reject(toDioError(response.requestOptions, e));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 已是 ApiException 的直接放行
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }
    // 连接类错误交给 LineFallbackInterceptor 处理，勿提前包装 badResponse
    if (isConnectionDioError(err)) {
      handler.next(err);
      return;
    }
    final silent = err.requestOptions.extra['silent'] == true;
    final e = ApiException.network(err.message)..silent = silent;
    handler.reject(toDioError(err.requestOptions, e));
  }

  Future<void> _handle401(
    Response response,
    ResponseInterceptorHandler handler,
    bool silent,
  ) async {
    // 重放保护：刷新后仍 401，说明新 token 也无效，直接退出，避免无限刷新循环
    if (response.requestOptions.extra['_retried'] == true) {
      deps.onAuthFail();
      final e = ApiException(401, '登录信息已过期，请重新登录')..silent = silent;
      handler.reject(toDioError(response.requestOptions, e));
      return;
    }

    final ok = await _ensureRefreshed();
    if (!ok) {
      deps.onAuthFail();
      final e = ApiException(401, '登录信息已过期，请重新登录')..silent = silent;
      handler.reject(toDioError(response.requestOptions, e));
      return;
    }
    // 刷新成功，重放原请求（标记已重放）
    try {
      final opts = response.requestOptions;
      opts.extra['_retried'] = true;
      final token = deps.getAccessToken();
      if (token != null) opts.headers['accessToken'] = token;
      final retry = await deps.getDio().fetch(opts);
      handler.resolve(retry);
    } catch (e) {
      handler.reject(
        e is DioException
            ? e
            : toDioError(response.requestOptions, asApiException(e)),
      );
    }
  }

  Future<bool> _ensureRefreshed() {
    final inflight = _refreshing;
    if (inflight != null) return inflight.future;

    final c = Completer<bool>();
    _refreshing = c;
    deps
        .refreshToken()
        .then((ok) => c.complete(ok))
        .catchError((Object _) => c.complete(false))
        .whenComplete(() => _refreshing = null);
    return c.future;
  }
}
