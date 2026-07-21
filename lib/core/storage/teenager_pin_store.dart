import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 青少年模式 PIN：仅存加盐哈希到安全存储（Keystore / Keychain）。
class TeenagerPinStore {
  TeenagerPinStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String secureKey(int userId) => 'im_teenager_pin_$userId';

  static String newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String hashPin(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt:$pin')).toString();
  }

  Future<void> savePin(int userId, String pin) async {
    final salt = newSalt();
    final payload = jsonEncode({
      'v': 1,
      'salt': salt,
      'hash': hashPin(pin, salt),
    });
    await _storage.write(key: secureKey(userId), value: payload);
  }

  Future<bool> verifyPin(int userId, String pin) async {
    final raw = await _storage.read(key: secureKey(userId));
    if (raw == null || raw.isEmpty) return false;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final salt = map['salt'] as String? ?? '';
      final hash = map['hash'] as String? ?? '';
      if (salt.isEmpty || hash.isEmpty) return false;
      return hashPin(pin, salt) == hash;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasPin(int userId) async {
    final raw = await _storage.read(key: secureKey(userId));
    return raw != null && raw.isNotEmpty;
  }

  Future<void> clearPin(int userId) async {
    try {
      await _storage.delete(key: secureKey(userId));
    } catch (_) {}
  }
}