import 'package:flutter_contacts/flutter_contacts.dart';

import '../config/app_constants.dart';

/// 通讯录权限引导「每日一次」日期键。对齐 friend.vue `contacts_guide_last_date`。
String contactsGuideDayKey(DateTime dateTime) {
  final local = dateTime.toLocal();
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '${local.year}-$m-$d';
}

/// 是否应弹出通讯录授权引导（纯逻辑，便于单测）。
bool shouldShowContactsPermissionGuide({
  required String? lastGuideDayKey,
  required String todayDayKey,
  required bool hasPermission,
}) {
  if (hasPermission) return false;
  if (lastGuideDayKey == todayDayKey) return false;
  return true;
}

bool isDeviceContactsGranted(PermissionStatus status) =>
    status == PermissionStatus.granted ||
    status == PermissionStatus.limited;

/// KV 键，与 uniapp `contacts_guide_last_date` 一致。
String get contactsGuideLastDateKey => StorageKeys.contactsGuideLastDate;
