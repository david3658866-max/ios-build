/// 字符串工具。
abstract final class StringUtil {
  static bool isBlank(String? s) => s == null || s.trim().isEmpty;

  static bool isNotBlank(String? s) => !isBlank(s);

  /// 取展示名优先级：备注 > 昵称 > 兜底。
  static String pickName({
    String? remark,
    String? nickName,
    String fallback = '',
  }) {
    if (isNotBlank(remark)) return remark!.trim();
    if (isNotBlank(nickName)) return nickName!.trim();
    return fallback;
  }

  /// 截断超长文本（会话最后一条预览等）。
  static String ellipsis(String? s, int max) {
    if (s == null) return '';
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…';
  }

  /// 手机号脱敏：138****8888。
  static String maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    final v = phone.trim();
    if (v.length < 7) return v;
    return '${v.substring(0, 3)}****${v.substring(v.length - 4)}';
  }

  /// 邮箱脱敏：a**@example.com。
  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    final v = email.trim();
    final at = v.indexOf('@');
    if (at <= 0) return v;
    final local = v.substring(0, at);
    final domain = v.substring(at);
    if (local.length <= 1) return '*$domain';
    return '${local[0]}${'*' * (local.length - 1)}$domain';
  }
}
