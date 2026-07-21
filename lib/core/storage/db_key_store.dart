import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 本地加密库（SQLite3MultipleCiphers）密钥。存平台安全存储（Keystore/Keychain）。
///
/// 与 Token 生命周期分离：登出/切号不清此密钥，否则会导致本地加密库无法再打开。
/// 仅卸载 App 或显式重置本地数据时才丢失。
class DbKeyStore {
  DbKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _dbKeyName = 'im_db_passphrase';

  final FlutterSecureStorage _storage;

  /// 读取已有密钥；不存在则生成 32 字节随机密钥（base64）并持久化。
  Future<String> getOrCreateKey() async {
    final existing = await _readKey();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final key = generateKey();
    await _storage.write(key: _dbKeyName, value: key);
    return key;
  }

  Future<String?> _readKey() async {
    try {
      return await _storage.read(key: _dbKeyName);
    } catch (_) {
      return null;
    }
  }

  /// 生成 32 字节随机密钥并 base64 编码，作为 `PRAGMA key` 的口令。
  static String generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// 仅在“重置本地数据/密钥损坏重建”时调用。日常登出不要调用。
  Future<void> resetKey() async {
    try {
      await _storage.delete(key: _dbKeyName);
    } catch (_) {}
  }
}
