import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vortek/core/storage/db_encryption_migrator.dart';
import 'package:vortek/core/storage/db_key_store.dart';

void main() {
  group('DbKeyStore.generateKey', () {
    test('生成的密钥非空且随机', () {
      final a = DbKeyStore.generateKey();
      final b = DbKeyStore.generateKey();
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(a == b, isFalse);
    });
  });

  group('SQLite3MultipleCiphers 可用性', () {
    test('PRAGMA cipher 非空（确认链接了加密版 sqlite3）', () {
      final db = sqlite3.openInMemory();
      try {
        final rows = db.select('PRAGMA cipher;');
        expect(rows, isNotEmpty,
            reason: '若为空说明未链接 sqlite3mc，请检查 pubspec hooks 配置');
      } finally {
        db.close();
      }
    });
  });

  group('DbEncryptionMigrator', () {
    late Directory tempDir;
    late File plaintext;
    late File encrypted;
    const key = 'unit-test-passphrase-xyz';

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('db_enc_test_');
      plaintext = File('${tempDir.path}/vortek_im.sqlite');
      encrypted = File('${tempDir.path}/vortek_im.enc.sqlite');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    void seedPlaintext() {
      final db = sqlite3.open(plaintext.path);
      db.execute('CREATE TABLE msg (id INTEGER PRIMARY KEY, body TEXT);');
      db.execute("INSERT INTO msg (id, body) VALUES (1, 'hello-history');");
      db.close();
    }

    test('明文库迁移为加密库：明文删除、密文存在、需 key 才可读', () async {
      seedPlaintext();
      expect(await plaintext.exists(), isTrue);

      await DbEncryptionMigrator.migrateIfNeeded(
        plaintext: plaintext,
        encrypted: encrypted,
        key: key,
      );

      expect(await encrypted.exists(), isTrue);
      expect(await plaintext.exists(), isFalse);

      // 无 key 打开应无法读取（已加密）。
      final noKeyDb = sqlite3.open(encrypted.path);
      expect(
        () => noKeyDb.select('SELECT body FROM msg;'),
        throwsA(isA<SqliteException>()),
      );
      noKeyDb.dispose();

      // 正确 key 打开可读回历史消息。
      final keyedDb = sqlite3.open(encrypted.path);
      keyedDb.execute("PRAGMA key = '$key';");
      final rows = keyedDb.select('SELECT body FROM msg;');
      expect(rows.single['body'], 'hello-history');
      keyedDb.dispose();
    });

    test('全新安装（无明文、无密文）：不生成密文，交由 drift 新建', () async {
      await DbEncryptionMigrator.migrateIfNeeded(
        plaintext: plaintext,
        encrypted: encrypted,
        key: key,
      );
      expect(await encrypted.exists(), isFalse);
    });

    test('已存在密文：幂等跳过', () async {
      seedPlaintext();
      await DbEncryptionMigrator.migrateIfNeeded(
        plaintext: plaintext,
        encrypted: encrypted,
        key: key,
      );
      final size1 = await encrypted.length();

      // 再造一个明文库，迁移应因密文已存在而跳过，不覆盖。
      seedPlaintext();
      await DbEncryptionMigrator.migrateIfNeeded(
        plaintext: plaintext,
        encrypted: encrypted,
        key: key,
      );
      expect(await encrypted.length(), size1);
      // 明文库因跳过而保留。
      expect(await plaintext.exists(), isTrue);
    });
  });
}