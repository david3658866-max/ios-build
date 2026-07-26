import 'package:dio/dio.dart';

import 'api_result.dart';

/// 当前线路连接失败时回退可用线路并重试。
class LineFallbackInterceptor extends Interceptor {
  LineFallbackInterceptor({
    required this.tryFallback,
    required this.getBaseUrl,
    required this.getDio,
    this.onConnectionError,
    this.maxRetries = 3,
  });

  final Future<bool> Function() tryFallback;
  final String Function() getBaseUrl;
  final Dio Function() getDio;
  final Future<void> Function(DioException err)? onConnectionError;
  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 上报仍用宽口径；真正换线用更严的 isLineFailoverDioError。
    if (!isConnectionDioError(err)) {
      handler.next(err);
      return;
    }
    await onConnectionError?.call(err);

    final retryCount =
        (err.requestOptions.extra['_lineRetryCount'] as int?) ?? 0;
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final currentBase = getBaseUrl();
    final reqBase = err.requestOptions.baseUrl;
    // 其他请求已切线：只换 baseUrl 重试，避免晚到的失败再触发第二次切线。
    if (reqBase.isNotEmpty &&
        currentBase.isNotEmpty &&
        reqBase != currentBase) {
      try {
        final opts = err.requestOptions;
        opts.extra['_lineRetryCount'] = retryCount + 1;
        opts.baseUrl = currentBase;
        handler.resolve(await getDio().fetch(opts));
      } catch (e) {
        if (e is DioException && isConnectionDioError(e)) {
          return onError(e, handler);
        }
        handler.next(e is DioException ? e : err);
      }
      return;
    }

    if (!isLineFailoverDioError(err)) {
      handler.next(err);
      return;
    }

    final switched = await tryFallback();
    if (!switched) {
      handler.next(err);
      return;
    }
    try {
      final opts = err.requestOptions;
      opts.extra['_lineRetryCount'] = retryCount + 1;
      opts.baseUrl = getBaseUrl();

      handler.resolve(await getDio().fetch(opts));
    } catch (e) {
      if (e is DioException && isConnectionDioError(e)) {
        return onError(e, handler);
      }
      handler.next(e is DioException ? e : err);
    }
  }
}
