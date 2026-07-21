import 'dart:convert';

import 'package:hive/hive.dart';

import '../config/app_constants.dart';
import '../line/line_config.dart';
import '../../models/login_info.dart';
import 'secure_credential_store.dart';

/// 轻量键值存储封装（Hive）。
///
/// Token 存 [SecureCredentialStore]；Hive 仅保留会话元数据。
/// 消息、会话、好友、群等重数据走 drift（见 app_database.dart）。
class KvStore {
  KvStore(this._box, this._secure);

  static const String boxName = 'app_kv';

  final Box _box;
  final SecureCredentialStore _secure;

  SecureCredentialStore get secureCredentials => _secure;

  /// 打开 Hive box + 安全存储，并完成旧凭证迁移。
  static Future<KvStore> open() async {
    Box box;
    try {
      box = await Hive.openBox(boxName).timeout(const Duration(seconds: 5));
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      box = await Hive.openBox(boxName).timeout(const Duration(seconds: 8));
    }
    final secure = SecureCredentialStore();
    await secure.init();
    final store = KvStore(box, secure);
    await store.migrateLegacyCredentials();
    return store;
  }

  /// 清理 Hive 明文密码；将旧 loginInfo 内的 token 迁入安全存储。
  Future<void> migrateLegacyCredentials() async {
    await _box.delete(StorageKeys.password);

    final raw = _box.get(StorageKeys.loginInfo);
    if (raw is! String || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final access = (map['accessToken'] as String?)?.trim() ?? '';
      final refresh = (map['refreshToken'] as String?)?.trim() ?? '';
      if (refresh.isNotEmpty || access.isNotEmpty) {
        await _secure.saveTokens(
          accessToken: access.isNotEmpty
              ? access
              : (_secure.accessToken ?? ''),
          refreshToken: refresh.isNotEmpty
              ? refresh
              : (_secure.refreshToken ?? ''),
        );
      }
      map['accessToken'] = '';
      map['refreshToken'] = '';
      await _box.put(StorageKeys.loginInfo, jsonEncode(map));
    } catch (_) {}
  }

  // ---- 登录信息 ----

  LoginInfo? getLoginInfo() {
    final access = _secure.accessToken?.trim() ?? '';
    final refresh = _secure.refreshToken?.trim() ?? '';
    final raw = _box.get(StorageKeys.loginInfo);

    Map<String, dynamic> meta = {};
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          meta = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    // 兼容未迁移的旧数据：Hive 里仍可能短暂带有 token。
    final hiveAccess = (meta['accessToken'] as String?)?.trim() ?? '';
    final hiveRefresh = (meta['refreshToken'] as String?)?.trim() ?? '';
    final resolvedAccess = access.isNotEmpty ? access : hiveAccess;
    final resolvedRefresh = refresh.isNotEmpty ? refresh : hiveRefresh;
    if (resolvedAccess.isEmpty && resolvedRefresh.isEmpty) {
      return null;
    }

    return LoginInfo(
      accessToken: resolvedAccess,
      refreshToken: resolvedRefresh,
      userId: _asInt(meta['userId']),
      accessTokenExpiresIn: _asInt(meta['accessTokenExpiresIn']),
      refreshTokenExpiresIn: _asInt(meta['refreshTokenExpiresIn']),
      deviceId: meta['deviceId']?.toString(),
    );
  }

  Future<void> setLoginInfo(LoginInfo info) async {
    await _secure.saveTokens(
      accessToken: info.accessToken,
      refreshToken: info.refreshToken,
    );
    final meta = <String, dynamic>{
      'accessToken': '',
      'refreshToken': '',
      'userId': info.userId,
      'accessTokenExpiresIn': info.accessTokenExpiresIn,
      'refreshTokenExpiresIn': info.refreshTokenExpiresIn,
      if (info.deviceId != null) 'deviceId': info.deviceId,
    };
    await _box.put(StorageKeys.loginInfo, jsonEncode(meta));
    await syncDevIdFromLoginInfo();
  }

  Future<void> clearLoginInfo() async {
    await _secure.clear();
    await _box.delete(StorageKeys.loginInfo);
    await _box.delete(StorageKeys.devId);
  }

  String? get accessToken => getLoginInfo()?.accessToken;

  // ---- 设备唯一标识（仅服务端登录后写入，禁止客户端自造） ----

  Future<void> setDevId(String deviceId) async {
    if (deviceId.isEmpty) return;
    await _box.put(StorageKeys.devId, deviceId);
  }

  String get devId => (_box.get(StorageKeys.devId) as String?) ?? '';

  String get effectiveDevId {
    final stored = devId.trim();
    if (stored.isNotEmpty) return stored;
    return getLoginInfo()?.deviceId?.trim() ?? '';
  }

  Future<void> syncDevIdFromLoginInfo() async {
    final fromLogin = getLoginInfo()?.deviceId?.trim();
    if (fromLogin != null && fromLogin.isNotEmpty) {
      await setDevId(fromLogin);
    }
  }

  // ---- 当前线路 ----

  String getLineId() =>
      (_box.get(StorageKeys.lineId) as String?) ?? kDefaultLine.id;

  Future<void> setLineId(String lineId) =>
      _box.put(StorageKeys.lineId, lineId);

  String? get lineConfigVersion =>
      _box.get(StorageKeys.lineConfigVersion) as String?;

  String? get lineConfigJson =>
      _box.get(StorageKeys.lineConfigJson) as String?;

  Future<void> setLineConfigCache({
    required String version,
    required String linesJson,
  }) async {
    await _box.put(StorageKeys.lineConfigVersion, version);
    await _box.put(StorageKeys.lineConfigJson, linesJson);
  }

  // ---- 当前用户缓存 ----

  Map<String, dynamic>? getUserInfo() {
    final raw = _box.get(StorageKeys.userInfo);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setUserInfo(Map<String, dynamic> info) =>
      _box.put(StorageKeys.userInfo, jsonEncode(info));

  Future<void> clearUserInfo() => _box.delete(StorageKeys.userInfo);

  // ---- 登录页回填（仅手机号，不再存密码） ----

  String? get loginPhone => _box.get(StorageKeys.loginPhone) as String?;

  Future<void> setLoginPhone(String phone) =>
      _box.put(StorageKeys.loginPhone, phone);

  /// @Deprecated 明文密码已废弃，仅用于迁移清理。
  @Deprecated('Do not store plaintext passwords')
  String? get savedPassword => null;

  @Deprecated('Do not store plaintext passwords')
  Future<void> setPassword(String pwd) async {
    await _box.delete(StorageKeys.password);
  }

  Future<void> clearCredentials() async {
    await _box.delete(StorageKeys.loginPhone);
    await _box.delete(StorageKeys.password);
  }

  /// 登出时清理明文密码残留（保留手机号方便回填）。
  Future<void> clearStoredPassword() => _box.delete(StorageKeys.password);

  // ---- 通用 ----

  T? get<T>(String key) => _box.get(key) as T?;

  Future<void> set(String key, Object value) => _box.put(key, value);

  Future<void> remove(String key) => _box.delete(key);

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
