import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/enums/cmd_type.dart';
import 'package:vortek/core/enums/message_status.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/models/chat_session_summary.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/services/message_dispatcher.dart';
import 'package:vortek/services/offline_sync.dart';
import 'package:vortek/stores/chat_store.dart';
import 'package:vortek/stores/user_store.dart';

import 'helpers/integration_auth.dart';

/// M2 端到端：登录摘要 → 合并 → 离线回放 → 去重。
void main() {
  test('sessionSummary 合并 + 离线回放不重复涨未读', () async {
    final dio = IntegrationAuth.dio();
    final login = await IntegrationAuth.withNetworkRetry(
      () => IntegrationAuth.login(dio),
    );
    final selfId = login.userId;

    final summaryRes = await IntegrationAuth.withNetworkRetry(
      () => dio.get<Map<String, dynamic>>(
        '/message/offline/sessionSummary',
        options: IntegrationAuth.authedOptions(login.accessToken),
      ),
    );
    final api = ApiResponse.fromBody(summaryRes.data);
    expect(api.isOk, isTrue);

    final summaries = (api.data as List)
        .map((e) => ChatSessionSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userStoreProvider.overrideWith(
          () => _FakeUserStore(User(id: selfId, userName: 'me', nickName: '我')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final store = container.read(chatStoreProvider);
    await store.applySessionSummaries(summaries);

    final chats = await db.chatDao.watchChatList().first;
    expect(chats.length, summaries.length);

    ChatSessionSummary? private;
    for (final s in summaries) {
      if (s.type == ChatType.private) {
        private = s;
        break;
      }
    }
    if (private == null) return;

    final friendId = private.targetId;
    final dispatcher = container.read(messageDispatcherProvider);
    final payload = {
      'id': 999001,
      'sendId': friendId,
      'recvId': selfId,
      'type': MessageType.text,
      'content': 'offline-dup-test',
      'status': MessageStatus.delivered,
      'sendTime': DateTime.now().millisecondsSinceEpoch,
    };
    await dispatcher.dispatch(CmdType.privateMessage, payload);
    await dispatcher.dispatch(CmdType.privateMessage, payload);

    final chat = await db.chatDao.findChat(ChatType.private, friendId);
    expect(chat!.unreadCount, 1);

    final msgs = await db.messageDao.watchMessages(ChatType.private, friendId).first;
    expect(msgs.where((m) => m.id == 999001).length, 1);
  });

  test('pullChatOffline 回放后 mark messagesLoaded', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userStoreProvider.overrideWith(
          () => _FakeUserStore(const User(id: 1, userName: 'u1', nickName: '我')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final store = container.read(chatStoreProvider);
    await store.openChat(type: ChatType.private, targetId: 2, showName: '好友');
    await store.markChatMessagesLoaded(ChatType.private, 2);

    await container.read(offlineSyncProvider).pullChatOffline(
          chatType: ChatType.private,
          targetId: 2,
        );

    final chat = await db.chatDao.findChat(ChatType.private, 2);
    expect(chat!.messagesLoaded, isTrue);
  });
}

class _FakeUserStore extends UserStore {
  _FakeUserStore(this._user);

  final User _user;

  @override
  User? build() => _user;
}
