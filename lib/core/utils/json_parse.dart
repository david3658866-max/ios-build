/// 后端 JSON 宽松解析。
///
/// Jackson 序列化 `java.util.Date` 常为 ISO8601 字符串；部分字段也可能以字符串形式返回整型。
abstract final class JsonParse {
  static int asInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static int? asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static bool asBool(dynamic v, [bool fallback = false]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return fallback;
  }

  static String? asNullableString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  /// 解析为毫秒时间戳。支持 num、纯数字字符串、ISO8601。
  static int? asNullableDateTimeMs(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) {
      if (v.isEmpty) return null;
      final n = int.tryParse(v);
      if (n != null) return n;
      return DateTime.tryParse(v)?.millisecondsSinceEpoch;
    }
    return null;
  }

  static String asString(dynamic v, [String fallback = '']) {
    return asNullableString(v) ?? fallback;
  }

  static int _typeFromJson(dynamic v) => v == null ? 1 : asInt(v, 1);
  static int typeFromJson(dynamic v) => _typeFromJson(v);

  static List<int> asIntList(dynamic data) {
    if (data is! List) return const [];
    return data.map(asInt).toList();
  }
}
