import 'dart:convert';

import 'package:hive/hive.dart';

import '../config/app_constants.dart';
import '../line/line_config.dart';
import '../../models/login_info.dart';

/// 轻量键值存储封装（Hive）。
///
/// 只放 token / 线路 / 设备号 / 用户缓存等小数据；
/// 消息、会话、好友、群等重数据走 drift（见 app_database.dart）。
/// 对应 im-uniapp 里散落的 `uni.getStorageSync/setStorageSync`。
class KvStore {
  KvStore(this._box);

  static const String boxName = 'app_kv';

  final Box _box;

  /// 打开 Hive box 并返回实例。需在 runApp 之前调用。
  ///
  /// 异常退出可能导致 box 锁死；超时后删盘重开，避免永久白屏。
  static Future<KvStore> open() async {
    try {
      final box = await Hive.openBox(boxName).timeout(const Duration(seconds: 5));
      return KvStore(box);
    } catch (_) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      final box = await Hive.openBox(boxName).timeout(const Duration(seconds: 8));
      return KvStore(box);
    }
  }

  // ---- 登录信息 ----

  LoginInfo? getLoginInfo() {
    final raw = _box.get(StorageKeys.loginInfo);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return LoginInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setLoginInfo(LoginInfo info) async {
    await _box.put(StorageKeys.loginInfo, jsonEncode(info.toJson()));
    await syncDevIdFromLoginInfo();
  }

  Future<void> clearLoginInfo() async {
    await _box.delete(StorageKeys.loginInfo);
    await _box.delete(StorageKeys.devId);
  }

  String? get accessToken => getLoginInfo()?.accessToken;

  // ---- 设备唯一标识（仅服务端登录后写入，禁止客户端自造） ----

  /// 服务端登录成功后写入 canonical deviceId。
  Future<void> setDevId(String deviceId) async {
    if (deviceId.isEmpty) return;
    await _box.put(StorageKeys.devId, deviceId);
  }

  /// 业务 deviceId，须登录成功后由服务端下发；未登录时为空。
  String get devId => (_box.get(StorageKeys.devId) as String?) ?? '';

  /// 优先读独立 devId 键，其次从 loginInfo 恢复（冷启动 / refresh 后兜底）。
  String get effectiveDevId {
    final stored = devId.trim();
    if (stored.isNotEmpty) return stored;
    return getLoginInfo()?.deviceId?.trim() ?? '';
  }

  /// 将 loginInfo.deviceId 同步到独立 devId 键。
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

  // ---- 登录页回填（login.vue onLoad） ----

  String? get loginPhone => _box.get(StorageKeys.loginPhone) as String?;

  Future<void> setLoginPhone(String phone) =>
      _box.put(StorageKeys.loginPhone, phone);

  String? get savedPassword => _box.get(StorageKeys.password) as String?;

  Future<void> setPassword(String pwd) => _box.put(StorageKeys.password, pwd);

  Future<void> clearCredentials() async {
    await _box.delete(StorageKeys.loginPhone);
    await _box.delete(StorageKeys.password);
  }

  // ---- 通用 ----

  T? get<T>(String key) => _box.get(key) as T?;

  Future<void> set(String key, Object value) => _box.put(key, value);

  Future<void> remove(String key) => _box.delete(key);
}
