import 'package:drift/drift.dart';

/// 群表。对应后端 GroupVO。id 为服务端群 id（非自增）。
/// topMessage 以 JSON 字符串存（GroupMessageVO）。
class Groups extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().nullable()();
  IntColumn get ownerId => integer().nullable()();
  TextColumn get headImage => text().nullable()();
  TextColumn get headImageThumb => text().nullable()();
  TextColumn get notice => text().nullable()();
  TextColumn get remarkNickName => text().nullable()();
  TextColumn get showNickName => text().nullable()();
  TextColumn get showGroupName => text().nullable()();
  TextColumn get remarkGroupName => text().nullable()();

  BoolColumn get isAllMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get isAllowInvite =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isAllowShareCard =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get dissolve => boolean().withDefault(const Constant(false))();
  BoolColumn get quit => boolean().withDefault(const Constant(false))();
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get isBanned => boolean().withDefault(const Constant(false))();
  TextColumn get reason => text().nullable()();
  BoolColumn get isDnd => boolean().withDefault(const Constant(false))();
  BoolColumn get isTop => boolean().withDefault(const Constant(false))();

  /// 群置顶消息（JSON: GroupMessageVO）。
  TextColumn get topMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
