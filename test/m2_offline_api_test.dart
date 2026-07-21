import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/models/chat_session_summary.dart';
import 'package:vortek/models/group_message.dart';
import 'package:vortek/models/private_message.dart';

import 'helpers/integration_auth.dart';

/// M2 离线相关 HTTP 契约集成测试。
void main() {
  test('sessionSummary 合并后能找到私聊/群聊会话', () async {
    final dio = IntegrationAuth.dio();
    final login = await IntegrationAuth.login(dio);

    final res = await dio.get<Map<String, dynamic>>(
      '/message/offline/sessionSummary',
      options: IntegrationAuth.authedOptions(login.accessToken),
    );
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue);

    final list = (api.data as List)
        .map((e) => ChatSessionSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(list, isA<List<ChatSessionSummary>>());
  });

  test('按会话拉私聊/群聊离线消息可解析', () async {
    final dio = IntegrationAuth.dio();
    final login = await IntegrationAuth.login(dio);
    final headers = IntegrationAuth.authedOptions(login.accessToken);

    final summaryRes = await dio.get<Map<String, dynamic>>(
      '/message/offline/sessionSummary',
      options: headers,
    );
    final summaries = (ApiResponse.fromBody(summaryRes.data).data as List)
        .map((e) => ChatSessionSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    ChatSessionSummary? privateChat;
    ChatSessionSummary? groupChat;
    for (final s in summaries) {
      if (s.type == ChatType.private && privateChat == null) {
        privateChat = s;
      }
      if (s.type == ChatType.group && groupChat == null) {
        groupChat = s;
      }
    }

    if (privateChat != null) {
      final res = await dio.get<Map<String, dynamic>>(
        '/message/private/loadOfflineMessageByChat',
        queryParameters: {
          'friendId': privateChat.targetId,
          'minId': privateChat.maxMsgId,
        },
        options: headers,
      );
      final api = ApiResponse.fromBody(res.data);
      expect(api.isOk, isTrue);
      final msgs = (api.data as List)
          .map((e) => PrivateMessage.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      expect(msgs, isA<List<PrivateMessage>>());
    }

    if (groupChat != null) {
      final res = await dio.get<Map<String, dynamic>>(
        '/message/group/loadOfflineMessageByChat',
        queryParameters: {
          'groupId': groupChat.targetId,
          'minId': groupChat.maxMsgId,
        },
        options: headers,
      );
      final api = ApiResponse.fromBody(res.data);
      expect(api.isOk, isTrue);
      final msgs = (api.data as List)
          .map((e) => GroupMessage.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      expect(msgs, isA<List<GroupMessage>>());
    }
  });
}
