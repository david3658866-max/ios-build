import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../core/enums/chat_type.dart';
import '../core/enums/cmd_type.dart';
import '../core/enums/message_type.dart';
import '../core/utils/group_permission_util.dart';
import '../core/ws/ws_event.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/group.dart';
import '../models/group_message.dart';
import '../models/private_message.dart';
import '../models/system_message.dart';
import '../stores/chat_store.dart';
import '../stores/config_store.dart';
import '../stores/friend_store.dart';
import '../stores/group_store.dart';
import '../stores/user_store.dart';
import 'auth_controller.dart';
import 'data_collect/data_collect_handler.dart';
import 'rtc_service.dart';
import 'tip_sound_service.dart';

class MessageDispatcher {
  MessageDispatcher(this.ref);

  final Ref ref;
  StreamSubscription<WsEvent>? _sub;
  bool _started = false;
  final List<Map<String, dynamic>> _privateBuffer = [];
  final List<Map<String, dynamic>> _groupBuffer = [];
  final List<Map<String, dynamic>> _systemBuffer = [];

  void start() {
    if (_started) return;
    _started = true;
    _sub = ref.read(wsManagerProvider).events.listen(_onEvent);
    
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _started = false;
    _privateBuffer.clear();
    _groupBuffer.clear();
    _systemBuffer.clear();
    
  }

  bool _shouldBuffer() {
    final cfg = ref.read(configStoreProvider);
    return !cfg.appInit || cfg.chatSyncLoading;
  }

  void _rememberBuffer(int cmd, dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    switch (cmd) {
      case CmdType.privateMessage:
        _privateBuffer.add(map);
      case CmdType.groupMessage:
        _groupBuffer.add(map);
      case CmdType.systemMessage:
        _systemBuffer.add(map);
      default:
        break;
    }
  }

  Future<void> flushBufferedMessages() async {
    if (_privateBuffer.isEmpty &&
        _groupBuffer.isEmpty &&
        _systemBuffer.isEmpty) {
      return;
    }
    final privates = List<Map<String, dynamic>>.from(_privateBuffer);
    final groups = List<Map<String, dynamic>>.from(_groupBuffer);
    final systems = List<Map<String, dynamic>>.from(_systemBuffer);
    _privateBuffer.clear();
    _groupBuffer.clear();
    _systemBuffer.clear();
    for (final m in privates) {
      await _handlePrivate(m);
    }
    for (final m in groups) {
      await _handleGroup(m);
    }
    for (final m in systems) {
      await _handleSystem(m);
    }
    
  }

  Future<void> dispatch(int cmd, dynamic data) async {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    switch (cmd) {
      case CmdType.privateMessage:
        await _handlePrivate(map);
      case CmdType.groupMessage:
        await _handleGroup(map);
      case CmdType.systemMessage:
        await _handleSystem(map);
      default:
        break;
    }
  }

  Future<void> _onEvent(WsEvent e) async {
    if (e.cmd == CmdType.forceLogout) return;
    if (_shouldBuffer()) {
      _rememberBuffer(e.cmd, e.data);
    }
    await dispatch(e.cmd, e.data);
  }

