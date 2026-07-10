import 'package:dio/dio.dart';

import 'api_result.dart';

/// 当前线路连接失败时回退主线路并重试一次。
class LineFallbackInterceptor extends Interceptor {
  LineFallbackInterceptor({
    required this.tryFallback,
    required this.getBaseUrl,
    required this.getDio,
    this.maxRetries = 3,
  });

  final Future<bool> Function() tryFallback;
  final String Function() getBaseUrl;
  final Dio Function() getDio;
  final int maxRetries;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_isConnectionError(err)) {
      handler.next(err);
      return;
    }
    final retryCount = (err.requestOptions.extra['_lineRetryCount'] as int?) ?? 0;
    if (retryCount >= maxRetries) {
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
      if (e is DioException && _isConnectionError(e)) {
        return onError(e, handler);
      }
      handler.next(e is DioException ? e : err);
    }
  }

  bool _isConnectionError(DioException err) => isConnectionDioError(err);
}

