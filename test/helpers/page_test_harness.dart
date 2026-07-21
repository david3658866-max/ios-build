import 'dart:async';

import 'package:drift/native.dart';
import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/storage/app_database.dart' hide Friend, Group, GroupMember, FriendRequest;
import 'package:vortek/models/friend_request.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_member.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/stores/chat_store.dart';
import 'package:vortek/stores/config_store.dart';
import 'package:vortek/stores/friend_store.dart';
import 'package:vortek/stores/group_store.dart';
import 'package:vortek/stores/user_store.dart';
import 'package:vortek/services/offline_sync.dart';

/// 页面冒烟测试共用假数据与 Provider 覆盖。
abstract final class PageTestHarness {
  static const testUserId = 1;

  static final AppDatabase _sharedDb =
      AppDatabase.forTesting(NativeDatabase.memory());

  static User get testUser => const User(
        id: testUserId,
        userName: 'test_user',
        nickName: '测试用户',
      );

  static Group get testGroup => const Group(
        id: 100,
        name: '测试群聊',
        ownerId: testUserId,
        isAllowInvite: true,
        isAllowShareCard: true,
      );

  static List<GroupMember> get testMembers => const [
        GroupMember(
          userId: testUserId,
          showNickName: '测试用户',
          quit: false,
          isManager: false,
        ),
        GroupMember(
          userId: 2,
          showNickName: '群友A',
          quit: false,
          isManager: false,
        ),
      ];

  static baseOverrides({
    Group? group,
    List<GroupMember>? members,
  }) {
    final g = group ?? testGroup;
    final ms = members ?? testMembers;
    return [
      appDatabaseProvider.overrideWithValue(_sharedDb),
      userStoreProvider.overrideWith(() => _FakeUserStore(testUser)),
      groupStoreProvider.overrideWith(() => _FakeGroupStore(g, ms)),
      friendStoreProvider.overrideWith(_FakeFriendStore.new),
      chatStoreProvider.overrideWith(_FakeChatStore.new),
      lineProvider.overrideWith(_FakeLine.new),
      chatBadgeUnreadCountProvider.overrideWith(
        (ref) => Stream<int>.value(0),
      ),
    ];
  }

  /// 通讯录 Tab 冒烟：不挂 drift，避免测试结束残留 Timer。
  static friendTabOverrides() => [
        userStoreProvider.overrideWith(() => _FakeUserStore(testUser)),
        friendStoreProvider.overrideWith(_FakeFriendStore.new),
        configStoreProvider.overrideWith(_FakeConfigStore.new),
        chatListStreamProvider.overrideWith(
          (ref) => Stream<List<Chat>>.value(const []),
        ),
        chatBadgeUnreadCountProvider.overrideWith(
          (ref) => Stream<int>.value(0),
        ),
      ];

  /// 消息 Tab 冒烟：可配置初始化/WS 状态与会话列表。
  static messagesTabOverrides({
    ConfigState config = const ConfigState(appInit: true),
    List<Chat> chats = const [],
  }) =>
      [
        userStoreProvider.overrideWith(() => _FakeUserStore(testUser)),
        friendStoreProvider.overrideWith(_FakeFriendStore.new),
        configStoreProvider.overrideWith(
          () => _FakeConfigStoreWithState(config),
        ),
        chatListStreamProvider.overrideWith(
          (ref) => Stream<List<Chat>>.value(chats),
        ),
        chatListWindowProvider.overrideWith(
          (ref, limit) {
            final end = limit.clamp(0, chats.length);
            return Stream<List<Chat>>.value(chats.sublist(0, end));
          },
        ),
        chatCountStreamProvider.overrideWith(
          (ref) => Stream<int>.value(chats.length),
        ),
        chatListSearchProvider.overrideWith(
          (ref, query) {
            final filtered = chats
                .where((c) => (c.showName ?? '').contains(query.keyword))
                .take(query.limit)
                .toList();
            return Stream<List<Chat>>.value(filtered);
          },
        ),
        chatBadgeUnreadCountProvider.overrideWith(
          (ref) => Stream<int>.value(
            chats
                .where((c) => !c.isDnd)
                .fold<int>(0, (sum, chat) => sum + chat.unreadCount),
          ),
        ),
        lineProvider.overrideWith(_FakeLine.new),
      ];

