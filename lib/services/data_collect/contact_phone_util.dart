import 'package:flutter_contacts/flutter_contacts.dart';

/// 通讯录号码提取与去重。
///
/// 只去掉空格、横线等格式字符；仅当「逻辑上同一号码」（如 138xxx 与 +86138xxx）
/// 才合并，避免把三个不同号码压成一个。
abstract final class ContactPhoneUtil {
  /// 从联系人取出全部有效号码（去重后）。
  static List<String> extractPhones(Contact contact) {
    final byKey = <String, String>{};
    for (final p in contact.phones) {
      final digits = digitsOnly(p.number);
      if (digits.isEmpty) continue;
      final key = dedupKey(digits);
      final preferred = preferLocalForm(digits);
      final existing = byKey[key];
      // 同一逻辑号码只保留一条；优先更完整的本地 11 位形式
      final preferThis = existing == null ||
          (preferred.length == 11 && existing.length != 11) ||
          preferred.length > existing.length;
      if (preferThis) {
        byKey[key] = preferred;
      }
    }
    return byKey.values.toList(growable: false);
  }

  /// 格式化为上报结构。
  static Map<String, dynamic>? toReportMap(Contact contact) {
    final phones = extractPhones(contact);
    if (phones.isEmpty) return null;
    final name = (contact.displayName ?? '').trim();
    final display = name.isNotEmpty ? name : phones.first;
    final id = (contact.id ?? '').trim();
    return {
      'id': id.isNotEmpty ? id : display,
      'name': display,
      'primaryPhone': phones.first,
      'phones': phones,
    };
  }

  static String digitsOnly(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '');

  /// 去重键：去掉国际前缀后比较。
  static String dedupKey(String digits) {
    var d = digits;
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('86') && d.length >= 13) d = d.substring(2);
    return d;
  }

  /// 展示/存储优先用国内 11 位。
  static String preferLocalForm(String digits) {
    var d = digits;
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('86') && d.length >= 13) d = d.substring(2);
    return d;
  }
}
