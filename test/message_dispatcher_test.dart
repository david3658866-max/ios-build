import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/enums/cmd_type.dart';
import 'package:vortek/core/enums/message_status.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/storage/app_database.dart' hide Group;
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_message.dart';
import 'package:vortek/models/private_message.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/services/message_dispatcher.dart';
import 'package:vortek/stores/chat_store.dart';
import 'package:vortek/stores/group_store.dart';
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
          () => _FakeUserStore(const User(id: 1, userName: 'u1', nickName: '我')),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('dispatch 私聊文字入库并更新会话', () async {
    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.privateMessage, {
      'id': 200,
      'sendId': 2,
      'recvId': 1,
      'type': MessageType.text,
      'content': 'hello',
      'status': MessageStatus.delivered,
      'sendTime': 3000,
    });

    final chat = await db.chatDao.findChat(ChatType.private, 2);
    expect(chat, isNotNull);
    expect(chat!.lastContent, 'hello');
    expect(chat.unreadCount, 1);

    final msgs = await db.messageDao.watchMessages(ChatType.private, 2).first;
    expect(msgs.length, 1);
    expect(msgs.first.id, 200);
  });

  test('dispatch 群聊文字入库', () async {
    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.groupMessage, {
      'id': 301,
      'groupId': 10,
      'sendId': 2,
      'sendNickName': '张三',
      'type': MessageType.text,
      'content': '群消息',
      'status': MessageStatus.delivered,
      'sendTime': 4000,
    });

    final chat = await db.chatDao.findChat(ChatType.group, 10);
    expect(chat!.lastContent, '群消息');
    expect(chat.sendNickName, '张三');
  });

  test('dispatch 私聊撤回替换为 tip', () async {
    final store = container.read(chatStoreProvider);
    await store.insertPrivate(
      const PrivateMessage(
        id: 50,
        sendId: 2,
        recvId: 1,
        content: '原消息',
        type: MessageType.text,
        sendTime: 1000,
      ),
    );

    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.privateMessage, {
      'sendId': 2,
      'recvId': 1,
      'type': MessageType.recall,
      'content': '50',
      'sendTime': 2000,
    });

    final msgs = await db.messageDao.watchMessages(ChatType.private, 2).first;
    expect(msgs.first.type, MessageType.tipText);
    expect(msgs.first.content, '对方撤回了一条消息');
    expect(msgs.first.status, MessageStatus.recall);
  });

  test('dispatch RECEIPT 标记己方消息已读', () async {
    final store = container.read(chatStoreProvider);
    await store.insertPrivate(
      const PrivateMessage(
        id: 60,
        sendId: 1,
        recvId: 2,
        content: '我发的',
        type: MessageType.text,
        status: MessageStatus.delivered,
        sendTime: 5000,
      ),
      incrementUnread: false,
    );

    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.privateMessage, {
      'sendId': 2,
      'recvId': 1,
      'type': MessageType.receipt,
    });

    final msgs = await db.messageDao.watchMessages(ChatType.private, 2).first;
    expect(msgs.first.status, MessageStatus.readed);
  });

  test('dispatch 群聊 @我 标记 atMe', () async {
    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.groupMessage, {
      'id': 302,
      'groupId': 10,
      'sendId': 2,
      'sendNickName': '张三',
      'type': MessageType.text,
      'content': '@我 看一下',
      'status': MessageStatus.delivered,
      'sendTime': 4001,
      'atUserIds': [1],
    });

    final chat = await db.chatDao.findChat(ChatType.group, 10);
    expect(chat!.atMe, isTrue);
    expect(chat.atAll, isFalse);
    expect(chat.lastAtMessageId, 302);
  });

  test('dispatch 同 id 重复推送不重复入库', () async {
    final dispatcher = container.read(messageDispatcherProvider);
    final payload = {
      'id': 400,
      'sendId': 2,
      'recvId': 1,
      'type': MessageType.text,
      'content': 'dup',
      'status': MessageStatus.delivered,
      'sendTime': 6000,
    };
    await dispatcher.dispatch(CmdType.privateMessage, payload);
    await dispatcher.dispatch(CmdType.privateMessage, payload);

    final msgs = await db.messageDao.watchMessages(ChatType.private, 2).first;
    expect(msgs.length, 1);
    expect(msgs.first.id, 400);

    final chat = await db.chatDao.findChat(ChatType.private, 2);
    expect(chat!.unreadCount, 1);
  });

  test('dispatch GROUP_TOP_MESSAGE 更新群置顶消息', () async {
    container.read(groupStoreProvider.notifier).state = [
      const Group(id: 10, name: '测试群'),
    ];

    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.groupMessage, {
      'groupId': 10,
      'sendId': 2,
      'type': MessageType.groupTopMessage,
      'content': jsonEncode({
        'id': 99,
        'groupId': 10,
        'sendId': 2,
        'content': '置顶内容',
        'type': MessageType.text,
        'sendTime': 5000,
      }),
      'sendTime': 5000,
    });

    final group = container.read(groupStoreProvider.notifier).byId(10);
    expect(group?.topMessage?.id, 99);
    expect(group?.topMessage?.content, '置顶内容');
  });

  test('dispatch GROUP_TOP_MESSAGE 空 content 清除置顶', () async {
    container.read(groupStoreProvider.notifier).state = [
      Group(
        id: 10,
        name: '测试群',
        topMessage: const GroupMessage(
          id: 99,
          groupId: 10,
          sendId: 2,
          content: '旧置顶',
          type: MessageType.text,
        ),
      ),
    ];

    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.groupMessage, {
      'groupId': 10,
      'sendId': 2,
      'type': MessageType.groupTopMessage,
      'content': '',
      'sendTime': 6000,
    });

    expect(
      container.read(groupStoreProvider.notifier).byId(10)?.topMessage,
      isNull,
    );
  });

  test('dispatch 群 RECEIPT 更新 readedCount', () async {
    final store = container.read(chatStoreProvider);
    await store.insertGroup(
      const GroupMessage(
        id: 88,
        groupId: 10,
        sendId: 1,
        content: '回执消息',
        type: MessageType.text,
        receipt: true,
        sendTime: 7000,
      ),
      incrementUnread: false,
    );

    final dispatcher = container.read(messageDispatcherProvider);
    await dispatcher.dispatch(CmdType.groupMessage, {
      'id': 88,
      'groupId': 10,
      'sendId': 3,
      'type': MessageType.receipt,
      'readedCount': 5,
      'receiptOk': false,
      'sendTime': 7100,
    });

    final msgs = await db.messageDao.watchMessages(ChatType.group, 10).first;
    expect(msgs.first.readedCount, 5);
    expect(msgs.first.receiptOk, isFalse);
  });
}

class _FakeUserStore extends UserStore {
  _FakeUserStore(this._user);

  final User _user;

  @override
  User? build() => _user;
}
