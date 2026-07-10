import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_logger.dart';

/// 设备硬件标识读取。**禁止任何随机 UUID 兜底**。
abstract final class DeviceIdUtil {
  /// Android ANDROID_ID / iOS IDFV。读不到返回空字符串（调用方须拒绝登录）。
  static Future<String> readRawHardwareId() async {
    if (kIsWeb) return '';
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        final androidId = info.id.trim();
        if (androidId.isNotEmpty &&
            androidId.toLowerCase() != 'unknown' &&
            androidId != '9774d56d682e549c') {
          return androidId;
        }
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        final id = info.identifierForVendor?.trim() ?? '';
        if (id.isNotEmpty) {
          return id;
        }
      }
    } catch (e) {
      log.w('[DeviceIdUtil] readRawHardwareId failed: $e');
    }
    return '';
  }
}

/// Android IMEI 采集（需 READ_PHONE_STATE；Android 10+ 可能为空，不兜底伪造）。
class DeviceImeiPayload {
  const DeviceImeiPayload({this.imei, this.imei2});

  final String? imei;
  final String? imei2;

  bool get hasAny => (imei != null && imei!.isNotEmpty) ||
      (imei2 != null && imei2!.isNotEmpty);
}

abstract final class DeviceImeiUtil {
  static const _channel = MethodChannel('com.cyberis.vortek/device_info');

  /// 尽力读取 IMEI；iOS / 无权限 / 系统限制时返回空，**绝不伪造**。
  static Future<DeviceImeiPayload> read() async {
    if (kIsWeb || !Platform.isAndroid) {
      return const DeviceImeiPayload();
    }
    try {
      final perm = await Permission.phone.status;
      if (!perm.isGranted) {
        await Permission.phone.request();
      }
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('readImei');
      if (raw == null) return const DeviceImeiPayload();
      String? pick(Object? v) {
        final s = v?.toString().trim();
        if (s == null || s.isEmpty) return null;
        return s;
      }
      return DeviceImeiPayload(
        imei: pick(raw['imei']),
        imei2: pick(raw['imei2']),
      );
    } catch (e) {
      log.w('[DeviceImeiUtil] read failed: $e');
      return const DeviceImeiPayload();
    }
  }
}
