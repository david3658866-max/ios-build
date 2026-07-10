import 'package:drift/drift.dart';

/// 同步游标表，替代 im-uniapp 里散落的 maxId 变量。
/// key 例：privateMsgMaxId / groupMsgMaxId / systemMsgMaxSeqNo。
class SyncCursors extends Table {
  TextColumn get key => text()();
  IntColumn get value => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {key};
}
