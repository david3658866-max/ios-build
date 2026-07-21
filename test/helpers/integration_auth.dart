import 'package:dio/dio.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/models/login_dto.dart';
import 'package:vortek/models/login_info.dart';

/// M2 集成测试共用登录。
class IntegrationAuth {
  IntegrationAuth._();

  static const phone = '15222222222';
  static const password = '123456';

  static Dio dio() => Dio(BaseOptions(
        baseUrl: kDefaultLine.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
      ));

  static Future<LoginInfo> login([Dio? client]) async {
    final d = client ?? dio();
    final res = await d.post<Map<String, dynamic>>(
      '/login',
      data: LoginDTO(
        mode: 'username',
        terminal: 1,
        userName: phone,
        phone: phone,
        email: '',
        code: '',
        password: password,
        deviceId: 'integration-test-device',
        loginType: 'android',
        deviceInfo: 'Test|Android 12|Test',
        clientVersion: '1.0.0',
      ).toJson(),
    );
    final api = ApiResponse.fromBody(res.data);
    if (!api.isOk) {
      throw StateError('login failed: ${api.code} ${api.message}');
    }
    return LoginInfo.fromJson((api.data as Map).cast<String, dynamic>());
  }

  static Options authedOptions(String accessToken) => Options(
        headers: {'accessToken': accessToken},
      );

  /// 集成测网络偶发失败时重试（不依赖真机）。
  static Future<T> withNetworkRetry<T>(
    Future<T> Function() action, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 2),
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        if (attempt >= maxAttempts) break;
        await Future.delayed(delay);
      }
    }
    throw lastError!;
  }
}
