import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'permission_guide_util.dart';
import '../../services/diagnostics/ui_breadcrumb.dart';
import '../../widgets/im_confirm_dialog.dart';

/// 聊天媒体相关系统权限。对齐 im-uniapp `permission.js` storage/camera/micro 引导。
enum MediaPermissionKind {
  album,
  camera,
  microphone,
  /// Android 12 及以下选文件；Android 13+ 走 SAF 无需预检。
  storage,
}

/// 聊天发图/拍摄/视频/语音等场景的精确引导文案。
enum MediaPermissionScenario {
  chatAlbumImage,
  chatAlbumVideo,
  chatCameraPhoto,
  chatCameraVideo,
  chatVoiceMessage,
}

class _MediaPermissionMeta {
  const _MediaPermissionMeta(this.name, this.purpose);

  final String name;
  final String purpose;
}

/// 确保媒体权限；未授权时弹窗引导去系统设置。
abstract final class MediaPermissionUtil {
  MediaPermissionUtil._();

  static const _metaMap = {
    MediaPermissionKind.album: _MediaPermissionMeta(
      '相册',
      '用于从相册选择图片',
    ),
    MediaPermissionKind.camera: _MediaPermissionMeta(
      '相机',
      '用于拍摄照片',
    ),
    MediaPermissionKind.microphone: _MediaPermissionMeta(
      '麦克风',
      '用于录制语音',
    ),
    MediaPermissionKind.storage: _MediaPermissionMeta(
      '存储',
      '用于发送文件、保存附件',
    ),
  };

