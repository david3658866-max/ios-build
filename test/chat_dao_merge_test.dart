import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/core/storage/tables/chats.dart';
import 'package:vortek/models/chat_session_summary.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  ChatSessionSummary _summary({
    String type = ChatType.private,
    int targetId = 1001,
    int maxMsgId = 0,
    String? showName,
  }) {
    return ChatSessionSummary(
      type: type,
      targetId: targetId,
      maxMsgId: maxMsgId,
      showName: showName,
      lastContent: 'preview',
      lastSendTime: 1_700_000_000_000,
    );
  }

  Future<void> _insertExisting({
    required String type,
    required int targetId,
    int lastMsgId = 0,
    String? showName,
    bool messagesLoaded = false,
  }) async {
    await db.into(db.chats).insert(
          ChatsCompanion.insert(
            type: type,
            targetId: targetId,
            showName: Value(showName),
            lastMsgId: Value(lastMsgId),
            messagesLoaded: Value(messagesLoaded),
          ),
        );
  }

  group('ChatDao.mergeFromSummary', () {
    test('a) 新会话插入：lastMsgId=0, messagesLoaded=false, showName 默认值', () async {
      await db.chatDao.mergeFromSummary(
        _summary(type: ChatType.private, targetId: 1, showName: null),
        localMaxMsgId: 0,
      );
      await db.chatDao.mergeFromSummary(
        _summary(type: ChatType.group, targetId: 2, showName: ''),
        localMaxMsgId: 0,
      );
      await db.chatDao.mergeFromSummary(
        _summary(type: ChatType.system, targetId: 0, showName: '  '),
        localMaxMsgId: 0,
      );

      final private = await db.chatDao.findChat(ChatType.private, 1);
      expect(private, isNotNull);
      expect(private!.lastMsgId, 0);
      expect(private.messagesLoaded, isFalse);
      expect(private.showName, '未知用户');

      final group = await db.chatDao.findChat(ChatType.group, 2);
      expect(group!.lastMsgId, 0);
      expect(group.messagesLoaded, isFalse);
      expect(group.showName, '未知群聊');

      final system = await db.chatDao.findChat(ChatType.system, 0);
      expect(system!.lastMsgId, 0);
      expect(system.messagesLoaded, isFalse);
      expect(system.showName, '系统通知');
    });

    test('b) 已有会话合并：localMaxMsgId=50, summary.maxMsgId=100 → messagesLoaded=false, lastMsgId 保持 50', () async {
      await _insertExisting(
        type: ChatType.private,
        targetId: 42,
        lastMsgId: 50,
        showName: '本地好友',
      );

      await db.chatDao.mergeFromSummary(
        _summary(targetId: 42, maxMsgId: 100, showName: '服务端昵称'),
        localMaxMsgId: 50,
      );

      final chat = await db.chatDao.findChat(ChatType.private, 42);
      expect(chat, isNotNull);
      expect(chat!.lastMsgId, 50, reason: 'lastMsgId 不应被 summary.maxMsgId 覆盖');
      expect(chat.messagesLoaded, isFalse);
    });

    test('c) summary.maxMsgId==localMaxMsgId 且 localMax>0 → messagesLoaded=true', () async {
      await _insertExisting(
        type: ChatType.private,
        targetId: 77,
        lastMsgId: 50,
        messagesLoaded: false,
      );

      await db.chatDao.mergeFromSummary(
        _summary(targetId: 77, maxMsgId: 50),
        localMaxMsgId: 50,
      );

      final chat = await db.chatDao.findChat(ChatType.private, 77);
      expect(chat, isNotNull);
      expect(chat!.lastMsgId, 50);
      expect(chat.messagesLoaded, isTrue);
    });

    test('d) 已有 showName 不被 summary 空值覆盖', () async {
      await _insertExisting(
        type: ChatType.private,
        targetId: 88,
        showName: '张三',
      );

      await db.chatDao.mergeFromSummary(
        _summary(targetId: 88, showName: null),
        localMaxMsgId: 0,
      );

      final afterNull = await db.chatDao.findChat(ChatType.private, 88);
      expect(afterNull!.showName, '张三');

      await db.chatDao.mergeFromSummary(
        _summary(targetId: 88, showName: ''),
        localMaxMsgId: 0,
      );

      final afterEmpty = await db.chatDao.findChat(ChatType.private, 88);
      expect(afterEmpty!.showName, '张三');

      await db.chatDao.mergeFromSummary(
        _summary(targetId: 88, showName: '  '),
        localMaxMsgId: 0,
      );

      final afterBlank = await db.chatDao.findChat(ChatType.private, 88);
      expect(afterBlank!.showName, '张三');
    });

    test('e) 未知用户可被 summary 有效 showName 覆盖', () async {
      await _insertExisting(
        type: ChatType.private,
        targetId: 99,
        showName: '未知用户',
      );

      await db.chatDao.mergeFromSummary(
        _summary(targetId: 99, showName: '王五'),
        localMaxMsgId: 0,
      );

      final chat = await db.chatDao.findChat(ChatType.private, 99);
      expect(chat!.showName, '王五');
    });
  });
}
