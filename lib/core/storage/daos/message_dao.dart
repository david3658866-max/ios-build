import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/enums/message_status.dart';
import '../../../core/enums/message_type.dart';
import '../../../models/group_message.dart';
import '../../../models/private_message.dart';
import '../../../models/quote_message.dart';
import '../../../models/system_message.dart';
import '../app_database.dart';
import '../tables/messages.dart';

part 'message_dao.g.dart';

@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  /// 按 sendTime 升序返回最近 [limit] 条；[beforeSendTime] 用于上拉加载更早消息。
  Stream<List<Message>> watchMessages(
    String chatType,
    int chatTargetId, {
    int limit = 30,
    int? beforeSendTime,
  }) {
    final q = select(messages)
      ..where((t) {
        final base =
            t.chatType.equals(chatType) & t.chatTargetId.equals(chatTargetId);
        if (beforeSendTime == null) return base;
        return base & t.sendTime.isSmallerThanValue(beforeSendTime);
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.sendTime),
        // 同秒消息按服务端 id 继续排，避免列表顺序抖动。
        (t) => OrderingTerm(
              expression: coalesce([t.id, const Constant(-1)]),
              mode: OrderingMode.desc,
            ),
        // 本地临时消息兜底顺序，保证排序稳定。
        (t) => OrderingTerm.desc(t.rowId),
      ])
      ..limit(limit);
    return q.watch().map((rows) => rows.reversed.toList());
  }

  /// 一次性读取最近消息（进聊天页首屏预填，对齐 uniapp 内存 messages）。
  Future<List<Message>> listMessages(
    String chatType,
    int chatTargetId, {
    int limit = 30,
    int? beforeSendTime,
  }) async {
    final q = select(messages)
      ..where((t) {
        final base =
            t.chatType.equals(chatType) & t.chatTargetId.equals(chatTargetId);
        if (beforeSendTime == null) return base;
        return base & t.sendTime.isSmallerThanValue(beforeSendTime);
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.sendTime),
        (t) => OrderingTerm(
              expression: coalesce([t.id, const Constant(-1)]),
              mode: OrderingMode.desc,
            ),
        (t) => OrderingTerm.desc(t.rowId),
      ])
      ..limit(limit);
    final rows = await q.get();
    return rows.reversed.toList();
  }

  Future<bool> insertPrivate(PrivateMessage msg, {required bool selfSend}) async {
    final friendId = selfSend ? msg.recvId : msg.sendId;
    return _insert(
      MessagesCompanion(
        id: Value(msg.id),
        tmpId: Value(msg.tmpId),
        chatType: const Value('PRIVATE'),
        chatTargetId: Value(friendId),
        sendId: Value(msg.sendId),
        recvId: Value(msg.recvId),
        type: Value(msg.type),
        content: Value(msg.content),
        status: Value(msg.status),
        sendTime: Value(msg.sendTime),
        quoteMessage: Value(
          msg.quoteMessage == null ? null : jsonEncode(msg.quoteMessage!.toJson()),
        ),
        selfSend: Value(selfSend),
      ),
    );
  }

  Future<bool> insertGroup(GroupMessage msg, {required bool selfSend}) async {
    return _insert(
      MessagesCompanion(
        id: Value(msg.id),
        tmpId: Value(msg.tmpId),
        chatType: const Value('GROUP'),
        chatTargetId: Value(msg.groupId),
        sendId: Value(msg.sendId),
        groupId: Value(msg.groupId),
        type: Value(msg.type),
        content: Value(msg.content),
        status: Value(msg.status),
        sendTime: Value(msg.sendTime),
        sendNickName: Value(msg.sendNickName),
        atUserIds: Value(
          msg.atUserIds.isEmpty ? null : jsonEncode(msg.atUserIds),
        ),
        quoteMessage: Value(
          msg.quoteMessage == null ? null : jsonEncode(msg.quoteMessage!.toJson()),
        ),
        receipt: Value(msg.receipt),
        receiptOk: Value(msg.receiptOk),
        readedCount: Value(msg.readedCount),
        selfSend: Value(selfSend),
      ),
    );
  }

  Future<bool> insertSystem(SystemMessage msg) async {
    final payload = jsonEncode({
      'title': msg.title,
      'coverUrl': msg.coverUrl,
      'intro': msg.intro,
      if (msg.content != null && msg.content!.isNotEmpty) 'content': msg.content,
    });
    return _insert(
      MessagesCompanion(
        id: Value(msg.id),
        chatType: const Value('SYSTEM'),
        chatTargetId: const Value(0),
        type: Value(
          msg.type == 0 ? MessageType.systemMessage : msg.type,
        ),
        content: Value(payload),
        status: Value(msg.status),
        sendTime: Value(msg.sendTime),
        seqNo: Value(msg.seqNo),
        selfSend: const Value(false),
      ),
    );
  }

  Future<void> recallMessage({
    required String chatType,
    required int chatTargetId,
    required int recalledId,
    required String tipContent,
    int? sendTime,
  }) async {
    await (update(messages)
          ..where(
            (t) =>
                t.chatType.equals(chatType) &
                t.chatTargetId.equals(chatTargetId) &
                t.id.equals(recalledId),
          ))
        .write(MessagesCompanion(
          type: const Value(MessageType.tipText),
          content: Value(tipContent),
          status: const Value(MessageStatus.recall),
          sendTime: sendTime != null ? Value(sendTime) : const Value.absent(),
        ));
  }

  Future<void> markSelfReaded({
    required String chatType,
    required int chatTargetId,
    int? maxId,
  }) async {
    await (update(messages)
          ..where((t) {
            var cond = t.chatType.equals(chatType) &
                t.chatTargetId.equals(chatTargetId) &
                t.selfSend.equals(true) &
                t.status.isSmallerThanValue(MessageStatus.recall);
            if (maxId != null) {
              cond = cond & t.id.isSmallerOrEqualValue(maxId);
            }
            return cond;
          }))
        .write(const MessagesCompanion(status: Value(MessageStatus.readed)));
  }

  Future<void> updateReadedCount({
    required String chatType,
    required int chatTargetId,
    required int messageId,
    required int readedCount,
    bool? receiptOk,
  }) async {
    await (update(messages)
          ..where(
            (t) =>
                t.chatType.equals(chatType) &
                t.chatTargetId.equals(chatTargetId) &
                t.id.equals(messageId),
          ))
        .write(MessagesCompanion(
          readedCount: Value(readedCount),
          receiptOk: receiptOk == null
              ? const Value.absent()
              : Value(receiptOk),
        ));
  }

  Future<int> maxMessageId(String chatType, int chatTargetId) async {
    final query = selectOnly(messages)
      ..addColumns([messages.id.max()])
      ..where(
        messages.chatType.equals(chatType) &
            messages.chatTargetId.equals(chatTargetId) &
            messages.id.isNotNull(),
      );
    final row = await query.getSingleOrNull();
    return row?.read(messages.id.max()) ?? 0;
  }

  Future<void> updateContentById({
    required String chatType,
    required int chatTargetId,
    required int messageId,
    required String content,
  }) async {
    await (update(messages)
          ..where(
            (t) =>
                t.chatType.equals(chatType) &
                t.chatTargetId.equals(chatTargetId) &
                t.id.equals(messageId),
          ))
        .write(MessagesCompanion(content: Value(content)));
  }

  Future<void> updateByTmpId(
    String tmpId, {
    int? id,
    int? status,
    String? content,
    QuoteMessage? quoteMessage,
  }) async {
    await (update(messages)..where((t) => t.tmpId.equals(tmpId))).write(
      MessagesCompanion(
        id: id != null ? Value(id) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
        content: content != null ? Value(content) : const Value.absent(),
        quoteMessage: quoteMessage == null
            ? const Value.absent()
            : Value(jsonEncode(quoteMessage.toJson())),
      ),
    );
  }

  Future<void> clearAll() => delete(messages).go();

  Future<int> countMessages(String chatType, int chatTargetId) async {
    final query = selectOnly(messages)
      ..addColumns([countAll()])
      ..where(
        messages.chatType.equals(chatType) &
            messages.chatTargetId.equals(chatTargetId),
      );
    final row = await query.getSingleOrNull();
    return row?.read(countAll()) ?? 0;
  }

  Future<int> totalMessageCount() async {
    final query = selectOnly(messages)..addColumns([countAll()]);
    final row = await query.getSingleOrNull();
    return row?.read(countAll()) ?? 0;
  }

  Future<List<({String type, int targetId})>> listDistinctChats() async {
    final rows = await customSelect(
      'SELECT DISTINCT chat_type AS type, chat_target_id AS target_id FROM messages',
      readsFrom: {messages},
    ).get();
    return [
      for (final row in rows)
        (type: row.read<String>('type'), targetId: row.read<int>('target_id')),
    ];
  }

  /// 删除会话内最旧的 [deleteCount] 条消息（按 sendTime 升序）。
  Future<int> deleteOldestMessages({
    required String chatType,
    required int targetId,
    required int deleteCount,
  }) async {
    if (deleteCount <= 0) return 0;
    final oldest = await (select(messages)
          ..where(
            (t) =>
                t.chatType.equals(chatType) & t.chatTargetId.equals(targetId),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sendTime)])
          ..limit(deleteCount))
        .get();
    var deleted = 0;
    for (final row in oldest) {
      await (delete(messages)..where((t) => t.rowId.equals(row.rowId))).go();
      deleted++;
    }
    return deleted;
  }

  /// 冷启动修复：残留「发送中」标记为失败。对齐 chatStore.loadChat。
  Future<void> markSendingAsFailed() async {
    await (update(messages)
          ..where((t) => t.status.equals(MessageStatus.sending)))
        .write(const MessagesCompanion(status: Value(MessageStatus.failed)));
  }

  Future<void> deleteMessage({
    required String chatType,
    required int chatTargetId,
    int? id,
    String? tmpId,
  }) async {
    if (id == null && tmpId == null) return;
    await (delete(messages)..where((t) {
      var cond = t.chatType.equals(chatType) &
          t.chatTargetId.equals(chatTargetId);
      if (id != null) {
        return cond & t.id.equals(id);
      }
      return cond & t.tmpId.equals(tmpId!);
    })).go();
  }

  Future<bool> _insert(MessagesCompanion companion) async {
    if (companion.id.present && companion.id.value != null) {
      final existing = await (select(messages)
            ..where(
              (t) =>
                  t.chatType.equals(companion.chatType.value) &
                  t.chatTargetId.equals(companion.chatTargetId.value) &
                  t.id.equals(companion.id.value!),
            ))
          .getSingleOrNull();
      if (existing != null) {
        await (update(messages)..where((t) => t.rowId.equals(existing.rowId)))
            .write(companion);
        return false;
      }
    }
    if (companion.tmpId.present && companion.tmpId.value != null) {
      final existing = await (select(messages)
            ..where((t) => t.tmpId.equals(companion.tmpId.value!)))
          .getSingleOrNull();
      if (existing != null) {
        await (update(messages)..where((t) => t.rowId.equals(existing.rowId)))
            .write(companion);
        return false;
      }
    }
    await into(messages).insert(companion);
    return true;
  }
}
