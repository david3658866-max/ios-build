import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/storage/app_database.dart' hide Friend, Group;
import 'package:vortek/models/chat_session_summary.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/stores/chat_store.dart';
import 'package:vortek/stores/friend_store.dart';
import 'package:vortek/stores/group_store.dart';
import 'package:vortek/stores/user_store.dart';

void main() {
  test('enrichFromContacts 用好友/群资料补全会话名', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userStoreProvider.overrideWith(
          () => _FakeUserStore(const User(id: 1, userName: 'u1', nickName: '我')),
        ),
        friendStoreProvider.overrideWith(() => _FakeFriendStore(const [
          Friend(id: 2, showNickName: '张三', headImage: 'http://a.png'),
        ])),
        groupStoreProvider.overrideWith(() => _FakeGroupStore(const [
          Group(id: 10, showGroupName: '测试群', headImageThumb: 'http://g.png'),
        ])),
      ],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final store = container.read(chatStoreProvider);
    await store.openChat(type: ChatType.private, targetId: 2, showName: '未知用户');
    await store.openChat(type: ChatType.group, targetId: 10, showName: '未知群聊');
    await store.enrichFromContacts();

    final priv = await db.chatDao.findChat(ChatType.private, 2);
    final grp = await db.chatDao.findChat(ChatType.group, 10);
    expect(priv!.showName, '张三');
    expect(priv.headImage, 'http://a.png');
    expect(grp!.showName, '测试群');
    expect(grp.headImage, 'http://g.png');
  });

  test('applySessionSummaries 合并时用好友资料补 showName', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userStoreProvider.overrideWith(
          () => _FakeUserStore(const User(id: 1, userName: 'u1', nickName: '我')),
        ),
        friendStoreProvider.overrideWith(() => _FakeFriendStore(const [
          Friend(id: 2, showNickName: '李四', headImage: 'http://b.png'),
        ])),
        groupStoreProvider.overrideWith(() => _FakeGroupStore(const [])),
      ],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final store = container.read(chatStoreProvider);
    await store.applySessionSummaries(const [
      ChatSessionSummary(
        type: ChatType.private,
        targetId: 2,
        lastContent: 'hi',
        maxMsgId: 10,
      ),
    ]);

    final chat = await db.chatDao.findChat(ChatType.private, 2);
    expect(chat!.showName, '李四');
    expect(chat.headImage, 'http://b.png');
  });

  test('clearAllData 清空会话与消息', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userStoreProvider.overrideWith(
          () => _FakeUserStore(const User(id: 1, userName: 'u1', nickName: '我')),
        ),
      ],
    );
    addTearDown(() {
      container.dispose();
      db.close();
    });

    final store = container.read(chatStoreProvider);
    await store.openChat(type: ChatType.private, targetId: 2, showName: 'x');
    await store.clearAllData();

    final chats = await db.chatDao.watchChatList().first;
    expect(chats, isEmpty);
  });
}

class _FakeUserStore extends UserStore {
  _FakeUserStore(this._user);
  final User _user;
  @override
  User? build() => _user;
}

class _FakeFriendStore extends FriendStore {
  _FakeFriendStore(this._friends);
  final List<Friend> _friends;
  @override
  FriendState build() => FriendState(friends: _friends);
}

class _FakeGroupStore extends GroupStore {
  _FakeGroupStore(this._groups);
  final List<Group> _groups;
  @override
  List<Group> build() => _groups;
}
