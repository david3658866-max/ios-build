import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums/message_type.dart';
import '../models/friend.dart';
import '../models/group_message.dart';
import '../models/private_message.dart';
import '../stores/chat_store.dart';

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
  }) async {}

  Future<void> handleGroupRtcSignal(GroupMessage msg) async {}

  void openOutgoingGroupCall({
    required int groupId,
    required int inviterId,
    required List<Map<String, dynamic>> userInfos,
  }) {}

  void openIncomingGroupCall({
    required int groupId,
    required int inviterId,
    required String userInfosJson,
  }) {}

  void openJoinGroupCall({
    required int groupId,
    required int inviterId,
    required List<Map<String, dynamic>> userInfos,
  }) {}

  bool openOutgoingCall({
    required String mode,
    required Friend friend,
  }) =>
      false;

  void openIncomingCall({
    required String mode,
    required Friend friend,
  }) {}

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

}

final rtcServiceProvider = Provider<RtcService>((ref) {
  final service = RtcService(ref);
  ref.onDispose(service.dispose);
  return service;
});

