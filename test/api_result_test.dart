import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/http/api_result.dart';

void main() {
  group('asApiException', () {
    test('连接超时映射为友好中文提示', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/login'),
        type: DioExceptionType.connectionTimeout,
        message:
            'The request connection took longer than 0:00:10.000000 and it was aborted.',
      );
      expect(asApiException(err).message, '网络似乎有点不给力哟');
    });

    test('isConnectionDioError 识别超时类型', () {
      final err = DioException(
        requestOptions: RequestOptions(path: '/message/private/send'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(isConnectionDioError(err), isTrue);
    });
  });
}
