import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../utils/app_logger.dart';

/// 明文 SQLite → 加密库（SQLite3MultipleCiphers）的一次性迁移。
///
/// 采用 drift 官方推荐方式：`VACUUM INTO` 复制明文库到临时文件，再 `PRAGMA rekey`
/// 就地加密该临时文件，最后原子替换为正式加密库并删除明文库。
///
/// 策略：
/// - 已有加密库 → 跳过（迁移完成）。
/// - 无加密库且无明文库 → 全新安装，交给 drift 直接创建加密库。
/// - 无加密库但有明文库 → 迁移；失败则清理临时文件并把明文库改名 .migfail，
///   避免下次死循环与明文长期留存，由 drift 新建空加密库（历史消息可由服务端摘要重新拉回）。
class DbEncryptionMigrator {
  const DbEncryptionMigrator._();

  static Future<void> migrateIfNeeded({
    required File plaintext,
    required File encrypted,
    required String key,
  }) async {
    if (await encrypted.exists()) {
      return;
    }
    if (!await plaintext.exists()) {
      return;
    }

    final tmp = File('${encrypted.path}.tmp');
    if (await tmp.exists()) {
      try {
        await tmp.delete();
      } catch (_) {}
    }

    try {
      _vacuumIntoEncrypted(
        plaintextPath: plaintext.path,
        encryptedTmpPath: tmp.path,
        key: key,
      );

      if (!await tmp.exists()) {
        throw StateError('迁移未生成临时加密库');
      }
      await tmp.rename(encrypted.path);
      try {
        await plaintext.delete();
      } catch (e) {
        log.w('[DbMigrate] 明文库删除失败（加密库已生成）: $e');
      }
      log.i('[DbMigrate] 明文库已迁移为加密库并删除明文');
    } catch (e, s) {
      log.e('[DbMigrate] 迁移失败，降级为新建空加密库: $e\n$s');
      try {
        if (await tmp.exists()) {
          await tmp.delete();
        }
      } catch (_) {}
      try {
        await plaintext.rename('${plaintext.path}.migfail');
      } catch (_) {}
    }
  }

  static void _vacuumIntoEncrypted({
    required String plaintextPath,
    required String encryptedTmpPath,
    required String key,
  }) {
    final plaintextDb = sqlite3.open(plaintextPath);
    try {
      plaintextDb
          .execute("VACUUM INTO '${_escape(encryptedTmpPath)}';");
    } finally {
      plaintextDb.close();
    }

    final encryptedDb = sqlite3.open(encryptedTmpPath);
    try {
      encryptedDb.execute("PRAGMA rekey = '${_escape(key)}';");
    } finally {
      encryptedDb.close();
    }
  }

  static String _escape(String source) => source.replaceAll("'", "''");
}