import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/message_tmp_id.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/models/chat_session_summary.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_message_dto.dart';
import 'package:vortek/models/private_message.dart';
import 'package:vortek/models/private_message_dto.dart';
import 'package:vortek/models/user.dart';

import 'helpers/integration_auth.dart';

/// 真实后端 M2 链路冒烟（替代部分双跑项）。
void main() {
  test('登录 → 好友/群/摘要 → 私聊发送 API', () async {
    final dio = IntegrationAuth.dio();
    final login = await IntegrationAuth.login(dio);
    final headers = IntegrationAuth.authedOptions(login.accessToken);

    final selfRes = await dio.get<Map<String, dynamic>>(
      '/user/self',
      options: headers,
    );
    final selfApi = ApiResponse.fromBody(selfRes.data);
    expect(selfApi.isOk, isTrue);
    final self = User.fromJson((selfApi.data as Map).cast<String, dynamic>());
    expect(self.id, greaterThan(0), reason: 'userId 应由 /user/self 补齐');

    final friendsRes = await dio.get<dynamic>('/friend/list', options: headers);
    final friends = (ApiResponse.fromBody(friendsRes.data).data as List)
        .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(friends, isA<List<Friend>>());

    final groupsRes = await dio.get<dynamic>('/group/list', options: headers);
    final groups = (ApiResponse.fromBody(groupsRes.data).data as List)
        .map((e) => Group.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(groups, isA<List<Group>>());

    final summaryRes = await dio.get<Map<String, dynamic>>(
      '/message/offline/sessionSummary',
      options: headers,
    );
    final summaries = (ApiResponse.fromBody(summaryRes.data).data as List)
        .map((e) => ChatSessionSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(summaries, isA<List<ChatSessionSummary>>());

    int? friendId;
    for (final s in summaries) {
      if (s.type == ChatType.private && s.targetId != self.id) {
        friendId = s.targetId;
        break;
      }
    }
    friendId ??= friends.isNotEmpty ? friends.first.id : null;

    if (friendId != null) {
      final tmpId = MessageTmpId.next();
      final sendRes = await dio.post<Map<String, dynamic>>(
        '/message/private/send',
        data: PrivateMessageDTO(
          tmpId: tmpId,
          recvId: friendId,
          content: 'm2-live-test-${DateTime.now().millisecondsSinceEpoch}',
        ).toJson(),
        options: headers,
      );
      final sendApi = ApiResponse.fromBody(sendRes.data);
      expect(sendApi.isOk, isTrue, reason: '${sendApi.code} ${sendApi.message}');
      if (sendApi.data is Map) {
        final sent = PrivateMessage.fromJson(
          (sendApi.data as Map).cast<String, dynamic>(),
        );
        expect(sent.id, isNotNull);
      }
    }

    ChatSessionSummary? groupSummary;
    for (final s in summaries) {
      if (s.type == ChatType.group) {
        groupSummary = s;
        break;
      }
    }
    final groupId =
        groupSummary?.targetId ?? (groups.isNotEmpty ? groups.first.id : null);
    if (groupId != null) {
      final tmpId = MessageTmpId.next();
      final sendRes = await dio.post<Map<String, dynamic>>(
        '/message/group/send',
        data: GroupMessageDTO(
          tmpId: tmpId,
          groupId: groupId,
          content: 'm2-group-live-${DateTime.now().millisecondsSinceEpoch}',
        ).toJson(),
        options: headers,
      );
      final api = ApiResponse.fromBody(sendRes.data);
      expect(api.isOk, isTrue, reason: '${api.code} ${api.message}');
      if (api.data is Map) {
        expect(api.data, isA<Map>());
      }
    }
  });
}
