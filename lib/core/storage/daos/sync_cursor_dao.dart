import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_cursors.dart';

part 'sync_cursor_dao.g.dart';

/// 同步游标 DAO，替代 im-uniapp 散落的 maxId 变量。
/// 例：privateMsgMaxId / groupMsgMaxId / systemMsgMaxSeqNo。
@DriftAccessor(tables: [SyncCursors])
class SyncCursorDao extends DatabaseAccessor<AppDatabase>
    with _$SyncCursorDaoMixin {
  SyncCursorDao(super.db);

  /// 读游标，不存在返回 0。
  Future<int> getCursor(String key) async {
    final row = await (select(syncCursors)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value ?? 0;
  }

  /// 写游标（INSERT OR REPLACE）。
  Future<void> setCursor(String key, int value) async {
    await into(syncCursors).insertOnConflictUpdate(
      SyncCursorsCompanion.insert(key: key, value: Value(value)),
    );
  }
}
