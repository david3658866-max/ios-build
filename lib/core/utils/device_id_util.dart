import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';

/// 设备硬件标识读取。**禁止任何随机 UUID 兜底**。
abstract final class DeviceIdUtil {
  static const _channel = MethodChannel('com.cyberis.vortek/device_info');

  /// Android ANDROID_ID / iOS Keychain 持久 ID（优先于裸 IDFV）。
  /// 读不到返回空字符串（调用方须拒绝登录）。
  ///
  /// 注意：不可使用 `device_info_plus` 的 `AndroidDeviceInfo.id`——那是 `Build.ID`
  ///（系统构建号，同 ROM 多机可撞车），不是 `Settings.Secure.ANDROID_ID`。
  static Future<String> readRawHardwareId() async {
    if (kIsWeb) return '';
    try {
      if (Platform.isAndroid) {
        final raw = await _channel.invokeMethod<String>('readAndroidId');
        final androidId = (raw ?? '').trim();
        if (androidId.isNotEmpty &&
            androidId.toLowerCase() != 'unknown' &&
            androidId != '9774d56d682e549c') {
          return androidId;
        }
      } else if (Platform.isIOS) {
        // Keychain 自建 UUID：卸 App 再装常仍保留；工厂重置仍会变。
        final raw =
            await _channel.invokeMethod<String>('readOrCreateIosHardwareId');
        final id = (raw ?? '').trim();
        if (id.isNotEmpty && id.toLowerCase() != 'unknown') {
          return id;
        }
        // 通道失败时回退 IDFV（旧包兼容）
        final plugin = DeviceInfoPlugin();
        final info = await plugin.iosInfo;
        final idfv = info.identifierForVendor?.trim() ?? '';
        if (idfv.isNotEmpty) {
          return idfv;
        }
      }
    } catch (e) {
      log.w('[DeviceIdUtil] readRawHardwareId failed: $e');
    }
    return '';
  }

  /// iOS DeviceCheck token（Base64）。不支持/失败返回空，登录仍可走同机型兜底。
  static Future<String> readDeviceCheckToken() async {
    if (kIsWeb || !Platform.isIOS) return '';
    try {
      final raw =
          await _channel.invokeMethod<String>('generateDeviceCheckToken');
      return (raw ?? '').trim();
    } catch (e) {
      log.w('[DeviceIdUtil] readDeviceCheckToken failed: $e');
      return '';
    }
  }
}
