import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/enums/cmd_type.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/models/private_message.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/services/message_dispatcher.dart';
import 'package:vortek/stores/chat_store.dart';
import 'package:vortek/stores/user_store.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userStoreProvider.overrideWith(
          () => _FakeUserStore(const User(id: 1, userName: 'u1', nickName: 'u1')),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('insertPrivate 写入会话与消息', () async {
    final store = container.read(chatStoreProvider);
    await store.insertPrivate(
      const PrivateMessage(
        id: 100,
        sendId: 2,
        recvId: 1,
        content: 'hello',
        type: MessageType.text,
        sendTime: 1000,
      ),
    );

    final chats = await db.chatDao.findChat(ChatType.private, 2);
    expect(chats, isNotNull);
    expect(chats!.lastContent, 'hello');
    expect(chats.unreadCount, 1);

    final msgs = await db.messageDao.watchMessages(ChatType.private, 2).first;
    expect(msgs.length, 1);
    expect(msgs.first.content, 'hello');
  });

  test('MessageDispatcher 分发 READED 清空未读', () async {
    final store = container.read(chatStoreProvider);
    await store.insertPrivate(
      const PrivateMessage(
        id: 101,
        sendId: 2,
        recvId: 1,
        content: 'hi',
        type: MessageType.text,
        sendTime: 2000,
      ),
    );
    final chat = await db.chatDao.findChat(ChatType.private, 2);
    expect(chat!.unreadCount, 1);

    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.privateMessage, {
      'sendId': 2,
      'recvId': 1,
      'type': MessageType.readed,
    });

    final after = await db.chatDao.findChat(ChatType.private, 2);
    expect(after!.unreadCount, 0);
  });
}

class _FakeUserStore extends UserStore {
  _FakeUserStore(this._user);

  final User _user;

  @override
  User? build() => _user;
}
