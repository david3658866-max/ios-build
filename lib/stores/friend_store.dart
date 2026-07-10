import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../core/enums/chat_type.dart';
import '../core/enums/message_type.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/user.dart';
import 'chat_store.dart';

class FriendState {
  const FriendState({
    this.friends = const [],
    this.requests = const [],
  });

  final List<Friend> friends;
  final List<FriendRequest> requests;

  FriendState copyWith({
    List<Friend>? friends,
    List<FriendRequest>? requests,
  }) {
    return FriendState(
      friends: friends ?? this.friends,
      requests: requests ?? this.requests,
    );
  }
}

class FriendStore extends Notifier<FriendState> {
  @override
  FriendState build() => const FriendState();

  Future<void> loadFriends() async {
    try {
      final friends = await ref.read(friendApiProvider).list();
      state = state.copyWith(friends: friends);
      try {
        await loadRequests();
      } catch (e) {
        
      }
    } catch (e) {
      
      rethrow;
    }
  }

  Friend? byId(int id) {
    for (final f in state.friends) {
      if (f.id == id) return f;
    }
    return null;
  }

  FriendRequest? findRequest(int id) {
    for (final r in state.requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  bool isFriend(int userId) {
    final f = byId(userId);
    return f != null && !f.deleted;
  }

  bool isPendingRequest(int userId) {
    return state.requests.any(
      (r) => r.recvId == userId && r.status == RequestStatus.pending,
    );
  }

  /// 从服务端刷新单个好友并保留在线状态。
  Future<Friend> refreshFriend(int friendId) async {
    final friend = await ref.read(friendApiProvider).find(friendId);
    _upsertFriend(friend);
    return friend;
  }

  Future<void> modifyRemark(int friendId, String remark) async {
    final updated =
        await ref.read(friendApiProvider).modifyRemark(friendId, remark);
    _upsertFriend(updated);
    final friend = await refreshFriend(friendId);
    await syncChatFromFriend(friend);
  }

  Future<void> setDnd(int friendId, bool isDnd) async {
    _patchFriend(friendId, isDnd: isDnd);
    await ref.read(chatStoreProvider).setDnd(ChatType.private, friendId, isDnd);
    try {
      await ref.read(friendApiProvider).setDnd(friendId, isDnd);
    } catch (e) {
      _patchFriend(friendId, isDnd: !isDnd);
      await ref.read(chatStoreProvider).setDnd(ChatType.private, friendId, !isDnd);
      rethrow;
    }
  }

  Future<void> setTop(int friendId, bool isTop) async {
    _patchFriend(friendId, isTop: isTop);
    await ref.read(chatStoreProvider).setTop(ChatType.private, friendId, isTop);
    try {
      await ref.read(friendApiProvider).setTop(friendId, isTop);
    } catch (e) {
      _patchFriend(friendId, isTop: !isTop);
      await ref.read(chatStoreProvider).setTop(ChatType.private, friendId, !isTop);
      rethrow;
    }
  }

  void addRequest(FriendRequest request) {
    if (state.requests.any((r) => r.id == request.id)) return;
    state = state.copyWith(requests: [request, ...state.requests]);
  }

  void removeRequest(int id) => _removeRequest(id);

  void addFriend(Friend friend) {
    _upsertFriend(friend);
    unawaited(syncChatFromFriend(friend));
  }

  void removeFriend(int id) {
    final list = state.friends.map((f) {
      if (f.id != id) return f;
      return Friend(
        id: f.id,
        nickName: f.nickName,
        showNickName: f.showNickName,
        remarkNickName: f.remarkNickName,
        headImage: f.headImage,
        companyName: f.companyName,
        isDnd: f.isDnd,
        isTop: f.isTop,
        deleted: true,
        online: f.online,
        onlineWeb: f.onlineWeb,
        onlineApp: f.onlineApp,
      );
    }).toList();
    state = state.copyWith(friends: list);
  }

  void updateOnlineStatus(Map<String, dynamic> data) {
    final userId = data['userId'];
    final id = userId is int ? userId : int.tryParse('$userId');
    if (id == null) return;
    final terminal = data['terminal'] is int
        ? data['terminal'] as int
        : int.tryParse('${data['terminal']}');
    final online = data['online'] == true ||
        data['online'] == 1 ||
        data['online'] == 'true';

    final list = state.friends.map((f) {
      if (f.id != id) return f;
      var web = f.onlineWeb;
      var app = f.onlineApp;
      if (terminal == TerminalType.web) {
        web = online;
      } else if (terminal == TerminalType.app) {
        app = online;
      }
      return Friend(
        id: f.id,
        nickName: f.nickName,
        showNickName: f.showNickName,
        remarkNickName: f.remarkNickName,
        headImage: f.headImage,
        companyName: f.companyName,
        isDnd: f.isDnd,
        isTop: f.isTop,
        deleted: f.deleted,
        online: web || app,
        onlineWeb: web,
        onlineApp: app,
      );
    }).toList();
    state = state.copyWith(friends: list);
  }

  void setDndLocal(int friendId, bool isDnd) {
    _patchFriend(friendId, isDnd: isDnd);
  }

  void setTopLocal(int friendId, bool isTop) {
    _patchFriend(friendId, isTop: isTop);
  }

  Future<void> updateFriendFromUser(User user) async {
    final friend = byId(user.id);
    if (friend == null || friend.deleted) return;
    final nick = user.nickName ?? friend.nickName;
    final remark = friend.remarkNickName?.trim();
    final showNick =
        (remark != null && remark.isNotEmpty) ? remark : nick;
    final updated = Friend(
      id: friend.id,
      nickName: nick,
      showNickName: showNick,
      remarkNickName: friend.remarkNickName,
      headImage: user.headImageThumb ?? user.headImage ?? friend.headImage,
      companyName: friend.companyName,
      isDnd: friend.isDnd,
      isTop: friend.isTop,
      deleted: friend.deleted,
      online: friend.online,
      onlineWeb: friend.onlineWeb,
      onlineApp: friend.onlineApp,
    );
    _upsertFriend(updated);
    await syncChatFromFriend(updated);
  }

  Future<void> syncChatFromFriend(Friend friend) async {
    if (friend.deleted) return;
    final name = friend.showNickName?.trim();
    if (name == null || name.isEmpty) return;
    await ref.read(chatStoreProvider).updateContactProfile(
          type: ChatType.private,
          targetId: friend.id,
          showName: name,
          headImage: friend.headImage,
          companyName: friend.companyName,
          isDnd: friend.isDnd,
          isTop: friend.isTop,
        );
  }

  Future<List<FriendRequest>> loadRequests() async {
    final requests = await ref.read(friendApiProvider).requestList();
    state = state.copyWith(requests: requests);
    return requests;
  }

  Future<FriendRequest> applyRequest({
    required int friendId,
    String? remark,
  }) async {
    final req = await ref.read(friendApiProvider).apply(
          friendId: friendId,
          remark: remark,
        );
    if (req.status == RequestStatus.approved) {
      await loadFriends();
    } else if (req.status == RequestStatus.pending) {
      addRequest(req);
    }
    return req;
  }

  Future<void> approveRequest(int id) async {
    await ref.read(friendApiProvider).approve(id);
    _removeRequest(id);
    await loadFriends();
  }

  Future<void> rejectRequest(int id) async {
    await ref.read(friendApiProvider).reject(id);
    _removeRequest(id);
  }

  Future<void> recallRequest(int id) async {
    await ref.read(friendApiProvider).recall(id);
    _removeRequest(id);
  }

  void _upsertFriend(Friend friend) {
    final list = [...state.friends];
    final idx = list.indexWhere((f) => f.id == friend.id);
    if (idx >= 0) {
      final old = list[idx];
      list[idx] = Friend(
        id: friend.id,
        nickName: friend.nickName,
        showNickName: friend.showNickName,
        remarkNickName: friend.remarkNickName,
        headImage: friend.headImage,
        companyName: friend.companyName,
        isDnd: friend.isDnd,
        isTop: friend.isTop,
        deleted: friend.deleted,
        online: old.online,
        onlineWeb: old.onlineWeb,
        onlineApp: old.onlineApp,
      );
    } else {
      list.add(friend);
    }
    state = state.copyWith(friends: list);
  }

  void _patchFriend(int friendId, {bool? isDnd, bool? isTop}) {
    final list = state.friends.map((f) {
      if (f.id != friendId) return f;
      return Friend(
        id: f.id,
        nickName: f.nickName,
        showNickName: f.showNickName,
        remarkNickName: f.remarkNickName,
        headImage: f.headImage,
        companyName: f.companyName,
        isDnd: isDnd ?? f.isDnd,
        isTop: isTop ?? f.isTop,
        deleted: f.deleted,
        online: f.online,
        onlineWeb: f.onlineWeb,
        onlineApp: f.onlineApp,
      );
    }).toList();
    state = state.copyWith(friends: list);
  }

  void _addRequest(FriendRequest request) {
    state = state.copyWith(requests: [request, ...state.requests]);
  }

  void _removeRequest(int id) {
    state = state.copyWith(
      requests: state.requests.where((r) => r.id != id).toList(),
    );
  }
}

final friendStoreProvider =
    NotifierProvider<FriendStore, FriendState>(FriendStore.new);