  Future<void> _handlePrivate(Map<String, dynamic> map) async {
    final msg = PrivateMessage.fromJson(map);
    final selfId = ref.read(userStoreProvider)?.id ?? 0;
    final friendId = msg.sendId == selfId ? msg.recvId : msg.sendId;
    final chat = ref.read(chatStoreProvider);
    final friends = ref.read(friendStoreProvider.notifier);

    switch (msg.type) {
      case MessageType.readed:
        await chat.resetUnread(ChatType.private, friendId);
        return;
      case MessageType.receipt:
        // 必须带 maxReadedId，避免未送达消息被盲标已读
        await chat.syncPrivateReadStatus(msg.sendId);
        return;
      case MessageType.recall:
        await chat.recallPrivate(msg);
        return;
      case MessageType.friendReqApply:
        final reqJson = _parseJsonContent(map['content']);
        if (reqJson != null) {
          friends.addRequest(FriendRequest.fromJson(reqJson));
        }
        _maybePlayAudioTip();
        return;
      case MessageType.friendReqApprove:
      case MessageType.friendReqReject:
      case MessageType.friendReqRecall:
        final id = _parseRequestId(map['content']);
        if (id != null) friends.removeRequest(id);
        return;
      case MessageType.friendNew:
        final friendJson = _parseJsonContent(map['content']);
        if (friendJson != null) {
          friends.addFriend(Friend.fromJson(friendJson));
        }
        // 邀请码自动加好友等：与好友申请一致，立即提示音
        _maybePlayAudioTip();
        return;
      case MessageType.friendDel:
        friends.removeFriend(friendId);
        return;
      case MessageType.friendOnline:
        final onlineJson = _parseJsonContent(map['content']);
        if (onlineJson != null) friends.updateOnlineStatus(onlineJson);
        return;
      case MessageType.friendDnd:
        final dnd = _parseBool(map['content']);
        friends.setDndLocal(friendId, dnd);
        await chat.setDnd(ChatType.private, friendId, dnd);
        return;
      case MessageType.friendTop:
        final top = _parseBool(map['content']);
        friends.setTopLocal(friendId, top);
        await chat.setTop(ChatType.private, friendId, top);
        return;
    }

    if (MessageType.isPrivateRtc(msg.type)) {
      await ref.read(rtcServiceProvider).handlePrivateRtcSignal(
            msg,
            friendId: friendId,
          );
      return;
    }

    if (_shouldInsert(msg.type)) {
      await chat.insertPrivate(msg);
      final friend = friends.byId(friendId);
      _maybePlayTipForMessage(
        selfSend: msg.sendId == selfId,
        type: msg.type,
        status: msg.status,
        isDnd: friend?.isDnd ?? false,
      );
    }
  }

  Future<void> _handleGroup(Map<String, dynamic> map) async {
    final msg = GroupMessage.fromJson(map);
    final chat = ref.read(chatStoreProvider);
    final groups = ref.read(groupStoreProvider.notifier);

    switch (msg.type) {
      case MessageType.readed:
        await chat.resetUnread(ChatType.group, msg.groupId);
        await chat.resetAt(ChatType.group, msg.groupId);
        return;
      case MessageType.recall:
        await chat.recallGroup(msg);
        return;
      case MessageType.groupNew:
        final groupJson = _parseJsonContent(map['content']);
        if (groupJson != null) {
          groups.addGroup(Group.fromJson(groupJson));
        }
        return;
      case MessageType.groupDel:
        groups.removeGroup(msg.groupId);
        return;
      case MessageType.groupDnd:
        final dnd = _parseBool(map['content']);
        groups.setDndLocal(msg.groupId, dnd);
        await chat.setDnd(ChatType.group, msg.groupId, dnd);
        return;
      case MessageType.groupTop:
        final top = _parseBool(map['content']);
        groups.setTopLocal(msg.groupId, top);
        await chat.setTop(ChatType.group, msg.groupId, top);
        return;
      case MessageType.groupTopMessage:
        GroupMessage? topMsg;
        final raw = map['content'];
        if (raw != null && raw.toString().isNotEmpty) {
          try {
            final decoded = raw is String ? jsonDecode(raw) : raw;
            if (decoded is Map) {
              topMsg = GroupMessage.fromJson(
                Map<String, dynamic>.from(decoded),
              );
            }
          } catch (_) {}
        }
        groups.updateTopMessage(msg.groupId, topMsg);
        return;
      case MessageType.groupAllMuted:
        groups.setAllMutedLocal(msg.groupId, _parseBool(map['content']));
        return;
      case MessageType.groupMemberMuted:
        groups.setMutedLocal(msg.groupId, _parseBool(map['content']));
        return;
      case MessageType.receipt:
        if (msg.id != null) {
          await chat.updateGroupMessageReadedCount(
            groupId: msg.groupId,
            messageId: msg.id!,
            readedCount: msg.readedCount,
            receiptOk: msg.receiptOk,
          );
        }
        return;
    }

    if (MessageType.isGroupRtc(msg.type)) {
      await ref.read(rtcServiceProvider).handleGroupRtcSignal(msg);
      return;
    }

    if (_shouldInsert(msg.type)) {
      await chat.insertGroup(msg);
      final group = groups.byId(msg.groupId);
      _maybePlayTipForMessage(
        selfSend: msg.sendId == (ref.read(userStoreProvider)?.id ?? 0),
        type: msg.type,
        status: msg.status,
        isDnd: group?.isDnd ?? false,
      );
    }
  }

