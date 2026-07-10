import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../widgets/im_confirm_dialog.dart';

/// 系统权限引导。对齐 im-uniapp `permission-ios.js` `showPermissionGuide`。
abstract final class PermissionGuideUtil {
  static const contactsPermissionName = '通讯录';
  static const contactsPermissionPurpose = '访问通讯录用于快速添加好友';
  static const contactsPermissionDeniedHint = '请在系统设置中开启通讯录权限';

  static String contactsPermissionGuideTitle(String permissionName) =>
      '需要$permissionName权限';

  static String contactsPermissionGuideBody(
    String permissionName,
    String description,
  ) =>
      '$description，请在系统设置中开启该权限。';

  /// 弹窗引导去系统设置；用户点「去设置」返回 true。
  static Future<bool> showContactsPermissionGuide(BuildContext context) async {
    final go = await showImConfirmDialog(
      context,
      title: contactsPermissionGuideTitle(contactsPermissionName),
      content: contactsPermissionGuideBody(
        contactsPermissionName,
        contactsPermissionPurpose,
      ),
      confirmText: '去设置',
    );
    if (go == true) {
      await openAppSystemSettings();
      return true;
    }
    return false;
  }

  static Future<bool> openAppSystemSettings() => openAppSettings();
}