  /// 好友资料/备注子页：带假好友数据，chat 不访问数据库。
  static friendDetailOverrides({
    List<Friend> friends = const [
      Friend(id: 2, nickName: '测试好友', showNickName: '测试好友'),
    ],
  }) =>
      [
        userStoreProvider.overrideWith(() => _FakeUserStore(testUser)),
        friendStoreProvider.overrideWith(
          () => _FakeFriendStoreWithFriends(friends),
        ),
        chatStoreProvider.overrideWith(_LightChatStore.new),
      ];

  /// 聊天页冒烟：跳过离线拉取与线路探活。
  static chatBoxOverrides({
    Group? group,
    List<GroupMember>? members,
  }) {
    final g = group ?? testGroup;
    final ms = members ?? testMembers;
    return [
      appDatabaseProvider.overrideWithValue(_sharedDb),
      userStoreProvider.overrideWith(() => _FakeUserStore(testUser)),
      groupStoreProvider.overrideWith(() => _FakeGroupStore(g, ms)),
      friendStoreProvider.overrideWith(_FakeFriendStore.new),
      lineProvider.overrideWith(_FakeLine.new),
      configStoreProvider.overrideWith(() => _FakeConfigStore()),
      offlineSyncProvider.overrideWith((ref) => _NoOpOfflineSync(ref)),
      chatStoreProvider.overrideWith(_ChatBoxChatStore.new),
    ];
  }
}

class _FakeUserStore extends UserStore {
  _FakeUserStore(this._user);

  final User _user;

  @override
  User? build() => _user;
}

class _FakeGroupStore extends GroupStore {
  _FakeGroupStore(this._group, this._members);

  final Group _group;
  final List<GroupMember> _members;

  @override
  List<Group> build() => [_group];

  @override
  Future<void> loadGroups() async {}

  @override
  Future<Group> loadGroupDetail(int groupId) async => _group;

  @override
  Future<List<GroupMember>> loadMembers(int groupId, {int version = 0}) async =>
      _members;

  @override
  List<GroupMember> membersOf(int groupId) => List.unmodifiable(_members);
}

class _FakeFriendStore extends FriendStore {
  @override
  FriendState build() => const FriendState();

  @override
  Future<void> loadFriends() async {}

  @override
  Future<List<FriendRequest>> loadRequests() async => const [];
}

class _FakeFriendStoreWithFriends extends FriendStore {
  _FakeFriendStoreWithFriends(this._friends);

  final List<Friend> _friends;

  @override
  FriendState build() => FriendState(friends: _friends);

  @override
  Future<void> modifyRemark(int friendId, String remark) async {}
}

class _FakeConfigStore extends ConfigStore {
  @override
  ConfigState build() => const ConfigState(appInit: true);
}

class _FakeConfigStoreWithState extends ConfigStore {
  _FakeConfigStoreWithState(this._state);

  final ConfigState _state;

  @override
  ConfigState build() => _state;
}

/// 消息 Tab 测试用线路：跳过 HTTP 探活。
class _FakeLine extends LineNotifier {
  @override
  LineConfig build() => kDefaultLine;

  @override
  Future<bool> checkCurrentLineStatus({bool allowFallback = true}) async =>
      true;
}

class _FakeChatStore extends ChatStore {
  _FakeChatStore(super.ref);

  @override
  Stream<List<Message>> watchMessages(
    String chatType,
    int targetId, {
    int limit = 30,
    int? beforeSendTime,
  }) =>
      Stream.value(const []);

  @override
  Future<void> activeSystemChat() async {}
}

class _LightChatStore extends ChatStore {
  _LightChatStore(super.ref);

  @override
  Future<Chat?> findChat(String type, int targetId) async => null;
}

class _ChatBoxChatStore extends ChatStore {
  _ChatBoxChatStore(super.ref);

  @override
  Stream<List<Chat>> watchChatList() => Stream.value(const []);

  @override
  Stream<List<Message>> watchMessages(
    String chatType,
    int targetId, {
    int limit = 30,
    int? beforeSendTime,
  }) =>
      Stream.value(const []);

  @override
  Future<void> activePrivateChat(int friendId) async {}

  @override
  Future<void> activeGroupChat(int groupId) async {}

  @override
  Future<void> resetUnread(String chatType, int targetId) async {}
}

class _NoOpOfflineSync extends OfflineSync {
  _NoOpOfflineSync(super.ref);

  @override
  Future<void> pullChatOffline({
    required String chatType,
    required int targetId,
    bool force = false,
  }) async {}

  @override
  Future<void> pullAfterWsLogin() async {}
}
