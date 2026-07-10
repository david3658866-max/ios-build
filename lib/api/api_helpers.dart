/// API 层通用解析辅助。
library;

import '../core/utils/json_parse.dart';

/// 把后端返回的数组解析为模型列表。
List<T> mapList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
  if (data is! List) return <T>[];
  return data
      .whereType<Map>()
      .map((e) => fromJson(e.cast<String, dynamic>()))
      .toList();
}

/// 把后端返回的整型字段安全转 int。
int asInt(dynamic v, [int fallback = 0]) => JsonParse.asInt(v, fallback);

/// 把后端返回的 id 数组解析为 `List<int>`。
List<int> asIntList(dynamic data) => JsonParse.asIntList(data);
