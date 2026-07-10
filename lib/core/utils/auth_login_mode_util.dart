/// 登录方式。对齐 im-uniapp login.vue `modeNameMap` / `modes()`。
enum AuthLoginMode {
  username,
  phone,
  email,
}

/// 当前启用的登录方式与展示文案。
abstract final class AuthLoginModeUtil {
  /// uniapp `computed.modes()` 当前仅返回 `['username']`。
  static const List<AuthLoginMode> enabledModes = [AuthLoginMode.username];

  static const Map<AuthLoginMode, String> displayNames = {
    AuthLoginMode.username: '密码登录',
    AuthLoginMode.phone: '手机登录',
    AuthLoginMode.email: '邮箱登录',
  };

  static bool get showModeSwitcher => enabledModes.length > 1;

  static String displayName(AuthLoginMode mode) =>
      displayNames[mode] ?? displayNames[AuthLoginMode.username]!;

  /// 对齐 uniapp submit：`userName = phone`，`mode = 'username'`。
  static String resolveUserName({
    required AuthLoginMode mode,
    required String phone,
    String? email,
  }) {
    return switch (mode) {
      AuthLoginMode.phone => phone,
      AuthLoginMode.email => email?.trim() ?? '',
      AuthLoginMode.username => phone,
    };
  }
}
