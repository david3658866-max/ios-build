import 'package:drift/drift.dart';

import '../../../core/enums/chat_type.dart';
import '../../../models/chat_session_summary.dart';
import '../app_database.dart';
import '../tables/chats.dart';

part 'chat_dao.g.dart';

@DriftAccessor(tables: [Chats])
class ChatDao extends DatabaseAccessor<AppDatabase> with _$ChatDaoMixin {
  ChatDao(super.db);

  SimpleSelectStatement<$ChatsTable, Chat> _orderedChatQuery() {
    return select(chats)
      ..orderBy([
        (t) => OrderingTerm(expression: t.isTop, mode: OrderingMode.desc),
        (t) => OrderingTerm(
              expression: coalesce([t.lastSendTime, const Constant(0)]),
              mode: OrderingMode.desc,
            ),
        // 同时间戳下按主键稳定排序，避免列表抖动。
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);
  }

  Stream<List<Chat>> watchChatList() {
    return _orderedChatQuery().watch();
  }

  Stream<List<Chat>> watchChatListWindow({required int limit}) {
    final safeLimit = limit <= 0 ? 1 : limit;
    return (_orderedChatQuery()..limit(safeLimit)).watch();
  }

  Stream<int> watchChatCount() {
    final countExp = chats.id.count();
    final query = selectOnly(chats)..addColumns([countExp]);
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Stream<int> watchChatBadgeUnreadCount() {
    final unreadExp = chats.unreadCount.sum();
    final query = selectOnly(chats)
      ..addColumns([unreadExp])
      ..where(chats.isDnd.equals(false));
    return query.watchSingle().map((row) => row.read(unreadExp) ?? 0);
  }

  Stream<List<Chat>> watchChatSearch({
    required String keyword,
    required int limit,
  }) {
    final safeLimit = limit <= 0 ? 1 : limit;
    final safeKeyword = keyword.trim();
    final query = _orderedChatQuery()
      ..where(
        (t) =>
            t.showName.isNotNull() &
            t.showName.like('%$safeKeyword%'),
      )
      ..limit(safeLimit);
    return query.watch();
  }

  Future<Chat?> findChat(String type, int targetId) {
    return (select(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .getSingleOrNull();
  }

  /// 有未读的私聊会话，用于断线后补拉未送达消息。
  Future<List<Chat>> listPrivateChatsWithUnread() {
    return (select(chats)
          ..where(
            (t) =>
                t.type.equals(ChatType.private) &
                t.unreadCount.isBiggerThanValue(0),
          ))
        .get();
  }

  Future<void> upsertFromSummary(ChatSessionSummary s) async {
    await mergeFromSummary(s, localMaxMsgId: 0);
  }

  /// 合并服务端会话摘要。对齐 uniapp chatStore.updateChatSummary。
  Future<void> mergeFromSummary(
    ChatSessionSummary s, {
    required int localMaxMsgId,
  }) async {
    final existing = await findChat(s.type, s.targetId);
    if (existing == null) {
      await into(chats).insert(
        ChatsCompanion.insert(
          type: s.type,
          targetId: s.targetId,
          showName: Value(_resolveShowName(s)),
          headImage: Value(s.headImage),
          companyName: Value(s.companyName),
          lastContent: Value(s.lastContent ?? ''),
          lastSendTime: Value(s.lastSendTime),
          sendNickName: Value(s.sendNickName),
          unreadCount: Value(s.unreadCount),
          isDnd: Value(s.isDnd),
          isTop: Value(s.isTop),
          lastMsgId: const Value(0),
          messagesLoaded: const Value(false),
        ),
      );
      return;
    }

    final lastMsgId =
        localMaxMsgId > existing.lastMsgId ? localMaxMsgId : existing.lastMsgId;
    final bool messagesLoaded;
    // 有未读时即使本地 maxMsgId 已更高（中间空洞），也要允许进会话补拉。
    if (s.unreadCount > 0 && s.type == ChatType.private) {
      messagesLoaded = false;
    } else if (s.maxMsgId > lastMsgId) {
      messagesLoaded = false;
    } else if (s.maxMsgId == lastMsgId) {
      messagesLoaded = localMaxMsgId > 0;
    } else {
      messagesLoaded = existing.messagesLoaded;
    }

    final showName =
        _pickShowName(existing.showName, s.showName, s.type) ??
            _resolveShowName(s);
    final headImage = _pickString(existing.headImage, s.headImage);

    await (update(chats)..where((t) => t.id.equals(existing.id))).write(
      ChatsCompanion(
        showName: Value(showName),
        headImage: Value(headImage),
        companyName: Value(_pickString(existing.companyName, s.companyName)),
        lastContent:
            s.lastContent != null ? Value(s.lastContent) : const Value.absent(),
        lastSendTime:
            s.lastSendTime != null ? Value(s.lastSendTime) : const Value.absent(),
        sendNickName: s.sendNickName != null
            ? Value(s.sendNickName)
            : const Value.absent(),
        unreadCount: Value(s.unreadCount),
        isDnd: Value(s.isDnd),
        isTop: Value(s.isTop),
        lastMsgId: Value(lastMsgId),
        messagesLoaded: Value(messagesLoaded),
      ),
    );
  }

  String? _pickString(String? local, String? remote) {
    if (local != null && local.trim().isNotEmpty) return local;
    if (remote != null && remote.trim().isNotEmpty) return remote;
    return null;
  }

  /// 占位名视为空，允许摘要/好友资料覆盖（对齐 uniapp updateChatSummary）。
  String? _pickShowName(String? local, String? remote, String type) {
    if (!_isPlaceholderShowName(local, type) &&
        local != null &&
        local.trim().isNotEmpty) {
      return local;
    }
    if (remote != null && remote.trim().isNotEmpty) return remote.trim();
    return null;
  }

  bool _isPlaceholderShowName(String? name, String type) {
    if (name == null || name.trim().isEmpty) return true;
    return switch (type) {
      ChatType.private => name == '未知用户',
      ChatType.group => name == '未知群聊',
      _ => false,
    };
  }

  String _resolveShowName(ChatSessionSummary s) {
    if (s.showName != null && s.showName!.trim().isNotEmpty) {
      return s.showName!.trim();
    }
    return switch (s.type) {
      ChatType.private => '未知用户',
      ChatType.group => '未知群聊',
      _ => '系统通知',
    };
  }

  Future<void> openChat({
    required String type,
    required int targetId,
    String? showName,
    String? headImage,
    String? companyName,
    bool isDnd = false,
    bool isTop = false,
  }) async {
    final existing = await findChat(type, targetId);
    if (existing != null) {
      final name = showName?.trim();
      final needName = name != null &&
          name.isNotEmpty &&
          (existing.showName == null ||
              existing.showName!.isEmpty ||
              existing.showName == '未知用户' ||
              existing.showName == '未知群聊');
      if (needName ||
          (headImage != null && headImage.isNotEmpty) ||
          companyName != null) {
        await updateContactProfile(
          type: type,
          targetId: targetId,
          showName: needName ? name : null,
          headImage: headImage,
          companyName: companyName,
          isDnd: isDnd,
          isTop: isTop,
        );
      }
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final resolvedName = (showName != null && showName.trim().isNotEmpty)
        ? showName.trim()
        : switch (type) {
            ChatType.private => '未知用户',
            ChatType.group => '未知群聊',
            _ => '系统通知',
          };
    await into(chats).insert(
      ChatsCompanion.insert(
        type: type,
        targetId: targetId,
        showName: Value(resolvedName),
        headImage: Value(headImage),
        companyName: Value(companyName),
        lastSendTime: Value(now),
        isDnd: Value(isDnd),
        isTop: Value(isTop),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> resetUnread(String type, int targetId) async {
    await (update(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .write(const ChatsCompanion(unreadCount: Value(0)));
  }

  Future<void> resetAt(String type, int targetId) async {
    await (update(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .write(const ChatsCompanion(
          atMe: Value(false),
          atAll: Value(false),
          lastAtMessageId: Value(-1),
        ));
  }

  Future<void> setTop(String type, int targetId, bool isTop) async {
    await (update(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .write(ChatsCompanion(isTop: Value(isTop)));
  }

  Future<void> setDnd(String type, int targetId, bool isDnd) async {
    await (update(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .write(ChatsCompanion(isDnd: Value(isDnd)));
  }

  Future<void> incrementUnread(String type, int targetId) async {
    final chat = await findChat(type, targetId);
    if (chat == null) return;
    await (update(chats)..where((t) => t.id.equals(chat.id))).write(
      ChatsCompanion(unreadCount: Value(chat.unreadCount + 1)),
    );
  }

  /// 群消息 @ 标记（对齐 uniapp insertMessage atUserIds 逻辑）。
  Future<void> markAt({
    required String type,
    required int targetId,
    required int messageId,
    required bool atMe,
    required bool atAll,
  }) async {
    if (!atMe && !atAll) return;
    final chat = await findChat(type, targetId);
    if (chat == null) return;
    await (update(chats)..where((t) => t.id.equals(chat.id))).write(
      ChatsCompanion(
        atMe: atMe ? const Value(true) : const Value.absent(),
        atAll: atAll ? const Value(true) : const Value.absent(),
        lastAtMessageId: Value(messageId),
      ),
    );
  }

  Future<void> setMessagesLoaded(String type, int targetId, bool loaded) async {
    await (update(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .write(ChatsCompanion(messagesLoaded: Value(loaded)));
  }

  /// 本地无消息时重置离线拉取游标（对齐 chat-box loadChatOfflineMessages）。
  Future<void> resetOfflinePullState(String type, int targetId) async {
    await (update(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .write(const ChatsCompanion(
          messagesLoaded: Value(false),
          lastMsgId: Value(0),
        ));
  }

  Future<void> bumpLastMsgId(String type, int targetId, int? msgId) async {
    if (msgId == null || msgId <= 0) return;
    final chat = await findChat(type, targetId);
    if (chat == null || msgId <= chat.lastMsgId) return;
    await (update(chats)..where((t) => t.id.equals(chat.id))).write(
      ChatsCompanion(lastMsgId: Value(msgId)),
    );
  }

  /// 用好友/群资料刷新会话展示名与头像（对齐 uniapp updateChatSummary）。
  Future<void> updateContactProfile({
    required String type,
    required int targetId,
    String? showName,
    String? headImage,
    String? companyName,
    bool? isDnd,
    bool? isTop,
  }) async {
    final chat = await findChat(type, targetId);
    if (chat == null) return;
    await (update(chats)..where((t) => t.id.equals(chat.id))).write(
      ChatsCompanion(
        showName: showName != null ? Value(showName) : const Value.absent(),
        headImage: headImage != null ? Value(headImage) : const Value.absent(),
        companyName:
            companyName != null ? Value(companyName) : const Value.absent(),
        isDnd: isDnd != null ? Value(isDnd) : const Value.absent(),
        isTop: isTop != null ? Value(isTop) : const Value.absent(),
      ),
    );
  }

  Future<void> clearAll() => delete(chats).go();

  Future<void> updateLastPreview({
    required String type,
    required int targetId,
    String? lastContent,
    int? lastSendTime,
    String? sendNickName,
    int? lastMsgType,
    int? lastMsgId,
  }) async {
    await (update(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .write(ChatsCompanion(
          lastContent: Value(lastContent),
          lastSendTime: Value(lastSendTime),
          sendNickName: Value(sendNickName),
          lastMsgType: lastMsgType != null
              ? Value(lastMsgType)
              : const Value.absent(),
          lastMsgId: lastMsgId != null ? Value(lastMsgId) : const Value.absent(),
        ));
  }

  /// 删除会话（对齐 uniapp chatStore.removeChat）。
  Future<void> deleteChat(String type, int targetId) async {
    await (delete(chats)
          ..where((t) => t.type.equals(type) & t.targetId.equals(targetId)))
        .go();
  }
}
