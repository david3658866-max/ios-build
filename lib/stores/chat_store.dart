import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';

import '../api/api_providers.dart';
import '../core/di/app_providers.dart';
import '../core/enums/chat_type.dart';
import '../core/storage/sync_cursor_keys.dart';
import '../core/enums/message_status.dart';
import '../core/enums/message_type.dart';
import '../core/storage/app_database.dart' hide Friend, Group;
import '../core/http/api_result.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/string_util.dart';
import '../models/chat_session_summary.dart';
import '../models/friend.dart';
import '../models/group_message.dart';
import '../models/group_message_dto.dart';
import '../models/group.dart';
import '../models/private_message.dart';
import '../models/private_message_dto.dart';
import '../models/quote_message.dart';
import '../models/system_message.dart';
import '../models/user.dart';
import '../stores/user_store.dart';
import '../stores/friend_store.dart';
import '../stores/group_store.dart';
import '../core/utils/message_storage_util.dart';
import '../core/utils/message_tmp_id.dart';
import '../core/utils/message_send_queue.dart';
import '../core/utils/chat_media_meta_util.dart';
import '../services/upload_service.dart';

/// 会话 / 消息状态。对应原 Pinia chatStore（drift 单一数据源替代冷热分区）。
class ChatStore {
  ChatStore(this.ref);

  final Ref ref;
  final _apiSendQueue = MessageSendQueue();

  AppDatabase get _db => ref.read(appDatabaseProvider);
  int get _selfId => ref.read(userStoreProvider)?.id ?? 0;

