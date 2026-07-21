import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums/message_type.dart';
import '../models/friend.dart';
import '../models/group_message.dart';
import '../models/private_message.dart';
import '../router/app_router.dart';
import '../stores/chat_store.dart';
import '../stores/friend_store.dart';

class RtcService {
  RtcService(this.ref);

  final Ref ref;
  final _privateSignalController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _groupSignalController =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _privateRtcPageOpen = false;
  bool _groupRtcPageOpen = false;

  Stream<Map<String, dynamic>> get privateRtcSignals =>
      _privateSignalController.stream;

  Stream<Map<String, dynamic>> get groupRtcSignals =>
      _groupSignalController.stream;

  bool get isPrivateRtcPageOpen => _privateRtcPageOpen;

  bool get isGroupRtcPageOpen => _groupRtcPageOpen;

  void setPrivateRtcPageOpen(bool open) => _privateRtcPageOpen = open;

  void setGroupRtcPageOpen(bool open) => _groupRtcPageOpen = open;

  void dispose() {
    unawaited(_privateSignalController.close());
    unawaited(_groupSignalController.close());
  }

  void forwardPrivateSignal(
    Map<String, dynamic> msg, {
    Duration delay = Duration.zero,
  }) {
    _forwardSignal(_privateSignalController, msg, delay: delay);
  }

  void forwardGroupSignal(
    Map<String, dynamic> msg, {
    Duration delay = Duration.zero,
  }) {
    _forwardSignal(_groupSignalController, msg, delay: delay);
  }

  void _forwardSignal(
    StreamController<Map<String, dynamic>> controller,
    Map<String, dynamic> msg, {
    Duration delay = Duration.zero,
  }) {
    if (delay == Duration.zero) {
      controller.add(msg);
      return;
    }
    Future.delayed(delay, () {
      if (!controller.isClosed) {
        controller.add(msg);
      }
    });
  }

  Future<void> handlePrivateRtcSignal(
    PrivateMessage msg, {
    required int friendId,
  }) async {
    var delay = const Duration(milliseconds: 100);
    if (msg.type == MessageType.rtcSetupVoice ||
        msg.type == MessageType.rtcSetupVideo) {
      if (!_privateRtcPageOpen) {
        final friend = _loadFriend(friendId);
        final mode =
            msg.type == MessageType.rtcSetupVideo ? 'video' : 'voice';
        openIncomingCall(mode: mode, friend: friend);
        delay = const Duration(milliseconds: 500);
      }
    }
    forwardPrivateSignal(msg.toJson(), delay: delay);
  }

  Future<void> handleGroupRtcSignal(GroupMessage msg) async {
    var delay = const Duration(milliseconds: 100);
    if (msg.type == MessageType.rtcGroupSetup) {
      if (!_groupRtcPageOpen) {
        openIncomingGroupCall(
          groupId: msg.groupId,
          inviterId: msg.sendId,
          userInfosJson: msg.content ?? '[]',
        );
        delay = const Duration(milliseconds: 500);
      }
    }
    forwardGroupSignal(msg.toJson(), delay: delay);
  }

  void openOutgoingGroupCall({
    required int groupId,
    required int inviterId,
    required List<Map<String, dynamic>> userInfos,
  }) {
    _pushGroupRtcPage(
      groupId: groupId,
      inviterId: inviterId,
      isHost: true,
      userInfos: userInfos,
    );
  }

  void openIncomingGroupCall({
    required int groupId,
    required int inviterId,
    required String userInfosJson,
  }) {
    final userInfos = _parseUserInfos(userInfosJson);
    _pushGroupRtcPage(
      groupId: groupId,
      inviterId: inviterId,
      isHost: false,
      userInfos: userInfos,
    );
  }

  void openJoinGroupCall({
    required int groupId,
    required int inviterId,
    required List<Map<String, dynamic>> userInfos,
  }) {
    _pushGroupRtcPage(
      groupId: groupId,
      inviterId: inviterId,
      isHost: false,
      userInfos: userInfos,
    );
  }

  bool openOutgoingCall({
    required String mode,
    required Friend friend,
  }) {
    return _pushRtcPage(mode: mode, friend: friend, isHost: true);
  }

  void openIncomingCall({
    required String mode,
    required Friend friend,
  }) {
    _pushRtcPage(mode: mode, friend: friend, isHost: false);
  }

  Future<void> insertPrivateActMessageFromWebView(dynamic data) async {
    final map = _parseActRtPayload(data);
    if (map == null) return;
    try {
      final msg = PrivateMessage.fromJson(map);
      await ref.read(chatStoreProvider).insertPrivate(
            msg,
            incrementUnread: false,
          );
    } catch (e) {
      
    }
  }

  Future<void> insertGroupActMessageFromWebView(
    dynamic data, {
    required int groupId,
  }) async {
    final map = _parseActRtPayload(data);
    if (map == null) return;
    try {
      map['groupId'] = groupId;
      final msg = GroupMessage.fromJson(map);
      await ref.read(chatStoreProvider).insertGroup(
            msg,
            incrementUnread: false,
          );
    } catch (e) {
      
    }
  }

  Map<String, dynamic>? _parseActRtPayload(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final type = map['type'];
    if (type != MessageType.actRtVoice && type != MessageType.actRtVideo) {
      return null;
    }
    return map;
  }

  void _pushGroupRtcPage({
    required int groupId,
    required int inviterId,
    required bool isHost,
    required List<Map<String, dynamic>> userInfos,
  }) {
    if (_groupRtcPageOpen) return;
    try {
      ref.read(goRouterProvider).push(
            AppRoutes.chatRtcGroupPath(
              groupId: groupId,
              inviterId: inviterId,
              isHost: isHost,
              userInfos: userInfos,
            ),
          );
    } catch (e) {
      
    }
  }

  bool _pushRtcPage({
    required String mode,
    required Friend friend,
    required bool isHost,
  }) {
    if (_privateRtcPageOpen) return false;
    try {
      ref.read(goRouterProvider).push(
            AppRoutes.chatRtcPrivatePath(
              mode: mode,
              friend: friend,
              isHost: isHost,
            ),
          );
      return true;
    } catch (e) {
      
      return false;
    }
  }

  List<Map<String, dynamic>> _parseUserInfos(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Friend _loadFriend(int id) {
    final friend = ref.read(friendStoreProvider.notifier).byId(id);
    return friend ??
        Friend(
          id: id,
          showNickName: '鏈煡鐢ㄦ埛',
          headImage: '',
        );
  }
}

final rtcServiceProvider = Provider<RtcService>((ref) {
  final service = RtcService(ref);
  ref.onDispose(service.dispose);
  return service;
});

