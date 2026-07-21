import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/services/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late KvStore kv;
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vortek_prov');
    Hive.init(dir.path);
    kv = await KvStore.open();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        kvStoreProvider.overrideWithValue(kv),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('默认线路为主线路，devId 持久化稳定', () {
    expect(container.read(lineProvider).id, kDefaultLine.id);
    final id1 = kv.devId;
    final id2 = kv.devId;
    expect(id1, isNotEmpty);
    expect(id1, id2);
  });

  test('切换线路写回 KV 并更新 state', () async {
    await container.read(lineProvider.notifier).switchTo('line3');
    expect(container.read(lineProvider).id, 'line3');
    expect(kv.getLineId(), 'line3');
  });

  test('AuthController 初始 unknown，logout 后 unauthenticated 且清除登录态', () async {
    expect(container.read(authControllerProvider), AuthStatus.unknown);
    await container.read(authControllerProvider.notifier).logout();
    expect(container.read(authControllerProvider), AuthStatus.unauthenticated);
    expect(kv.getLoginInfo(), isNull);
  });

  test('handleSessionExpired 切到 unauthenticated（会话过期回登录）', () {
    container.read(authControllerProvider.notifier).handleSessionExpired();
    expect(container.read(authControllerProvider), AuthStatus.unauthenticated);
  });
}
