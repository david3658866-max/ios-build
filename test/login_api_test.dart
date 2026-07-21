import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/models/login_dto.dart';
import 'package:vortek/models/login_info.dart';

/// 真实登录接口集成测试（账号由用户提供）。
void main() {
  test('15222222222 / 123456 登录并解析 LoginInfo', () async {
    const phone = '15222222222';
    const password = '123456';

    final dio = Dio(BaseOptions(
      baseUrl: kDefaultLine.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ));

    final res = await dio.post<Map<String, dynamic>>(
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
    expect(api.isOk, isTrue, reason: '登录应返回 code=200，实际 code=${api.code} msg=${api.message}');
    expect(api.data, isA<Map>(), reason: 'data 不应为 null');

    final info = LoginInfo.fromJson((api.data as Map).cast<String, dynamic>());
    expect(info.accessToken, isNotEmpty);
    expect(info.refreshToken, isNotEmpty);
    // 后端当前可能返回 userId:null，解析不应抛 type null。
    expect(info.userId, isA<int>());
  });
}
