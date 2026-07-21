import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/models/chat_session_summary.dart';
import 'package:vortek/models/login_dto.dart';
import 'package:vortek/models/login_info.dart';

/// 离线会话摘要接口集成测试。
void main() {
  test('登录后 GET /message/offline/sessionSummary 返回可解析列表', () async {
    const phone = '15222222222';
    const password = '123456';

    final dio = Dio(BaseOptions(
      baseUrl: kDefaultLine.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ));

    final loginRes = await dio.post<Map<String, dynamic>>(
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

    final loginApi = ApiResponse.fromBody(loginRes.data);
    expect(loginApi.isOk, isTrue,
        reason: '登录应返回 code=200，实际 code=${loginApi.code} msg=${loginApi.message}');

    final loginInfo =
        LoginInfo.fromJson((loginApi.data as Map).cast<String, dynamic>());
    expect(loginInfo.accessToken, isNotEmpty);

    final summaryRes = await dio.get<Map<String, dynamic>>(
      '/message/offline/sessionSummary',
      options: Options(
        headers: {'accessToken': loginInfo.accessToken},
      ),
    );

    final summaryApi = ApiResponse.fromBody(summaryRes.data);
    expect(summaryApi.isOk, isTrue,
        reason:
            'sessionSummary 应返回 code=200，实际 code=${summaryApi.code} msg=${summaryApi.message}');
    expect(summaryApi.data, isA<List>(),
        reason: 'data 应为 List，实际类型=${summaryApi.data.runtimeType}');

    final list = summaryApi.data as List;
    if (list.isNotEmpty) {
      final first = ChatSessionSummary.fromJson(
        (list.first as Map).cast<String, dynamic>(),
      );
      expect(first.type, isNotEmpty);
      expect(first.targetId, isA<int>());
    }
  });
}
