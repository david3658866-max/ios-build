import 'package:drift/drift.dart';

/// 消息表（替代 im-uniapp 的冷热分区方案，统一一张表 + 分页查询）。
///
/// 唯一键 (chat_type, chat_target_id, id) 用于 INSERT OR REPLACE 去重；
/// 发送中的消息 id 为空（SQLite 多个 NULL 视为不同，互不冲突）。
class Messages extends Table {
  IntColumn get rowId => integer().autoIncrement()();

  /// 服务端消息 id（发送中为空）。
  IntColumn get id => integer().nullable()();

  /// 本地临时 id。
  TextColumn get tmpId => text().nullable()();

  /// PRIVATE / GROUP / SYSTEM。
  TextColumn get chatType => text()();

  /// 会话目标 id（好友id/群id/0）。
  IntColumn get chatTargetId => integer()();

  IntColumn get sendId => integer().nullable()();
  IntColumn get recvId => integer().nullable()();
  IntColumn get groupId => integer().nullable()();

  /// 消息类型 0-211，见 MessageType。
  IntColumn get type => integer()();
  TextColumn get content => text().nullable()();

  /// 消息状态 -2..3，见 MessageStatus。
  IntColumn get status => integer()();
  IntColumn get sendTime => integer().nullable()();

  /// 群聊发送者昵称。
  TextColumn get sendNickName => text().nullable()();

  /// @ 的用户 id 列表（JSON: `List<int>`）。
  TextColumn get atUserIds => text().nullable()();

  /// 引用消息（JSON: QuoteMessage）。
  TextColumn get quoteMessage => text().nullable()();

  BoolColumn get receipt => boolean().withDefault(const Constant(false))();
  BoolColumn get receiptOk => boolean().withDefault(const Constant(false))();
  IntColumn get readedCount => integer().withDefault(const Constant(0))();
  BoolColumn get selfSend => boolean().withDefault(const Constant(false))();

  /// 系统消息序号。
  IntColumn get seqNo => integer().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {chatType, chatTargetId, id},
      ];
}
