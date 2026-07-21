import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/utils/line_error_util.dart';

void main() {
  group('LineErrorUtil.classify', () {
    test('timeout / tls / dns / http', () {
      expect(
        LineErrorUtil.classify(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        'timeout',
      );
      expect(
        LineErrorUtil.classify(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.badCertificate,
          ),
        ),
        'tls',
      );
      expect(
        LineErrorUtil.classify(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
            message: 'Failed host lookup: example.com',
          ),
        ),
        'dns',
      );
      expect(LineErrorUtil.classify(null, httpStatus: 502), 'http');
      expect(LineErrorUtil.classify(null, bizOk: false), 'http');
      expect(LineErrorUtil.classify(ApiException(400, 'bad')), 'business');
    });
  });

  group('LineErrorUtil.offlineLikely / failReason', () {
    test('none + dns => device_offline', () {
      expect(
        LineErrorUtil.offlineLikely(
          networkType: 'none',
          errorCategory: 'dns',
        ),
        isTrue,
      );
      expect(
        LineErrorUtil.failReason(
          success: false,
          networkType: 'none',
          errorCategory: 'dns',
        ),
        'device_offline',
      );
    });

    test('mobile + dns => keep dns (not offline)', () {
      expect(
        LineErrorUtil.offlineLikely(
          networkType: 'mobile',
          errorCategory: 'dns',
        ),
        isFalse,
      );
      expect(
        LineErrorUtil.failReason(
          success: false,
          networkType: 'mobile',
          errorCategory: 'dns',
        ),
        'dns',
      );
    });

    test('success => no failReason', () {
      expect(
        LineErrorUtil.failReason(
          success: true,
          networkType: 'none',
          errorCategory: 'dns',
        ),
        isNull,
      );
      expect(
        LineErrorUtil.probeDiagnosisExtra(
          success: false,
          networkType: 'none',
          errorCategory: 'dns',
        ),
        {
          'failReason': 'device_offline',
          'offlineLikely': true,
        },
      );
    });
  });
}