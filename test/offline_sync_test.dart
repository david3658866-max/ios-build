import 'package:drift/native.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';



import 'package:vortek/core/di/app_providers.dart';

import 'package:vortek/core/enums/chat_type.dart';

import 'package:vortek/core/enums/message_status.dart';

import 'package:vortek/core/enums/message_type.dart';

import 'package:vortek/core/storage/app_database.dart';

import 'package:vortek/models/private_message.dart';

import 'package:vortek/models/user.dart';

import 'package:vortek/services/offline_sync.dart';

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

      ],

    );

  });



  tearDown(() {

    container.dispose();

    db.close();

  });



  test('messagesLoaded=true 且本地有消息时 pullChatOffline 跳过', () async {

    final store = container.read(chatStoreProvider);

    await store.openChat(type: ChatType.private, targetId: 2, showName: '好友');

    await store.insertPrivate(

      PrivateMessage(

        id: 10,

        sendId: 1,

        recvId: 2,

        content: 'hi',

        type: MessageType.text,

        status: MessageStatus.delivered,

        sendTime: 1,

      ),

      incrementUnread: false,

    );

    await store.markChatMessagesLoaded(ChatType.private, 2);



    final before =

        await db.messageDao.watchMessages(ChatType.private, 2).first;



    await container.read(offlineSyncProvider).pullChatOffline(

          chatType: ChatType.private,

          targetId: 2,

        );



    final after =

        await db.messageDao.watchMessages(ChatType.private, 2).first;

    expect(after.length, before.length);

    expect(after.length, 1);

  });



  test('messagesLoaded=true 但本地无消息时重置游标', () async {

    final store = container.read(chatStoreProvider);

    await store.openChat(type: ChatType.private, targetId: 2, showName: '好友');

    await store.markChatMessagesLoaded(ChatType.private, 2);



    await container.read(offlineSyncProvider).pullChatOffline(

          chatType: ChatType.private,

          targetId: 2,

        );



    final chat = await store.findChat(ChatType.private, 2);

    expect(chat?.messagesLoaded, isTrue);

    expect(chat?.lastMsgId, 0);

  });

}



class _FakeUserStore extends UserStore {

  _FakeUserStore(this._user);



  final User _user;



  @override

  User? build() => _user;

}


