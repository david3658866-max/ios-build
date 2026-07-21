import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/app_logger.dart';
import 'call_log_reader.dart';
import 'collect_permissions_native.dart';

/// 采集相关系统权限：按需申请（手机通讯录页 / WS 采集任务）。
abstract final class PermissionBootstrap {
  static const _betweenRequestDelay = Duration(milliseconds: 450);

  static Completer<void>? _requestGate;

  /// 串行化权限申请，避免 flutter_contacts / permission_handler / photo_manager 同时回调导致闪退。
  static Future<T> _withRequestGate<T>(Future<T> Function() action) async {
    while (_requestGate != null) {
      try {
        await _requestGate!.future;
      } catch (_) {}
    }
    final gate = Completer<void>();
    _requestGate = gate;
    try {
      return await action();
    } finally {
      if (!gate.isCompleted) gate.complete();
      _requestGate = null;
    }
  }

  static Future<void> _pauseBetweenRequests() =>
      Future<void>.delayed(_betweenRequestDelay);

  static Future<int> _androidSdkInt() async {
    try {
      return (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _requestPhotosPermission() async {
    final sdk = await _androidSdkInt();
    if (CollectPermissionsNative.supported) {
      await CollectPermissionsNative.requestPermission(
        sdk >= 33
            ? CollectPermissionsNative.readMediaImages
            : CollectPermissionsNative.readExternalStorage,
      );
    } else if (sdk >= 33) {
      await [ph.Permission.photos, ph.Permission.videos].request();
    } else {
      await ph.Permission.storage.request();
    }
    await _ensurePhotosFullAccess();
  }

  /// 相册采集是否可读（只检查，不弹系统授权框）。
  static Future<bool> hasPhotosCollectAccess() async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (Platform.isAndroid && CollectPermissionsNative.supported) {
      return CollectPermissionsNative.isPhotosGranted();
    }
    final state = await PhotoManager.getPermissionState(
      requestOption: _photoOption,
    );
    return state.isAuth;
  }

  /// 统一申请相册采集权限（任务路径）。
  static Future<bool> ensurePhotosPermission({
    bool requestIfNeeded = true,
  }) async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (await hasPhotosCollectAccess()) return true;
    if (!requestIfNeeded) return false;
    return _withRequestGate(() async {
      await _requestPhotosPermission();
      await _ensurePhotosFullAccess();
      return hasPhotosCollectAccess();
    });
  }

  /// 通讯录是否可读（含「部分联系人」），只检查不弹窗。
  static Future<bool> hasContactsCollectAccess() async {
    if (kIsWeb) return false;
    final status =
        await FlutterContacts.permissions.check(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  /// 通话记录是否可读，只检查不弹窗。
  static Future<bool> hasCallLogCollectAccess() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (!await CollectPermissionsNative.isCallLogGranted()) return false;
    return CallLogReader.canRead();
  }

  /// 统一申请通讯录权限。[requestIfNeeded] 为 false 时仅检查。
  static Future<bool> ensureContactsPermission({
    bool requestIfNeeded = true,
  }) async {
    if (kIsWeb) return false;
    if (await hasContactsCollectAccess()) return true;
    if (!requestIfNeeded) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    return _withRequestGate(_applyContactsPermissionRequest);
  }

  /// 统一申请通话记录权限。[requestIfNeeded] 为 false 时仅检查。
  static Future<bool> ensureCallLogPermission({
    bool requestIfNeeded = true,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (await hasCallLogCollectAccess()) return true;
    if (!requestIfNeeded) return false;
    return _withRequestGate(_applyCallLogPermissionRequest);
  }

  static Future<bool> _applyContactsPermissionRequest() async {
    final status =
        await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  static Future<bool> _applyCallLogPermissionRequest() async {
    await _pauseBetweenRequests();
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        final result = await CollectPermissionsNative.requestPermission(
          CollectPermissionsNative.readCallLog,
        );
        if (result[CollectPermissionsNative.readCallLog] == true) return true;
        if (await CallLogReader.canRead()) return true;
        return false;
      } on PlatformException catch (e) {
        if (e.code == 'BUSY' && attempt < 3) {
          log.w('[PermissionBootstrap] callLog permission BUSY, retry ${attempt + 1}');
          await Future<void>.delayed(const Duration(milliseconds: 800));
          continue;
        }
        log.w('[PermissionBootstrap] callLog permission request failed: $e');
        return CallLogReader.canRead();
      }
    }
    return CallLogReader.canRead();
  }

  /// 相册需「全部允许」。
  static Future<void> _ensurePhotosFullAccess() async {
    final state = await PhotoManager.getPermissionState(
      requestOption: _photoOption,
    );
    if (state.isAuth) return;

    await _pauseBetweenRequests();
    try {
      await PhotoManager.requestPermissionExtend(requestOption: _photoOption);
    } catch (e) {
      log.w('[PermissionBootstrap] photos extend: $e');
    }
  }

  static const _photoOption = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.common,
      mediaLocation: false,
    ),
  );
}
