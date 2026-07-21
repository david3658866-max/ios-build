import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/core/storage/daos/sync_cursor_dao.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('建表成功，SyncCursorDao 读写正常', () async {
    final dao = SyncCursorDao(db);

    expect(await dao.getCursor('privateMsgMaxId'), 0);

    await dao.setCursor('privateMsgMaxId', 1024);
    expect(await dao.getCursor('privateMsgMaxId'), 1024);

    await dao.setCursor('privateMsgMaxId', 2048);
    expect(await dao.getCursor('privateMsgMaxId'), 2048);
  });
}
