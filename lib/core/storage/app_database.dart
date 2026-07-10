import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/chat_dao.dart';
import 'daos/message_dao.dart';
import 'daos/sync_cursor_dao.dart';
import 'tables/chats.dart';
import 'tables/friend_requests.dart';
import 'tables/friends.dart';
import 'tables/group_members.dart';
import 'tables/groups.dart';
import 'tables/messages.dart';
import 'tables/sync_cursors.dart';

part 'app_database.g.dart';

/// 全局 SQLite 数据库（drift）。重数据单一数据源：消息/会话/好友/群/成员/申请/游标。
///
/// 改表结构 = 改契约：必须由主 agent 统一改并升级 [schemaVersion]。
@DriftDatabase(
  tables: [
    Chats,
    Messages,
    Friends,
    Groups,
    GroupMembers,
    FriendRequests,
    SyncCursors,
  ],
  daos: [SyncCursorDao, ChatDao, MessageDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用：注入内存数据库。
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.addColumn(chats, chats.lastMsgType);
          }
          if (from < 3) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_chats_order_top_time_id '
              'ON chats (is_top DESC, last_send_time DESC, id DESC)',
            );
          }
          if (from < 4) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_messages_chat_time_id_row '
              'ON messages (chat_type, chat_target_id, send_time DESC, id DESC, row_id DESC)',
            );
          }
        },
        beforeOpen: (details) async {
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_chats_order_top_time_id '
            'ON chats (is_top DESC, last_send_time DESC, id DESC)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_messages_chat_time_id_row '
            'ON messages (chat_type, chat_target_id, send_time DESC, id DESC, row_id DESC)',
          );
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'vortek_im.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