  static bool isGrantedStatus(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  /// 聊天场景：按按钮使用精确用途说明与权限组合。
  static Future<bool> ensureScenario(
    BuildContext context,
    MediaPermissionScenario scenario,
  ) async {
    switch (scenario) {
      case MediaPermissionScenario.chatAlbumImage:
        return ensure(
          context,
          MediaPermissionKind.album,
          purpose: '用于从相册选择并发送图片',
          guideFeatureName: '相册',
          requireFullAlbumAccess: true,
        );
      case MediaPermissionScenario.chatAlbumVideo:
        return ensure(
          context,
          MediaPermissionKind.album,
          includeVideo: true,
          purpose: '用于从相册选择并发送视频',
          guideFeatureName: '相册',
          requireFullAlbumAccess: true,
        );
      case MediaPermissionScenario.chatCameraPhoto:
        return ensure(
          context,
          MediaPermissionKind.camera,
          purpose: '用于拍摄并发送照片',
          guideFeatureName: '相机',
        );
      case MediaPermissionScenario.chatCameraVideo:
        return _ensurePermissions(
          context,
          permissions: const [
            Permission.camera,
            Permission.microphone,
          ],
          purpose: '用于拍摄并发送视频',
          guideFeatureName: '相机',
          albumAccess: false,
        );
      case MediaPermissionScenario.chatVoiceMessage:
        return ensure(
          context,
          MediaPermissionKind.microphone,
          purpose: '用于录制并发送语音消息',
          guideFeatureName: '麦克风',
        );
    }
  }

  /// 返回 true 表示可继续；false 表示用户未授权或取消。
  ///
  /// [includeVideo] 为 true 时，Android 13+ 会额外检查视频读取权限（选视频场景）。
  /// [purpose] 可覆盖默认引导用途说明（聊天场景请用 [ensureScenario]）。
  /// [requireFullAlbumAccess] 为 true 时，额外用 photo_manager 核对相册访问权。
  /// 「仅所选照片」仍先放行试选；网格失败时再引导「允许全部」。
  static Future<bool> ensure(
    BuildContext context,
    MediaPermissionKind kind, {
    bool includeVideo = false,
    String? purpose,
    String? guideFeatureName,
    bool requireFullAlbumAccess = false,
  }) async {
    final permissions = await _permissionsFor(
      kind,
      includeVideo: includeVideo,
    );
    final meta = _metaMap[kind]!;
    final ok = await _ensurePermissions(
      context,
      permissions: permissions,
      purpose: purpose ?? meta.purpose,
      guideFeatureName: guideFeatureName ?? meta.name,
      albumAccess: kind == MediaPermissionKind.album,
    );
    if (!ok) return false;
    if (requireFullAlbumAccess && kind == MediaPermissionKind.album) {
      return _ensureFullAlbumAccess(
        context,
        purpose: purpose ?? meta.purpose,
        guideFeatureName: guideFeatureName ?? meta.name,
      );
    }
    return true;
  }

  static const _photoOption = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.image,
      mediaLocation: false,
    ),
  );

  /// permission_handler 把 limited 当已授权，但 wechat_assets_picker /
  /// photo_manager 在「仅所选照片」下可能失败。这里先确认至少有访问权；
  /// 若仅为 limited 仍放行试选，失败时再引导「允许全部」。
  static Future<bool> _ensureFullAlbumAccess(
    BuildContext context, {
    required String purpose,
    required String guideFeatureName,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    try {
      var state = await PhotoManager.getPermissionState(
        requestOption: _photoOption,
      );
      UiBreadcrumb.add(
        'album_perm_pm',
        detail: 'auth=${state.isAuth},access=${state.hasAccess}',
      );
      if (state.isAuth) return true;

      // 有限访问：先放行，网格若挂再由 picker 侧引导。
      if (state.hasAccess) {
        UiBreadcrumb.add('album_perm_limited');
        return true;
      }

      // 无访问：走系统申请。
      state = await PhotoManager.requestPermissionExtend(
        requestOption: _photoOption,
      );
      if (state.isAuth || state.hasAccess) return true;
      if (!context.mounted) return false;
      await _showGuide(
        context,
        permissions: await _albumPermissions(),
        purpose: purpose,
        guideFeatureName: guideFeatureName,
        albumAccess: true,
      );
      state = await PhotoManager.getPermissionState(
        requestOption: _photoOption,
      );
      return state.isAuth || state.hasAccess;
    } catch (e) {
      UiBreadcrumb.add('album_perm_pm_err', detail: '$e');
      // photo_manager 异常时不阻断；后续 AssetPicker 仍可能可用。
      return true;
    }
  }

  static Future<void> _showPartialAlbumGuide(
    BuildContext context, {
    required String purpose,
  }) async {
    final go = await showImConfirmDialog(
      context,
      title: PermissionGuideUtil.contactsPermissionGuideTitle('相册'),
      content:
          '$purpose。当前为「仅所选照片」，发图需选择「允许全部」。请在系统设置中修改相册权限。',
      confirmText: '去设置',
      cancelText: '我知道了',
      useRootNavigator: true,
    );
    if (go == true) {
      await PermissionGuideUtil.openAppSystemSettings();
    }
  }

  /// 选图失败时引导用户从「仅所选」改为「允许全部」。
  static Future<void> guidePartialAlbumAccess(
    BuildContext context, {
    required String purpose,
  }) =>
      _showPartialAlbumGuide(context, purpose: purpose);

  static Future<bool> _ensurePermissions(
    BuildContext context, {
    required List<Permission> permissions,
    required String purpose,
    String? guideFeatureName,
    bool albumAccess = false,
  }) async {
    if (permissions.isEmpty) return true;
    if (await _allGranted(permissions)) return true;

    UiBreadcrumb.add(
      'perm_request',
      detail: guideFeatureName ?? purpose,
    );
    await _requestMissing(permissions);
    if (await _allGranted(permissions)) return true;

    if (!context.mounted) return false;
    // 拒绝后系统常因 USER_FIXED 不再弹框；若只在 permanentlyDenied 时引导，
    // 部分机型会「点相册无反应」。未授权时一律给设置引导。
    await _showGuide(
      context,
      permissions: permissions,
      purpose: purpose,
      guideFeatureName: guideFeatureName,
      albumAccess: albumAccess,
    );

    return _allGranted(permissions);
  }

  static Future<List<Permission>> _permissionsFor(
    MediaPermissionKind kind, {
    bool includeVideo = false,
  }) async {
    if (kIsWeb) return const [];

    switch (kind) {
      case MediaPermissionKind.camera:
        return [Permission.camera];
      case MediaPermissionKind.microphone:
        return [Permission.microphone];
      case MediaPermissionKind.album:
        return _albumPermissions(includeVideo: includeVideo);
      case MediaPermissionKind.storage:
        return _storagePermissionsForFile();
    }
  }

  static Future<List<Permission>> _albumPermissions({
    bool includeVideo = false,
  }) async {
    if (Platform.isIOS) return [Permission.photos];
    if (Platform.isAndroid) {
      if (await _androidSdkInt() >= 33) {
        return includeVideo
            ? [Permission.photos, Permission.videos]
            : [Permission.photos];
      }
      return [Permission.storage];
    }
    return const [];
  }

  /// Android 13+ 系统文件选择器（SAF）通常无需存储权限。
  static Future<List<Permission>> _storagePermissionsForFile() async {
    if (!Platform.isAndroid) return const [];
    if (await _androidSdkInt() >= 33) return const [];
    return [Permission.storage];
  }

  static Future<int> _androidSdkInt() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> _allGranted(List<Permission> permissions) async {
    for (final permission in permissions) {
      final status = await permission.status;
      if (!isGrantedStatus(status)) return false;
    }
    return true;
  }

  static Future<void> _requestMissing(List<Permission> permissions) async {
    for (final permission in permissions) {
      var status = await permission.status;
      if (isGrantedStatus(status)) continue;
      if (status.isPermanentlyDenied || status.isRestricted) continue;
      status = await permission.request();
    }
  }

  static Future<List<String>> _missingDisplayNames(
    List<Permission> permissions, {
    required bool albumAccess,
  }) async {
    final names = <String>[];
    for (final permission in permissions) {
      final status = await permission.status;
      if (!isGrantedStatus(status)) {
        names.add(_displayName(permission, albumAccess: albumAccess));
      }
    }
    return names;
  }

  static String _displayName(
    Permission permission, {
    required bool albumAccess,
  }) {
    if (permission == Permission.camera) return '相机';
    if (permission == Permission.microphone) return '麦克风';
    if (permission == Permission.storage) return '存储';
    if (permission == Permission.photos || permission == Permission.videos) {
      return '照片和视频';
    }
    return '相关';
  }

  static String _formatQuotedList(List<String> items) {
    if (items.isEmpty) return '相关';
    final unique = items.toSet().toList();
    if (unique.length == 1) return '「${unique.first}」';
    if (unique.length == 2) {
      return '「${unique[0]}」和「${unique[1]}」';
    }
    final head = unique.sublist(0, unique.length - 1).map((e) => '「$e」').join('、');
    return '$head和「${unique.last}」';
  }

  static String _buildSettingGuideClause({
    required bool albumAccess,
    required List<String> missing,
  }) {
    if (albumAccess) {
      return '请在系统设置中开启「照片和视频」相关权限';
    }
    if (missing.isEmpty) {
      return '请在系统设置中开启相关权限';
    }
    return '请在系统设置中开启${_formatQuotedList(missing)}相关权限';
  }

  static Future<void> _showGuide(
    BuildContext context, {
    required List<Permission> permissions,
    required String purpose,
    String? guideFeatureName,
    bool albumAccess = false,
  }) async {
    final missing = await _missingDisplayNames(
      permissions,
      albumAccess: albumAccess,
    );
    final title = albumAccess
        ? PermissionGuideUtil.contactsPermissionGuideTitle(
            guideFeatureName ?? '相册',
          )
        : missing.length > 1
            ? '需要手动开启权限'
            : PermissionGuideUtil.contactsPermissionGuideTitle(
                guideFeatureName ??
                    (missing.isNotEmpty ? missing.first : '相关'),
              );
    final content =
        '$purpose，${_buildSettingGuideClause(albumAccess: albumAccess, missing: missing)}。';

    final go = await showImConfirmDialog(
      context,
      title: title,
      content: content,
      confirmText: '去设置',
      cancelText: '我知道了',
      // 聊天页可能在嵌套 Navigator 内；用根 Navigator 避免弹窗被挡住或看不见。
      useRootNavigator: true,
    );
    if (go == true) {
      await PermissionGuideUtil.openAppSystemSettings();
    }
  }
}
