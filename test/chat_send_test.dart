import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/enums/message_status.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/stores/chat_store.dart';
import 'package:vortek/stores/user_store.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        userStoreProvider.overrideWith(
          () => _FakeUserStore(const User(id: 1, userName: 'u1', nickName: '我')),
        ),
        lineProvider.overrideWith(_FixedLine.new),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  test('sendPrivateText 失败时标记 failed', () async {
    final store = container.read(chatStoreProvider);
    // 无 network → API 会失败
    await store.sendPrivateText(friendId: 2, content: 'hi');
    final msgs = await db.messageDao
        .watchMessages(ChatType.private, 2)
        .first;
    expect(msgs.length, 1);
    expect(msgs.first.content, 'hi');
    expect(msgs.first.status, MessageStatus.failed);
    expect(msgs.first.tmpId, isNotEmpty);
  });

  test('sendGroupText 本地先入库 sending', () async {
    final store = container.read(chatStoreProvider);
    await store.sendGroupText(groupId: 10, content: '群消息');
    final msgs = await db.messageDao
        .watchMessages(ChatType.group, 10)
        .first;
    expect(msgs.length, 1);
    expect(msgs.first.type, MessageType.text);
    expect(msgs.first.content, '群消息');
    expect(msgs.first.status, MessageStatus.failed);
  });
}

class _FakeUserStore extends UserStore {
  _FakeUserStore(this._user);

  final User _user;

  @override
  User? build() => _user;
}

class _FixedLine extends LineNotifier {
  @override
  LineConfig build() => kDefaultLine;
}
