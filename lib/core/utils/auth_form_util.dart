import 'user_bind_util.dart';

/// 登录/注册表单校验。与 uniapp login.vue / register.vue 对齐。
abstract final class AuthFormUtil {
  static bool isValidPhone(String? phone) =>
      UserBindUtil.isValidPhone(phone ?? '');

  static String? phoneValidationError(String? phone) {
    final v = phone?.trim() ?? '';
    if (v.isEmpty) return '请输入手机号';
    if (!isValidPhone(v)) return '手机号格式错误';
    return null;
  }

  /// uniapp 密码登录 submit 不走图形验证码；验证码仅用于发短信（reset-pwd / bind）。
  static const bool passwordLoginRequiresCaptcha = false;
}
