/// 绑定手机/邮箱表单与 API 契约。对齐 mine-phone.vue / mine-email.vue。
abstract final class UserBindUtil {
  static const smsCodeLockSeconds = 60;

  static final phoneReg = RegExp(r'^1[3-9]\d{9}$');

  static final emailReg =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  static bool isValidPhone(String phone) => phoneReg.hasMatch(phone.trim());

  static bool isValidEmail(String email) => emailReg.hasMatch(email.trim());
}

abstract final class UserBindApiBody {
  static Map<String, dynamic> bindPhone({
    required String phone,
    required String code,
  }) =>
      {'phone': phone, 'code': code};

  static Map<String, dynamic> bindEmail({
    required String email,
    required String code,
  }) =>
      {'email': email, 'code': code};

  static Map<String, dynamic> smsCode({
    required String phone,
    required String captchaId,
    required String captchaCode,
  }) =>
      {'phone': phone, 'id': captchaId, 'code': captchaCode};
}
