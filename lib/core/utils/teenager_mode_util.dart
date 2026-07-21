import 'dart:convert';

import '../storage/kv_store.dart';
import '../storage/teenager_pin_store.dart';

/// 青少年模式 KV 与功能拦截。对齐 mine-teenager.vue 文案。
/// PIN 明文不再落 Hive：仅存 enabled；哈希在 [TeenagerPinStore]。
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

  /// Hive 只保留 enabled；若仍有旧版明文 password 则迁入安全存储并清除。
  static Future<void> migrateLegacyPinIfNeeded({
    required int userId,
    required KvStore kv,
    required TeenagerPinStore pinStore,
  }) async {
    final key = storageKey(userId);
    final raw = kv.get<String>(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final legacyPin = (data['password'] as String?)?.trim() ?? '';
      final enabled = data['enabled'] == true;
      if (legacyPin.isEmpty) {
        if (data.containsKey('password')) {
          await kv.set(key, jsonEncode({'enabled': enabled}));
        }
        return;
      }
      if (!await pinStore.hasPin(userId)) {
        await pinStore.savePin(userId, legacyPin);
      }
      await kv.set(key, jsonEncode({'enabled': enabled}));
    } catch (_) {}
  }

  static Future<void> setEnabledFlag({
    required int userId,
    required KvStore kv,
    required bool enabled,
  }) async {
    await kv.set(storageKey(userId), jsonEncode({'enabled': enabled}));
  }

  static Future<void> clearMode({
    required int userId,
    required KvStore kv,
    required TeenagerPinStore pinStore,
  }) async {
    await pinStore.clearPin(userId);
    await kv.remove(storageKey(userId));
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
