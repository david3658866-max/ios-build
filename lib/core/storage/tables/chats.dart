import 'package:drift/drift.dart';

/// 会话表。对应 im-uniapp chatStore 的 chats 数组 + ChatSessionSummaryVO。
/// 列名由 drift 自动转 snake_case（chatType→chat_type）。
class Chats extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// PRIVATE / GROUP / SYSTEM。
  TextColumn get type => text()();

  /// 好友id / 群id / 0(系统)。
  IntColumn get targetId => integer()();

  TextColumn get showName => text().nullable()();
  TextColumn get headImage => text().nullable()();
  TextColumn get companyName => text().nullable()();
  TextColumn get lastContent => text().nullable()();
  IntColumn get lastSendTime => integer().nullable()();
  TextColumn get sendNickName => text().nullable()();

  /// 末条消息类型（对齐 uniapp chat-item isShowSendName 用 messages[last].type）。
  IntColumn get lastMsgType => integer().nullable()();

  IntColumn get unreadCount => integer().withDefault(const Constant(0))();
  BoolColumn get atMe => boolean().withDefault(const Constant(false))();
  BoolColumn get atAll => boolean().withDefault(const Constant(false))();
  IntColumn get lastAtMessageId =>
      integer().withDefault(const Constant(-1))();
  BoolColumn get isDnd => boolean().withDefault(const Constant(false))();
  BoolColumn get isTop => boolean().withDefault(const Constant(false))();

  /// 本地已拉取的最大消息 id。
  IntColumn get lastMsgId => integer().withDefault(const Constant(0))();

  /// 是否已加载过历史消息。
  BoolColumn get messagesLoaded =>
      boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {type, targetId},
      ];
}
