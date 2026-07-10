import 'package:drift/drift.dart';

/// 群成员表。对应后端 GroupMemberVO，复合主键 (groupId, userId)。
/// version 用于增量同步。
class GroupMembers extends Table {
  IntColumn get groupId => integer()();
  IntColumn get userId => integer()();
  TextColumn get showNickName => text().nullable()();
  TextColumn get remarkNickName => text().nullable()();
  TextColumn get headImage => text().nullable()();
  TextColumn get companyName => text().nullable()();
  BoolColumn get isManager => boolean().withDefault(const Constant(false))();
  BoolColumn get isMuted => boolean().withDefault(const Constant(false))();
  BoolColumn get quit => boolean().withDefault(const Constant(false))();
  BoolColumn get online => boolean().withDefault(const Constant(false))();
  TextColumn get showGroupName => text().nullable()();
  TextColumn get remarkGroupName => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {groupId, userId};
}
