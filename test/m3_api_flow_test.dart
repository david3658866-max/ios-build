import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/utils/message_tmp_id.dart';
import 'package:vortek/models/chat_session_summary.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_message_dto.dart';
import 'package:vortek/models/private_message_dto.dart';
import 'package:vortek/models/user.dart';

import 'helpers/integration_auth.dart';

/// P0 主路径 API 流程：登录 → 资料 → 会话 → 私聊/群聊发送（断言成功）。
void main() {
  late Dio dio;
  late String token;
  late User self;

  setUpAll(() async {
    dio = IntegrationAuth.dio();
    final login = await IntegrationAuth.login(dio);
    token = login.accessToken;

    final selfRes = await dio.get<Map<String, dynamic>>(
      '/user/self',
      options: IntegrationAuth.authedOptions(token),
    );
    final selfApi = ApiResponse.fromBody(selfRes.data);
    expect(selfApi.isOk, isTrue, reason: selfApi.message);
    self = User.fromJson((selfApi.data as Map).cast<String, dynamic>());
  });

  Options h() => IntegrationAuth.authedOptions(token);

  test('GET /system/config 可解析', () async {
    final res = await dio.get<Map<String, dynamic>>('/system/config', options: h());
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: api.message);
  });

  test('GET /message/offline/sessionSummary 可解析', () async {
    final res = await dio.get<Map<String, dynamic>>(
      '/message/offline/sessionSummary',
      options: h(),
    );
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: api.message);
    final list = (api.data as List)
        .map((e) => ChatSessionSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(list, isA<List<ChatSessionSummary>>());
  });

  test('私聊发送成功', () async {
    final friendsRes = await dio.get<dynamic>('/friend/list', options: h());
    final friends = (ApiResponse.fromBody(friendsRes.data).data as List)
        .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(friends, isNotEmpty, reason: '测试账号需至少一名好友');

    final recvId = friends.first.id;
    final res = await dio.post<Map<String, dynamic>>(
      '/message/private/send',
      data: PrivateMessageDTO(
        tmpId: MessageTmpId.next(),
        recvId: recvId,
        content: 'm3-flow-private-${DateTime.now().millisecondsSinceEpoch}',
      ).toJson(),
      options: h(),
    );
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: '${api.code} ${api.message}');
  });

  test('群聊发送成功', () async {
    final groupsRes = await dio.get<dynamic>('/group/list', options: h());
    final groups = (ApiResponse.fromBody(groupsRes.data).data as List)
        .map((e) => Group.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(groups, isNotEmpty, reason: '测试账号需至少一个群');

    final groupId = groups.first.id;
    final res = await dio.post<Map<String, dynamic>>(
      '/message/group/send',
      data: GroupMessageDTO(
        tmpId: MessageTmpId.next(),
        groupId: groupId,
        content: 'm3-flow-group-${DateTime.now().millisecondsSinceEpoch}',
      ).toJson(),
      options: h(),
    );
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: '${api.code} ${api.message}');
  });

  test('GET /user/find 好友资料可解析', () async {
    final friendsRes = await dio.get<dynamic>('/friend/list', options: h());
    final friends = (ApiResponse.fromBody(friendsRes.data).data as List)
        .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    if (friends.isEmpty) return;

    final res = await dio.get<Map<String, dynamic>>(
      '/user/find/${friends.first.id}',
      options: h(),
    );
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: api.message);
    final user = User.fromJson((api.data as Map).cast<String, dynamic>());
    expect(user.id, friends.first.id);
    expect(self.id, greaterThan(0));
  });
}
