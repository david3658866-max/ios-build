import 'dart:convert';

import '../storage/kv_store.dart';

/// 青少年模式 KV 与功能拦截。对齐 mine-teenager.vue 文案。
/// uniapp 侧暂无业务拦截；Flutter 按「部分功能将受限使用」补拦截点。
abstract final class TeenagerModeUtil {
  static String storageKey(int userId) => 'chats-app-$userId-teenagerMode';

  static bool parseEnabled(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  static bool isEnabled({required int? userId, required KvStore kv}) {
    if (userId == null) return false;
    return parseEnabled(kv.get<String>(storageKey(userId)));
  }
}

enum TeenagerBlockFeature {
  addFriend('添加好友'),
  createGroup('创建群聊'),
  scan('扫一扫'),
  rtcCall('音视频通话'),
  shareCard('分享名片');

  const TeenagerBlockFeature(this.label);
  final String label;
}

bool isTeenagerFeatureBlocked({
  required bool teenagerModeEnabled,
  required TeenagerBlockFeature feature,
}) =>
    teenagerModeEnabled;

String teenagerBlockTip(TeenagerBlockFeature feature) =>
    '青少年模式下无法使用${feature.label}';

/// 若已拦截返回 true。
bool guardTeenagerFeature({
  required bool teenagerModeEnabled,
  required TeenagerBlockFeature feature,
  required void Function(String message) onBlocked,
}) {
  if (!isTeenagerFeatureBlocked(
    teenagerModeEnabled: teenagerModeEnabled,
    feature: feature,
  )) {
    return false;
  }
  onBlocked(teenagerBlockTip(feature));
  return true;
}
