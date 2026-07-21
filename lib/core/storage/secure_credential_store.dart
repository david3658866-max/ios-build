import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform secure storage for tokens (Android Keystore / iOS Keychain).
/// In-memory cache keeps KvStore.getLoginInfo() synchronous.
class SecureCredentialStore {
  SecureCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessKey = 'im_access_token';
  static const String _refreshKey = 'im_refresh_token';

  final FlutterSecureStorage _storage;
  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get hasRefreshToken =>
      _refreshToken != null && _refreshToken!.trim().isNotEmpty;

  Future<void> init() async {
    try {
      _accessToken = await _storage.read(key: _accessKey);
      _refreshToken = await _storage.read(key: _refreshKey);
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    try {
      await _storage.write(key: _accessKey, value: accessToken);
      await _storage.write(key: _refreshKey, value: refreshToken);
    } catch (_) {
      // 单测无插件、或系统 Keystore 异常时，仍保留内存中的会话 token。
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }
}