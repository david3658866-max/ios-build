import 'package:drift/drift.dart';

/// 好友表。对应后端 FriendVO。id 为服务端好友 id（非自增）。
class Friends extends Table {
  IntColumn get id => integer()();
  TextColumn get nickName => text().nullable()();
  TextColumn get showNickName => text().nullable()();
  TextColumn get remarkNickName => text().nullable()();
  TextColumn get headImage => text().nullable()();
  TextColumn get companyName => text().nullable()();
  BoolColumn get isDnd => boolean().withDefault(const Constant(false))();
  BoolColumn get isTop => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get online => boolean().withDefault(const Constant(false))();
  BoolColumn get onlineWeb => boolean().withDefault(const Constant(false))();
  BoolColumn get onlineApp => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