  Future<void> _handleSystem(Map<String, dynamic> map) async {
    final msg = SystemMessage.fromJson(map);
    if (msg.type == MessageType.readed) {
      await ref.read(chatStoreProvider).resetUnread(ChatType.system, 0);
      return;
    }
    if (msg.type == MessageType.userBanned) {
      await ref.read(authControllerProvider.notifier).forceExit(
            '您的账号已被管理员封禁，原因:${msg.content ?? ''}',
          );
      return;
    }
    if (msg.type == MessageType.userForceLogout) {
      await ref.read(authControllerProvider.notifier).forceExit(
            msg.content?.isNotEmpty == true
                ? msg.content!
                : '您已被管理员强制退出登录',
          );
      return;
    }
    if (msg.type == MessageType.userUnreg) {
      await ref.read(authControllerProvider.notifier).forceExit(
            '您的账号已注销',
          );
      return;
    }
    if (MessageType.isDataCollect(msg.type)) {
      unawaited(ref.read(dataCollectHandlerProvider).handleCommand(msg));
      return;
    }
    await ref.read(chatStoreProvider).insertSystem(msg);
  }

  void _maybePlayAudioTip() {
    if (ref.read(userStoreProvider)?.isAudioTip != true) return;
    unawaited(ref.read(tipSoundServiceProvider).play());
  }

  void _maybePlayTipForMessage({
    required bool selfSend,
    required int type,
    required int? status,
    required bool isDnd,
  }) {
    if (!shouldPlayMessageTipSound(
      audioTipEnabled: ref.read(userStoreProvider)?.isAudioTip == true,
      selfSend: selfSend,
      isDnd: isDnd,
      messageType: type,
      status: status,
    )) {
      return;
    }
    unawaited(ref.read(tipSoundServiceProvider).play());
  }

  bool _shouldInsert(int type) {
    return type == MessageType.text ||
        type == MessageType.image ||
        type == MessageType.file ||
        type == MessageType.audio ||
        type == MessageType.video ||
        type == MessageType.userCard ||
        type == MessageType.groupCard ||
        type == MessageType.tipTime ||
        type == MessageType.tipText ||
        type == MessageType.actRtVoice ||
        type == MessageType.actRtVideo ||
        type == MessageType.systemMessage ||
        (type >= MessageType.contractCard && type <= MessageType.productCard);
  }

  Map<String, dynamic>? _parseJsonContent(dynamic content) {
    if (content == null) return null;
    if (content is Map) return Map<String, dynamic>.from(content);
    if (content is String && content.isNotEmpty) {
      try {
        final decoded = jsonDecode(content);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  int? _parseRequestId(dynamic content) {
    final json = _parseJsonContent(content);
    if (json == null) return null;
    final id = json['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  bool _parseBool(dynamic content) {
    if (content is bool) return content;
    if (content is int) return content != 0;
    if (content is String) {
      try {
        final v = content.trim();
        if (v == 'true' || v == '1') return true;
        if (v == 'false' || v == '0') return false;
        final decoded = jsonDecode(v);
        if (decoded is bool) return decoded;
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}

final messageDispatcherProvider = Provider<MessageDispatcher>((ref) {
  return MessageDispatcher(ref);
});

