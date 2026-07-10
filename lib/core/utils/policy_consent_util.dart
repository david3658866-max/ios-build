import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

import '../config/app_constants.dart';
import '../storage/kv_store.dart';

/// 首次协议同意状态。对齐 im-uniapp `components/policy/policy.vue`。
abstract final class PolicyConsentUtil {
  static String get storageKey => StorageKeys.hasReadPrivacy;

  /// uniapp 自定义弹窗仅 iOS；Flutter 在 Android/iOS 均展示（Android 无 uni 内置弹窗）。
  static bool get isTargetPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  static bool hasAccepted(KvStore kv) => kv.get<bool>(storageKey) == true;

  static bool shouldShowConsent({
    required KvStore kv,
    bool? isTargetPlatformOverride,
  }) {
    final target = isTargetPlatformOverride ?? isTargetPlatform;
    if (!target) return false;
    return !hasAccepted(kv);
  }

  static Future<void> markAccepted(KvStore kv) => kv.set(storageKey, true);
}
