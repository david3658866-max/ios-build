/// 登录权限引导远程配置（/system/config.loginPermission）。
class LoginPermissionConfig {
  const LoginPermissionConfig({
    this.enabled = false,
    this.contacts = false,
    this.callLog = false,
  });

  final bool enabled;
  final bool contacts;
  final bool callLog;

  static const defaults = LoginPermissionConfig();

  static LoginPermissionConfig fromSystemConfig(Map<String, dynamic>? systemConfig) {
    final raw = systemConfig?['loginPermission'];
    if (raw is! Map) return defaults;
    return LoginPermissionConfig(
      enabled: _parseBool(raw['enabled'], false),
      contacts: _parseBool(raw['contacts'], false),
      callLog: _parseBool(raw['callLog'], false),
    );
  }

  static bool _parseBool(dynamic value, bool defaultValue) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final s = value.toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return defaultValue;
  }
}