  /// 发送 API 遇网络错误时切换可用线路；500/429 时延迟重试（最多 3 次）。
  Future<T> _sendWithLineRetry<T>(Future<T> Function() send) async {
    const maxAttempts = 3;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await send();
      } catch (e) {
        final api = asApiException(e);
        final retryable = isNetworkApiError(api) ||
            api.code == 500 ||
            api.code == 429;
        if (!retryable || attempt >= maxAttempts - 1) rethrow;
        if (isNetworkApiError(api)) {
          final line = ref.read(lineProvider);
          log.w('[Chat] send network error on ${line.id}, ensureAvailableLine');
          final ok = await ref.read(lineProvider.notifier).ensureAvailableLine();
          if (!ok) rethrow;
        } else {
          final delayMs = 800 * (attempt + 1);
          log.w('[Chat] send server busy code=${api.code}, retry in ${delayMs}ms');
          await Future<void>.delayed(Duration(milliseconds: delayMs));
        }
        log.i(
          '[Chat] send retry attempt=${attempt + 2} line=${ref.read(lineProvider).id}',
        );
      }
    }
    throw StateError('sendWithLineRetry unreachable');
  }

  Stream<List<Chat>> watchChatList() => _db.chatDao.watchChatList();

  /// 会话列表虚拟窗口：仅 watch 前 [limit] 条，减少大列表 rebuild 成本。
  Stream<List<Chat>> watchChatListWindow(int limit) =>
      _db.chatDao.watchChatListWindow(limit: limit);

  Stream<int> watchChatCount() => _db.chatDao.watchChatCount();

  Stream<int> watchChatBadgeUnreadCount() =>
      _db.chatDao.watchChatBadgeUnreadCount();

  Stream<List<Chat>> watchChatSearch(String keyword, {required int limit}) =>
      _db.chatDao.watchChatSearch(keyword: keyword, limit: limit);

  Stream<List<Message>> watchMessages(
    String chatType,
    int targetId, {
    int limit = 30,
    int? beforeSendTime,
  }) =>
      _db.messageDao.watchMessages(
        chatType,
        targetId,
        limit: limit,
        beforeSendTime: beforeSendTime,
      );

  /// 读取本地最近消息（进聊天页首屏，避免 Stream 首帧 loading 闪屏）。
  Future<List<Message>> readMessages(
    String chatType,
    int targetId, {
    int limit = 30,
    int? beforeSendTime,
  }) =>
      _db.messageDao.listMessages(
        chatType,
        targetId,
        limit: limit,
        beforeSendTime: beforeSendTime,
      );

  Future<void> applySessionSummaries(List<ChatSessionSummary> list) async {
    if (list.isEmpty) return;
    await _db.transaction(() async {
      for (final raw in list) {
        final s = _enrichSummary(raw);
        final localMax = await _db.messageDao.maxMessageId(s.type, s.targetId);
        await _db.chatDao.mergeFromSummary(s, localMaxMsgId: localMax);
      }
    });
    await enrichFromContacts();
  }

  /// 合并摘要用好友/群资料补全（对齐 uniapp updateChatSummary）。
  ChatSessionSummary _enrichSummary(ChatSessionSummary s) {
    if (s.type == ChatType.private) {
      final f = _findFriend(s.targetId);
      if (f != null && !f.deleted) {
        final name = f.showNickName?.trim();
        return ChatSessionSummary(
          type: s.type,
          targetId: s.targetId,
          lastContent: s.lastContent,
          lastSendTime: s.lastSendTime,
          sendNickName: s.sendNickName,
          unreadCount: s.unreadCount,
          maxMsgId: s.maxMsgId,
          showName: (name != null && name.isNotEmpty) ? name : s.showName,
          headImage: f.headImage ?? s.headImage,
          companyName: f.companyName ?? s.companyName,
          isDnd: f.isDnd,
          isTop: f.isTop,
        );
      }
    } else if (s.type == ChatType.group) {
      final g = _findGroup(s.targetId);
      if (g != null && !g.quit && !g.dissolve) {
        final name = (g.showGroupName ?? g.name)?.trim();
        return ChatSessionSummary(
          type: s.type,
          targetId: s.targetId,
          lastContent: s.lastContent,
          lastSendTime: s.lastSendTime,
          sendNickName: s.sendNickName,
          unreadCount: s.unreadCount,
          maxMsgId: s.maxMsgId,
          showName: (name != null && name.isNotEmpty) ? name : s.showName,
          headImage: g.headImageThumb ?? g.headImage ?? s.headImage,
          isDnd: g.isDnd,
          isTop: g.isTop,
        );
      }
    }
    return s;
  }

  Friend? _findFriend(int id) {
    for (final f in ref.read(friendStoreProvider).friends) {
      if (f.id == id) return f;
    }
    return null;
  }

  Group? _findGroup(int id) {
    for (final g in ref.read(groupStoreProvider)) {
      if (g.id == id) return g;
    }
    return null;
  }

  /// 用好友/群资料补全会话 showName、头像等。
  Future<void> enrichFromContacts() async {
    final friends = ref.read(friendStoreProvider).friends;
    final groups = ref.read(groupStoreProvider);
    await _db.transaction(() async {
      for (final f in friends) {
        if (f.deleted) continue;
        final name = f.showNickName?.trim();
        if (name == null || name.isEmpty) continue;
        await _db.chatDao.updateContactProfile(
          type: ChatType.private,
          targetId: f.id,
          showName: name,
          headImage: f.headImage,
          companyName: f.companyName,
          isDnd: f.isDnd,
          isTop: f.isTop,
        );
      }
      for (final g in groups) {
        if (g.quit || g.dissolve) continue;
        final name = (g.showGroupName ?? g.name)?.trim();
        if (name == null || name.isEmpty) continue;
        await _db.chatDao.updateContactProfile(
          type: ChatType.group,
          targetId: g.id,
          showName: name,
          headImage: g.headImageThumb ?? g.headImage,
          isDnd: g.isDnd,
          isTop: g.isTop,
        );
      }
    });
  }

  /// 登出/换号时清空本地会话与消息。
  Future<void> clearAllData() async {
    await _db.messageDao.clearAll();
    await _db.chatDao.clearAll();
  }

  /// 冷启动将残留 SENDING 标为 FAILED；超量时裁剪历史。对齐 uniapp loadChat + fliterMessage。
  Future<void> repairStaleSendingMessages() async {
    await _db.messageDao.markSendingAsFailed();
    final total = await _db.messageDao.totalMessageCount();
    if (total > MessageStorageConfig.maxTotalMessages) {
      await MessageStorageUtil.pruneMessages(_db.messageDao);
    }
  }

  Future<void> openChat({
    required String type,
    required int targetId,
    String? showName,
    String? headImage,
    String? companyName,
    bool isDnd = false,
    bool isTop = false,
  }) =>
      _db.chatDao.openChat(
        type: type,
        targetId: targetId,
        showName: showName,
        headImage: headImage,
        companyName: companyName,
        isDnd: isDnd,
        isTop: isTop,
      );

  Future<void> resetUnread(String type, int targetId) =>
      _db.chatDao.resetUnread(type, targetId);

  Future<void> resetAt(String type, int targetId) =>
      _db.chatDao.resetAt(type, targetId);

  Future<void> setTop(String type, int targetId, bool isTop) =>
      _db.chatDao.setTop(type, targetId, isTop);

  Future<void> setDnd(String type, int targetId, bool isDnd) =>
      _db.chatDao.setDnd(type, targetId, isDnd);

  /// 从列表移除会话（不删本地消息）。
  Future<void> removeChat(String type, int targetId) =>
      _db.chatDao.deleteChat(type, targetId);

  /// 删除群会话。对齐 uniapp chatStore.removeGroupChat。
  Future<void> removeGroupChat(int groupId) =>
      removeChat(ChatType.group, groupId);

  /// 用好友/群资料更新本地会话展示字段。对齐 updateChatFromFriend。
  Future<void> updateContactProfile({
    required String type,
    required int targetId,
    String? showName,
    String? headImage,
    String? companyName,
    bool? isDnd,
    bool? isTop,
  }) =>
      _db.chatDao.updateContactProfile(
        type: type,
        targetId: targetId,
        showName: showName,
        headImage: headImage,
        companyName: companyName,
        isDnd: isDnd,
        isTop: isTop,
      );

  /// 非好友私聊：仅当本地已有会话时更新头像昵称。对齐 updateChatFromUser。
  Future<void> syncChatFromUser(User user) async {
    final chat = await findChat(ChatType.private, user.id);
    if (chat == null) return;
    await updateContactProfile(
      type: ChatType.private,
      targetId: user.id,
      showName: user.nickName,
      headImage: user.headImageThumb ?? user.headImage,
      companyName: user.companyName,
    );
  }

  /// 更新消息 content JSON（如图片 thumbLoad）。对齐 uniapp msgInfo.content 写回。
  Future<void> patchMessageContent({
    required String chatType,
    required int chatTargetId,
    required Message msg,
    required String content,
  }) async {
    final tmpId = msg.tmpId;
    if (tmpId != null && tmpId.isNotEmpty) {
      await _db.messageDao.updateByTmpId(tmpId, content: content);
      return;
    }
    final id = msg.id;
    if (id != null) {
      await _db.messageDao.updateContentById(
        chatType: chatType,
        chatTargetId: chatTargetId,
        messageId: id,
        content: content,
      );
    }
  }

  /// 同步群资料到会话列表。对齐 chatStore.updateChatFromGroup。
  Future<void> syncChatFromGroup(Group group) async {
    final showName = (group.showGroupName ?? group.name)?.trim();
    if (showName == null || showName.isEmpty) return;
    await updateContactProfile(
      type: ChatType.group,
      targetId: group.id,
      showName: showName,
      headImage: group.headImageThumb,
    );
  }

  Future<void> readedPrivate({required int friendId, int? maxId}) =>
      _db.messageDao.markSelfReaded(
        chatType: ChatType.private,
        chatTargetId: friendId,
        maxId: maxId,
      );

  /// 进入会话：清未读 + 同步已读水位 + 标记已读（HTTP）。
  Future<void> activePrivateChat(int friendId) async {
    final chat = await findChat(ChatType.private, friendId);
    final hadUnread = (chat?.unreadCount ?? 0) > 0;
    await resetUnread(ChatType.private, friendId);
    await syncPrivateReadStatus(friendId);
    if (hadUnread) {
      try {
        await ref.read(messageApiProvider).readedPrivate(friendId);
      } catch (_) {
        // 离线时忽略
      }
    }
  }

  /// 从服务端拉取 maxReadedId，更新己方消息已读状态（对齐 chat-box loadReaded）。
  Future<void> syncPrivateReadStatus(int friendId) async {
    try {
      final maxId = await ref.read(messageApiProvider).maxReadedId(friendId);
      if (maxId > 0) {
        await readedPrivate(friendId: friendId, maxId: maxId);
      }
    } catch (_) {}
  }

  /// 进入群聊：清未读 + HTTP 已读。
  ///
  /// 对齐 uniapp `readedMessage` / `activeChat`：只清未读角标，**不**清 `atMe`。
  /// 「有人@我」由聊天页在 @ 消息进入可视区或用户点击定位后再 `resetAt`。
  Future<void> activeGroupChat(int groupId) async {
    final chat = await findChat(ChatType.group, groupId);
    final hadUnread = (chat?.unreadCount ?? 0) > 0;
    await resetUnread(ChatType.group, groupId);
    if (hadUnread) {
      try {
        await ref.read(messageApiProvider).readedGroup(groupId);
      } catch (_) {}
    }
  }

  /// 进入系统通知：清未读 + HTTP 已读（对齐 chat-system readedMessage）。
  Future<void> activeSystemChat() async {
    await resetUnread(ChatType.system, 0);
    try {
      final maxSeq = await _db.syncCursorDao
          .getCursor(SyncCursorKeys.systemMsgMaxSeqNo);
      if (maxSeq > 0) {
        await ref.read(messageApiProvider).readedSystem(maxSeq);
      }
    } catch (_) {}
  }

  /// 转发消息到多个会话。对齐 chat-box onForwardMessage。
  Future<String?> forwardMessage(Message msg, List<Chat> chats) async {
    if (chats.isEmpty) return null;
    final content = msg.content ?? '';
    final type = msg.type;
    var ok = 0;
    String? lastErr;

    for (final chat in chats) {
      try {
        if (chat.type == ChatType.private) {
          final sent = await ref.read(messageApiProvider).sendPrivate(
                PrivateMessageDTO(
                  tmpId: MessageTmpId.next(),
                  recvId: chat.targetId,
                  content: content,
                  type: type,
                ),
              );
          await insertPrivate(sent, incrementUnread: false);
        } else if (chat.type == ChatType.group) {
          final sent = await ref.read(messageApiProvider).sendGroup(
                GroupMessageDTO(
                  tmpId: MessageTmpId.next(),
                  groupId: chat.targetId,
                  content: content,
                  type: type,
                ),
              );
          await insertGroup(sent, incrementUnread: false);
        }
        ok++;
      } catch (e) {
        lastErr = asApiException(e).message;
      }
    }
    if (ok == 0) return lastErr ?? '转发失败';
    return null;
  }

  /// 发送群聊文字。成功返回 null，失败返回可读错误信息。
  Future<String?> sendGroupText({
    required int groupId,
    required String content,
    List<int> atUserIds = const [],
    int? quoteMessageId,
    QuoteMessage? quoteMessage,
    bool receipt = false,
  }) async {
    var text = content.trim();
    if (text.isEmpty && atUserIds.isEmpty) return null;
    if (receipt) {
      text = '[回执消息] $text';
    }

    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = GroupMessage(
      tmpId: tmpId,
      groupId: groupId,
      sendId: _selfId,
      content: text,
      type: MessageType.text,
      status: MessageStatus.sending,
      sendTime: now,
      atUserIds: atUserIds,
      quoteMessage: quoteMessage,
      receipt: receipt,
    );
    await insertGroup(pending, incrementUnread: false);

    return _apiSendQueue.run(() async {
      try {
        final sent = await _sendWithLineRetry(
          () => ref.read(messageApiProvider).sendGroup(
                GroupMessageDTO(
                  tmpId: tmpId,
                  groupId: groupId,
                  content: text,
                  atUserIds: atUserIds,
                  quoteMessageId: quoteMessageId,
                  receipt: receipt,
                ),
              ),
        );
        await _db.messageDao.updateByTmpId(
          tmpId,
          id: sent.id,
          status: sent.status,
          content: sent.content,
          quoteMessage: sent.quoteMessage,
        );
        await _db.chatDao.bumpLastMsgId(ChatType.group, groupId, sent.id);
        log.i('[Chat] sendGroup ok id=${sent.id}');
        return null;
      } catch (e, st) {
        final api = asApiException(e);
        log.w('[Chat] sendGroup failed code=${api.code} msg=${api.message}\n$st');
        await _db.messageDao.updateByTmpId(
          tmpId,
          status: MessageStatus.failed,
        );
        return api.message;
      }
    });
  }

  /// 发送群聊图片。选图→本地入库→上传→发 IMAGE 消息（对齐 sendPrivateImage）。
  Future<String?> sendGroupImage({
    required int groupId,
    required String localPath,
    int? width,
    int? height,
    bool receipt = false,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent = jsonEncode({
      'originUrl': localPath,
      'thumbUrl': localPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
    final pending = GroupMessage(
      tmpId: tmpId,
      groupId: groupId,
      sendId: _selfId,
      content: pendingContent,
      type: MessageType.image,
      status: MessageStatus.sending,
      sendTime: now,
      receipt: receipt,
    );
    await insertGroup(pending, incrementUnread: false);

    log.i('[Chat] sendGroupImage start tmpId=$tmpId groupId=$groupId');

    final baseMap = Map<String, dynamic>.from(jsonDecode(pendingContent) as Map);
    if (width == null || height == null) {
      unawaited(_patchLocalImageDimensions(
        tmpId: tmpId,
        localPath: localPath,
        base: baseMap,
      ));
    }

    try {
      final uploaded =
          await ref.read(uploadServiceProvider).uploadChatImage(localPath);
      final uploadedMap = Map<String, dynamic>.from(uploaded.toJson());
      if (width != null && uploaded.width == 0) uploadedMap['width'] = width;
      if (height != null && uploaded.height == 0) {
        uploadedMap['height'] = height;
      }
      final contentJson = jsonEncode(uploadedMap);
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendGroup(
            GroupMessageDTO(
              tmpId: tmpId,
              groupId: groupId,
              content: contentJson,
              type: MessageType.image,
              receipt: receipt,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.group, groupId, sent.id);
      log.i('[Chat] sendGroupImage ok id=${sent.id} status=${sent.status}');
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w(
        '[Chat] sendGroupImage failed code=${api.code} msg=${api.message}\n$st',
      );
      await _db.messageDao.updateByTmpId(
        tmpId,
        status: MessageStatus.failed,
      );
      return api.message;
    }
  }

  /// 发送个人名片到多个会话。对齐 user-info.vue onSendCard。
  Future<String?> sendUserCard({
    required int userId,
    required String nickName,
    String? headImage,
    required List<Chat> chats,
  }) async {
    if (chats.isEmpty) return null;
    final content = jsonEncode({
      'userId': userId,
      'nickName': nickName,
      'headImage': headImage,
    });
    var ok = 0;
    String? lastErr;

    for (final chat in chats) {
      final tmpId = MessageTmpId.next();
      final now = DateTime.now().millisecondsSinceEpoch;
      try {
        if (chat.type == ChatType.private) {
          final pending = PrivateMessage(
            tmpId: tmpId,
            sendId: _selfId,
            recvId: chat.targetId,
            content: content,
            type: MessageType.userCard,
            status: MessageStatus.sending,
            sendTime: now,
          );
          await insertPrivate(pending, incrementUnread: false);
          final sent = await ref.read(messageApiProvider).sendPrivate(
                PrivateMessageDTO(
                  tmpId: tmpId,
                  recvId: chat.targetId,
                  content: content,
                  type: MessageType.userCard,
                ),
              );
          await _db.messageDao.updateByTmpId(
            tmpId,
            id: sent.id,
            status: sent.status,
            content: sent.content,
          );
          await _db.chatDao.bumpLastMsgId(ChatType.private, chat.targetId, sent.id);
        } else if (chat.type == ChatType.group) {
          final pending = GroupMessage(
            tmpId: tmpId,
            groupId: chat.targetId,
            sendId: _selfId,
            content: content,
            type: MessageType.userCard,
            status: MessageStatus.sending,
            sendTime: now,
          );
          await insertGroup(pending, incrementUnread: false);
          final sent = await ref.read(messageApiProvider).sendGroup(
                GroupMessageDTO(
                  tmpId: tmpId,
                  groupId: chat.targetId,
                  content: content,
                  type: MessageType.userCard,
                ),
              );
          await _db.messageDao.updateByTmpId(
            tmpId,
            id: sent.id,
            status: sent.status,
            content: sent.content,
          );
          await _db.chatDao.bumpLastMsgId(ChatType.group, chat.targetId, sent.id);
        }
        ok++;
      } catch (e) {
        lastErr = asApiException(e).message;
        await _db.messageDao.updateByTmpId(
          tmpId,
          status: MessageStatus.failed,
        );
      }
    }
    if (ok == 0) return lastErr ?? '发送失败';
    return null;
  }

  /// 发送群名片到指定会话（对齐 uniapp group-info onSendCard）。
  Future<String?> sendGroupCard({
    required String chatType,
    required int targetId,
    required int groupId,
    required String groupName,
    String? headImage,
  }) async {
    final content = jsonEncode({
      'groupId': groupId,
      'groupName': groupName,
      'headImage': headImage,
    });
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;

    if (chatType == ChatType.private) {
      final pending = PrivateMessage(
        tmpId: tmpId,
        sendId: _selfId,
        recvId: targetId,
        content: content,
        type: MessageType.groupCard,
        status: MessageStatus.sending,
        sendTime: now,
      );
      await insertPrivate(pending, incrementUnread: false);
      try {
        final sent = await ref.read(messageApiProvider).sendPrivate(
              PrivateMessageDTO(
                tmpId: tmpId,
                recvId: targetId,
                content: content,
                type: MessageType.groupCard,
              ),
            );
        await _db.messageDao.updateByTmpId(
          tmpId,
          id: sent.id,
          status: sent.status,
          content: sent.content,
        );
        await _db.chatDao.bumpLastMsgId(ChatType.private, targetId, sent.id);
        return null;
      } catch (e, st) {
        final api = asApiException(e);
        log.w('[Chat] sendGroupCard private failed: ${api.message}\n$st');
        await _db.messageDao.updateByTmpId(
          tmpId,
          status: MessageStatus.failed,
        );
        return api.message;
      }
    }

    if (chatType == ChatType.group) {
      final pending = GroupMessage(
        tmpId: tmpId,
        groupId: targetId,
        sendId: _selfId,
        content: content,
        type: MessageType.groupCard,
        status: MessageStatus.sending,
        sendTime: now,
      );
      await insertGroup(pending, incrementUnread: false);
      try {
        final sent = await ref.read(messageApiProvider).sendGroup(
              GroupMessageDTO(
                tmpId: tmpId,
                groupId: targetId,
                content: content,
                type: MessageType.groupCard,
              ),
            );
        await _db.messageDao.updateByTmpId(
          tmpId,
          id: sent.id,
          status: sent.status,
          content: sent.content,
        );
        await _db.chatDao.bumpLastMsgId(ChatType.group, targetId, sent.id);
        return null;
      } catch (e, st) {
        final api = asApiException(e);
        log.w('[Chat] sendGroupCard group failed: ${api.message}\n$st');
        await _db.messageDao.updateByTmpId(
          tmpId,
          status: MessageStatus.failed,
        );
        return api.message;
      }
    }

    return '不支持的会话类型';
  }

  Future<void> resendGroup(Message msg) async {
    final tmpId = msg.tmpId;
    if (tmpId == null || msg.content == null || msg.groupId == null) return;
    await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.sending);
    try {
      final sent = await ref.read(messageApiProvider).sendGroup(
            GroupMessageDTO(
              tmpId: tmpId,
              groupId: msg.groupId!,
              content: msg.content!,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content,
      );
    } catch (_) {
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
    }
  }

  /// 发送私聊文字。成功返回 null，失败返回可读错误信息。
  Future<String?> sendPrivateText({
    required int friendId,
    required String content,
    int? quoteMessageId,
    QuoteMessage? quoteMessage,
  }) async {
    final text = content.trim();
    if (text.isEmpty) return null;

    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pending = PrivateMessage(
      tmpId: tmpId,
      sendId: _selfId,
      recvId: friendId,
      content: text,
      type: MessageType.text,
      status: MessageStatus.sending,
      sendTime: now,
      quoteMessage: quoteMessage,
    );
    await insertPrivate(pending, incrementUnread: false);

    return _apiSendQueue.run(() async {
      final line = ref.read(lineProvider);
      log.i(
        '[Chat] sendPrivate start tmpId=$tmpId recvId=$friendId '
        'line=${line.id} host=${line.host}',
      );

      try {
        final sent = await _sendWithLineRetry(
          () => ref.read(messageApiProvider).sendPrivate(
                PrivateMessageDTO(
                  tmpId: tmpId,
                  recvId: friendId,
                  content: text,
                  type: MessageType.text,
                  quoteMessageId: quoteMessageId,
                ),
              ),
        );
        await _db.messageDao.updateByTmpId(
          tmpId,
          id: sent.id,
          status: sent.status,
          content: sent.content,
          quoteMessage: sent.quoteMessage,
        );
        await _db.chatDao.bumpLastMsgId(ChatType.private, friendId, sent.id);
        log.i('[Chat] sendPrivate ok id=${sent.id} status=${sent.status}');
        return null;
      } catch (e, st) {
        final api = asApiException(e);
        log.w(
          '[Chat] sendPrivate failed line=${line.id} host=${line.host} '
          'code=${api.code} msg=${api.message}\n$st',
        );
        await _db.messageDao.updateByTmpId(
          tmpId,
          status: MessageStatus.failed,
        );
        return api.message;
      }
    });
  }

  /// 发送私聊图片。选图→本地入库→上传→发 IMAGE 消息（对齐 uniapp onUploadImage*）。
  Future<String?> sendPrivateImage({
    required int friendId,
    required String localPath,
    int? width,
    int? height,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent = jsonEncode({
      'originUrl': localPath,
      'thumbUrl': localPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
    final pending = PrivateMessage(
      tmpId: tmpId,
      sendId: _selfId,
      recvId: friendId,
      content: pendingContent,
      type: MessageType.image,
      status: MessageStatus.sending,
      sendTime: now,
    );
    await insertPrivate(pending, incrementUnread: false);

    final line = ref.read(lineProvider);
    log.i(
      '[Chat] sendPrivateImage start tmpId=$tmpId recvId=$friendId '
      'line=${line.id} host=${line.host}',
    );

    final baseMap = Map<String, dynamic>.from(jsonDecode(pendingContent) as Map);
    if (width == null || height == null) {
      unawaited(_patchLocalImageDimensions(
        tmpId: tmpId,
        localPath: localPath,
        base: baseMap,
      ));
    }

    try {
      final uploaded =
          await ref.read(uploadServiceProvider).uploadChatImage(localPath);
      final uploadedMap = Map<String, dynamic>.from(uploaded.toJson());
      if (width != null && uploaded.width == 0) uploadedMap['width'] = width;
      if (height != null && uploaded.height == 0) {
        uploadedMap['height'] = height;
      }
      final contentJson = jsonEncode(uploadedMap);
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendPrivate(
            PrivateMessageDTO(
              tmpId: tmpId,
              recvId: friendId,
              content: contentJson,
              type: MessageType.image,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.private, friendId, sent.id);
      log.i('[Chat] sendPrivateImage ok id=${sent.id} status=${sent.status}');
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w(
        '[Chat] sendPrivateImage failed line=${line.id} host=${line.host} '
        'code=${api.code} msg=${api.message}\n$st',
      );
      await _db.messageDao.updateByTmpId(
        tmpId,
        status: MessageStatus.failed,
      );
      return api.message;
    }
  }

  /// 发送私聊视频。对齐 uniapp onUploadVideo*。
  Future<String?> sendPrivateVideo({
    required int friendId,
    required String localPath,
    int? width,
    int? height,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent = jsonEncode({
      'videoUrl': localPath,
      'coverUrl': '',
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
    final pending = PrivateMessage(
      tmpId: tmpId,
      sendId: _selfId,
      recvId: friendId,
      content: pendingContent,
      type: MessageType.video,
      status: MessageStatus.sending,
      sendTime: now,
    );
    await insertPrivate(pending, incrementUnread: false);

    final baseMap = Map<String, dynamic>.from(jsonDecode(pendingContent) as Map);
    if (width == null || height == null) {
      unawaited(_patchLocalVideoDimensions(
        tmpId: tmpId,
        localPath: localPath,
        base: baseMap,
      ));
    }

    try {
      final uploaded =
          await ref.read(uploadServiceProvider).uploadChatVideo(localPath);
      final uploadedMap = Map<String, dynamic>.from(uploaded.toJson());
      if (width != null && (uploadedMap['width'] as int? ?? 0) == 0) {
        uploadedMap['width'] = width;
      }
      if (height != null && (uploadedMap['height'] as int? ?? 0) == 0) {
        uploadedMap['height'] = height;
      }
      final contentJson = jsonEncode(uploadedMap);
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendPrivate(
            PrivateMessageDTO(
              tmpId: tmpId,
              recvId: friendId,
              content: contentJson,
              type: MessageType.video,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.private, friendId, sent.id);
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w('[Chat] sendPrivateVideo failed: ${api.message}\n$st');
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
      return api.message;
    }
  }

  /// 发送群聊视频。
  Future<String?> sendGroupVideo({
    required int groupId,
    required String localPath,
    int? width,
    int? height,
    bool receipt = false,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent = jsonEncode({
      'videoUrl': localPath,
      'coverUrl': '',
      if (width != null) 'width': width,
      if (height != null) 'height': height,
    });
    final pending = GroupMessage(
      tmpId: tmpId,
      groupId: groupId,
      sendId: _selfId,
      content: pendingContent,
      type: MessageType.video,
      status: MessageStatus.sending,
      sendTime: now,
      receipt: receipt,
    );
    await insertGroup(pending, incrementUnread: false);

    final baseMap = Map<String, dynamic>.from(jsonDecode(pendingContent) as Map);
    if (width == null || height == null) {
      unawaited(_patchLocalVideoDimensions(
        tmpId: tmpId,
        localPath: localPath,
        base: baseMap,
      ));
    }

    try {
      final uploaded =
          await ref.read(uploadServiceProvider).uploadChatVideo(localPath);
      final uploadedMap = Map<String, dynamic>.from(uploaded.toJson());
      if (width != null && (uploadedMap['width'] as int? ?? 0) == 0) {
        uploadedMap['width'] = width;
      }
      if (height != null && (uploadedMap['height'] as int? ?? 0) == 0) {
        uploadedMap['height'] = height;
      }
      final contentJson = jsonEncode(uploadedMap);
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendGroup(
            GroupMessageDTO(
              tmpId: tmpId,
              groupId: groupId,
              content: contentJson,
              type: MessageType.video,
              receipt: receipt,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.group, groupId, sent.id);
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w('[Chat] sendGroupVideo failed: ${api.message}\n$st');
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
      return api.message;
    }
  }

  /// 发送私聊文件。对齐 uniapp onUploadFile*。
  Future<String?> sendPrivateFile({
    required int friendId,
    required String localPath,
    required String name,
    required int size,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent = jsonEncode({
      'name': name,
      'size': size,
      'url': localPath,
    });
    final pending = PrivateMessage(
      tmpId: tmpId,
      sendId: _selfId,
      recvId: friendId,
      content: pendingContent,
      type: MessageType.file,
      status: MessageStatus.sending,
      sendTime: now,
    );
    await insertPrivate(pending, incrementUnread: false);

    try {
      final url = await ref.read(uploadServiceProvider).uploadChatFile(localPath);
      final contentJson = jsonEncode({'name': name, 'size': size, 'url': url});
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendPrivate(
            PrivateMessageDTO(
              tmpId: tmpId,
              recvId: friendId,
              content: contentJson,
              type: MessageType.file,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.private, friendId, sent.id);
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w('[Chat] sendPrivateFile failed: ${api.message}\n$st');
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
      return api.message;
    }
  }

  /// 发送群聊文件。
  Future<String?> sendGroupFile({
    required int groupId,
    required String localPath,
    required String name,
    required int size,
    bool receipt = false,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent = jsonEncode({
      'name': name,
      'size': size,
      'url': localPath,
    });
    final pending = GroupMessage(
      tmpId: tmpId,
      groupId: groupId,
      sendId: _selfId,
      content: pendingContent,
      type: MessageType.file,
      status: MessageStatus.sending,
      sendTime: now,
      receipt: receipt,
    );
    await insertGroup(pending, incrementUnread: false);

    try {
      final url = await ref.read(uploadServiceProvider).uploadChatFile(localPath);
      final contentJson = jsonEncode({'name': name, 'size': size, 'url': url});
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendGroup(
            GroupMessageDTO(
              tmpId: tmpId,
              groupId: groupId,
              content: contentJson,
              type: MessageType.file,
              receipt: receipt,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.group, groupId, sent.id);
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w('[Chat] sendGroupFile failed: ${api.message}\n$st');
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
      return api.message;
    }
  }

  /// 发送私聊语音。
  ///
  /// 先本地入库（本地路径，sending）再上传/发消息，松手后列表立即出现气泡，
  /// 避免等上传完成才显示（常见 300–800ms 空窗）。
  Future<String?> sendPrivateAudio({
    required int friendId,
    required String localPath,
    required int duration,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent =
        jsonEncode({'url': localPath, 'duration': duration});
    final pending = PrivateMessage(
      tmpId: tmpId,
      sendId: _selfId,
      recvId: friendId,
      content: pendingContent,
      type: MessageType.audio,
      status: MessageStatus.sending,
      sendTime: now,
    );
    await insertPrivate(pending, incrementUnread: false);

    try {
      final url =
          await ref.read(uploadServiceProvider).uploadChatFile(localPath);
      final contentJson = jsonEncode({'url': url, 'duration': duration});
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendPrivate(
            PrivateMessageDTO(
              tmpId: tmpId,
              recvId: friendId,
              content: contentJson,
              type: MessageType.audio,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.private, friendId, sent.id);
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w('[Chat] sendPrivateAudio failed: ${api.message}\n$st');
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
      return api.message;
    }
  }

  /// 发送群聊语音。先本地入库再上传，与 [sendPrivateAudio] 相同。
  Future<String?> sendGroupAudio({
    required int groupId,
    required String localPath,
    required int duration,
    bool receipt = false,
  }) async {
    final tmpId = MessageTmpId.next();
    final now = DateTime.now().millisecondsSinceEpoch;
    final pendingContent =
        jsonEncode({'url': localPath, 'duration': duration});
    final pending = GroupMessage(
      tmpId: tmpId,
      groupId: groupId,
      sendId: _selfId,
      content: pendingContent,
      type: MessageType.audio,
      status: MessageStatus.sending,
      sendTime: now,
      receipt: receipt,
    );
    await insertGroup(pending, incrementUnread: false);

    try {
      final url =
          await ref.read(uploadServiceProvider).uploadChatFile(localPath);
      final contentJson = jsonEncode({'url': url, 'duration': duration});
      await _db.messageDao.updateByTmpId(tmpId, content: contentJson);

      final sent = await ref.read(messageApiProvider).sendGroup(
            GroupMessageDTO(
              tmpId: tmpId,
              groupId: groupId,
              content: contentJson,
              type: MessageType.audio,
              receipt: receipt,
            ),
          );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content ?? contentJson,
      );
      await _db.chatDao.bumpLastMsgId(ChatType.group, groupId, sent.id);
      return null;
    } catch (e, st) {
      final api = asApiException(e);
      log.w('[Chat] sendGroupAudio failed: ${api.message}\n$st');
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
      return api.message;
    }
  }

  /// 删除本地消息（仅客户端）。对齐 chatStore.deleteMessage。
  Future<void> deleteMessage(Message msg) async {
    await _db.messageDao.deleteMessage(
      chatType: msg.chatType,
      chatTargetId: msg.chatTargetId,
      id: msg.id,
      tmpId: msg.tmpId,
    );
  }

  Future<void> updateGroupMessageReadedCount({
    required int groupId,
    required int messageId,
    required int readedCount,
    bool? receiptOk,
  }) =>
      _db.messageDao.updateReadedCount(
        chatType: ChatType.group,
        chatTargetId: groupId,
        messageId: messageId,
        readedCount: readedCount,
        receiptOk: receiptOk,
      );

  /// 设置群置顶消息。POST /group/setTopMessage。
  Future<String?> setGroupTopMessage(int groupId, int messageId) async {
    if (messageId <= 0) return '请等待该消息发送成功后操作';
    try {
      await ref.read(groupApiProvider).setTopMessage(groupId, messageId);
      await ref.read(groupStoreProvider.notifier).loadGroupDetail(groupId);
      return null;
    } catch (e) {
      return asApiException(e).message;
    }
  }

  /// 移除群置顶（群主/管理员）。
  Future<String?> removeGroupTopMessage(int groupId) async {
    try {
      await ref.read(groupApiProvider).removeTopMessage(groupId);
      await ref.read(groupStoreProvider.notifier).loadGroupDetail(groupId);
      return null;
    } catch (e) {
      return asApiException(e).message;
    }
  }

  /// 隐藏群置顶（普通成员）。
  Future<String?> hideGroupTopMessage(int groupId) async {
    try {
      await ref.read(groupApiProvider).hideTopMessage(groupId);
      await ref.read(groupStoreProvider.notifier).loadGroupDetail(groupId);
      return null;
    } catch (e) {
      return asApiException(e).message;
    }
  }

  /// 请求撤回消息。DELETE /message/*/recall/{id}。
  Future<String?> requestRecall(Message msg) async {
    if (msg.id == null) return '请等待该消息发送成功后操作';
    try {
      if (msg.chatType == ChatType.private) {
        final m = await ref.read(messageApiProvider).recallPrivate(msg.id!);
        await recallPrivate(m);
      } else if (msg.chatType == ChatType.group) {
        final m = await ref.read(messageApiProvider).recallGroup(msg.id!);
        await recallGroup(m);
      }
      return null;
    } catch (e) {
      return asApiException(e).message;
    }
  }

  Future<void> resendPrivate(Message msg) async {
    final tmpId = msg.tmpId;
    if (tmpId == null || msg.content == null) return;
    await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.sending);
    try {
      final sent = await _sendWithLineRetry(
        () => ref.read(messageApiProvider).sendPrivate(
              PrivateMessageDTO(
                tmpId: tmpId,
                recvId: msg.recvId ?? 0,
                content: msg.content!,
                type: msg.type,
              ),
            ),
      );
      await _db.messageDao.updateByTmpId(
        tmpId,
        id: sent.id,
        status: sent.status,
        content: sent.content,
      );
    } catch (_) {
      await _db.messageDao.updateByTmpId(tmpId, status: MessageStatus.failed);
    }
  }

  Future<void> setChatMessagesLoaded(
    String type,
    int targetId,
    bool loaded,
  ) => _db.chatDao.setMessagesLoaded(type, targetId, loaded);

  Future<void> markChatMessagesLoaded(String type, int targetId) =>
      setChatMessagesLoaded(type, targetId, true);

  Future<Chat?> findChat(String type, int targetId) =>
      _db.chatDao.findChat(type, targetId);

  Future<void> _patchLocalImageDimensions({
    required String tmpId,
    required String localPath,
    required Map<String, dynamic> base,
  }) async {
    final size = await ChatMediaMetaUtil.readImageSize(localPath);
    if (size.width == null || size.height == null) return;
    final next = Map<String, dynamic>.from(base)
      ..['width'] = size.width
      ..['height'] = size.height;
    await _db.messageDao.updateByTmpId(tmpId, content: jsonEncode(next));
  }

  Future<void> _patchLocalVideoDimensions({
    required String tmpId,
    required String localPath,
    required Map<String, dynamic> base,
  }) async {
    final size = await ChatMediaMetaUtil.readVideoSize(localPath);
    if (size.width == null || size.height == null) return;
    final next = Map<String, dynamic>.from(base)
      ..['width'] = size.width
      ..['height'] = size.height;
    await _db.messageDao.updateByTmpId(tmpId, content: jsonEncode(next));
  }

  Future<void> insertPrivate(PrivateMessage msg, {bool incrementUnread = true}) async {
    final selfSend = msg.sendId == _selfId;
    final friendId = selfSend ? msg.recvId : msg.sendId;
    final meta = _privateMeta(friendId);
    await openChat(
      type: ChatType.private,
      targetId: friendId,
      showName: meta.$1,
      headImage: meta.$2,
      companyName: meta.$3,
      isDnd: meta.$4,
      isTop: meta.$5,
    );
    final isNew =
        await _db.messageDao.insertPrivate(msg, selfSend: selfSend);
    if (!isNew) return;
    await _db.chatDao.updateLastPreview(
      type: ChatType.private,
      targetId: friendId,
      lastContent: _preview(msg.type, msg.content),
      lastSendTime: msg.sendTime,
      lastMsgType: msg.type,
    );
    await _db.chatDao.bumpLastMsgId(ChatType.private, friendId, msg.id);
    if (incrementUnread && !selfSend && msg.status != MessageStatus.readed) {
      await _db.chatDao.incrementUnread(ChatType.private, friendId);
    }
  }

  Future<void> insertGroup(GroupMessage msg, {bool incrementUnread = true}) async {
    final selfSend = msg.sendId == _selfId;
    final meta = _groupMeta(msg.groupId);
    await openChat(
      type: ChatType.group,
      targetId: msg.groupId,
      showName: meta.$1,
      headImage: meta.$2,
      isDnd: meta.$3,
      isTop: meta.$4,
    );
    final isNew = await _db.messageDao.insertGroup(msg, selfSend: selfSend);
    if (!isNew) return;
    await _db.chatDao.updateLastPreview(
      type: ChatType.group,
      targetId: msg.groupId,
      lastContent: _preview(msg.type, msg.content),
      lastSendTime: msg.sendTime,
      sendNickName: msg.sendNickName,
      lastMsgType: msg.type,
    );
    await _db.chatDao.bumpLastMsgId(ChatType.group, msg.groupId, msg.id);
    if (incrementUnread && !selfSend && msg.status != MessageStatus.readed) {
      await _db.chatDao.incrementUnread(ChatType.group, msg.groupId);
    }
    await _applyGroupAt(msg, selfSend);
  }

  Future<void> _applyGroupAt(GroupMessage msg, bool selfSend) async {
    if (selfSend ||
        msg.status == MessageStatus.readed ||
        msg.id == null ||
        msg.atUserIds.isEmpty) {
      return;
    }
    var atMe = false;
    var atAll = false;
    for (final uid in msg.atUserIds) {
      if (uid == _selfId) atMe = true;
      if (uid == -1) atAll = true;
    }
    if (!atMe && !atAll) return;
    await _db.chatDao.markAt(
      type: ChatType.group,
      targetId: msg.groupId,
      messageId: msg.id!,
      atMe: atMe,
      atAll: atAll,
    );
  }

  Future<void> insertSystem(SystemMessage msg) async {
    await openChat(type: ChatType.system, targetId: 0);
    final isNew = await _db.messageDao.insertSystem(msg);
    if (!isNew) return;
    await _db.chatDao.updateLastPreview(
      type: ChatType.system,
      targetId: 0,
      lastContent: msg.title ?? msg.intro ?? msg.content,
      lastSendTime: msg.sendTime,
      lastMsgType: msg.type,
    );
    await _db.chatDao.bumpLastMsgId(ChatType.system, 0, msg.id);
  }

  Future<void> recallPrivate(PrivateMessage msg) async {
    final selfSend = msg.sendId == _selfId;
    final friendId = selfSend ? msg.recvId : msg.sendId;
    final recalledId = int.tryParse(msg.content ?? '') ?? 0;
    if (recalledId <= 0) return;
    final name = selfSend ? '你' : '对方';
    final tip = '$name撤回了一条消息';
    await _db.messageDao.recallMessage(
      chatType: ChatType.private,
      chatTargetId: friendId,
      recalledId: recalledId,
      tipContent: tip,
      sendTime: msg.sendTime,
    );
    await _db.chatDao.updateLastPreview(
      type: ChatType.private,
      targetId: friendId,
      lastContent: tip,
      lastSendTime: msg.sendTime,
      lastMsgType: MessageType.tipText,
    );
  }

  Future<void> recallGroup(GroupMessage msg) async {
    final selfSend = msg.sendId == _selfId;
    final recalledId = int.tryParse(msg.content ?? '') ?? 0;
    if (recalledId <= 0) return;
    final name = selfSend ? '你' : (msg.sendNickName ?? '成员');
    final tip = '$name撤回了一条消息';
    await _db.messageDao.recallMessage(
      chatType: ChatType.group,
      chatTargetId: msg.groupId,
      recalledId: recalledId,
      tipContent: tip,
      sendTime: msg.sendTime,
    );
    await _db.chatDao.updateLastPreview(
      type: ChatType.group,
      targetId: msg.groupId,
      lastContent: tip,
      lastSendTime: msg.sendTime,
      lastMsgType: MessageType.tipText,
    );
  }

  String? _preview(int type, String? content) {
    if (content == null) return null;
    if (type == MessageType.text || type == MessageType.tipText) {
      return StringUtil.ellipsis(content, 50);
    }
    if (type == MessageType.image) return '[图片]';
    if (type == MessageType.video) return '[视频]';
    if (type == MessageType.audio) return '[语音]';
    if (type == MessageType.actRtVoice) return '[语音通话]';
    if (type == MessageType.actRtVideo) return '[视频通话]';
    if (type == MessageType.file) return '[文件]';
    if (type == MessageType.userCard) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return '[个人名片] ${map['nickName'] ?? ''}';
      } catch (_) {
        return '[个人名片]';
      }
    }
    if (type == MessageType.groupCard) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return '[群名片] ${map['groupName'] ?? ''}';
      } catch (_) {
        return '[群名片]';
      }
    }
    if (type == MessageType.contractCard) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return '[合同卡片] ${map['title'] ?? ''}';
      } catch (_) {
        return '[合同卡片]';
      }
    }
    if (type == MessageType.loanCard) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return '[借款卡片] ${map['title'] ?? ''}';
      } catch (_) {
        return '[借款卡片]';
      }
    }
    if (type == MessageType.productCard) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return '[产品卡片] ${map['productName'] ?? map['title'] ?? ''}';
      } catch (_) {
        return '[产品卡片]';
      }
    }
    if (type == MessageType.systemMessage) {
      try {
        final map = jsonDecode(content) as Map<String, dynamic>;
        return map['title'] as String? ?? '[系统通知]';
      } catch (_) {
        return content;
      }
    }
    return '[消息]';
  }

  /// (showName, headImage, companyName, isDnd, isTop)
  (String?, String?, String?, bool, bool) _privateMeta(int friendId) {
    final f = _findFriend(friendId);
    if (f == null) return (null, null, null, false, false);
    return (
      f.showNickName,
      f.headImage,
      f.companyName,
      f.isDnd,
      f.isTop,
    );
  }

  (String?, String?, bool, bool) _groupMeta(int groupId) {
    final g = _findGroup(groupId);
    if (g == null) return (null, null, false, false);
    return (
      g.showGroupName ?? g.name,
      g.headImageThumb ?? g.headImage,
      g.isDnd,
      g.isTop,
    );
  }
}

final chatStoreProvider = Provider<ChatStore>((ref) => ChatStore(ref));

/// 会话列表 Stream（drift watch）。
final chatListStreamProvider = StreamProvider<List<Chat>>((ref) {
  return ref.watch(chatStoreProvider).watchChatList();
});

/// 会话列表虚拟窗口（按 limit 从 DB 取前 N 条）。
final chatListWindowProvider = StreamProvider.family<List<Chat>, int>((
  ref,
  limit,
) {
  return ref.watch(chatStoreProvider).watchChatListWindow(limit);
});

/// 本地会话总数（滚动分页扩窗时用，避免 watch 全表）。
final chatCountStreamProvider = StreamProvider<int>((ref) {
  return ref.watch(chatStoreProvider).watchChatCount();
});

class ChatListSearchQuery {
  const ChatListSearchQuery({
    required this.keyword,
    required this.limit,
  });

  final String keyword;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is ChatListSearchQuery &&
      other.keyword == keyword &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(keyword, limit);
}

final chatListSearchProvider =
    StreamProvider.family<List<Chat>, ChatListSearchQuery>((ref, query) {
  return ref
      .watch(chatStoreProvider)
      .watchChatSearch(query.keyword, limit: query.limit);
});

final chatBadgeUnreadCountProvider = StreamProvider<int>((ref) {
  return ref.watch(chatStoreProvider).watchChatBadgeUnreadCount();
});
