import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:im_device_id/im_device_id.dart';
import 'package:uuid/uuid.dart';

import '../utils/app_logger.dart';

/// 设备硬件标识读取。
///
/// Android：优先 `ANDROID_ID`；坏值/不可用时用持久化 `appgen:<uuid>`。
/// 原生通道由标准插件 `im_device_id` 注册（避免报毒壳架空 MainActivity）；
/// 若原生 appgen 仍失败，再走 `flutter_secure_storage` 兜底。
/// **禁止**每次登录临时随机 UUID。仍读不到时返回空串，由登录层/服务端决定是否放行。
abstract final class DeviceIdUtil {
  static const _channel = MethodChannel(kImDeviceInfoChannel);
  static const _appgenStorageKey = 'appgen_hardware_id';
  static const _secureStorage = FlutterSecureStorage();

  /// 旧模拟器 ANDROID_ID 哨兵。
  static const _androidEmulatorSentinel = '9774d56d682e549c';

  /// Build.ID 形态（曾被误当 ANDROID_ID，跨机撞车）。
  static final _androidBuildId = RegExp(
    r'^[A-Z]{2,}\d[A-Z0-9]*(\.[0-9A-Z]+)+$',
    caseSensitive: false,
  );

  /// Android ANDROID_ID / iOS Keychain 持久 ID（优先于裸 IDFV）。
  /// 读不到或读到坏值时尽量走 appgen 兜底；仍失败返回空字符串。
  ///
  /// 注意：不可使用 `device_info_plus` 的 `AndroidDeviceInfo.id`——那是 `Build.ID`
  ///（系统构建号，同 ROM 多机可撞车），不是 `Settings.Secure.ANDROID_ID`。
  static Future<String> readRawHardwareId() async {
    if (kIsWeb) return '';
    try {
      if (Platform.isAndroid) {
        // ANDROID_ID 通道异常时仍要走 appgen，勿让外层 catch 直接空返回
        String androidId = '';
        try {
          final raw = await _channel.invokeMethod<String>('readAndroidId');
          androidId = (raw ?? '').trim();
        } catch (e) {
          log.w('[DeviceIdUtil] readAndroidId failed: $e');
        }
        if (isUsableAndroidRawId(androidId)) {
          return androidId;
        }
        if (androidId.isNotEmpty) {
          log.w('[DeviceIdUtil] reject bad ANDROID_ID, fallback appgen');
        }
        // 全0/坏值/旧包无通道：生成本机唯一兜底 ID（原生 SharedPreferences）
        try {
          final appgen = await _channel
              .invokeMethod<String>('readOrCreateAndroidHardwareId');
          final id = (appgen ?? '').trim();
          if (isUsableAndroidRawId(id)) {
            return id;
          }
          log.w('[DeviceIdUtil] appgen unusable: ${id.isEmpty ? "<empty>" : id}');
        } catch (e) {
          // 旧 APK 无此 method → MissingPluginException / notImplemented
          log.w('[DeviceIdUtil] readOrCreateAndroidHardwareId failed: $e');
        }
        // 报毒壳弄坏自定义通道时：标准 secure_storage 插件仍可能可用
        final dartAppgen = await _readOrCreateDartAppGenId();
        if (dartAppgen.isNotEmpty) {
          return dartAppgen;
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

  static Future<String> _readOrCreateDartAppGenId() async {
    try {
      final existing = (await _secureStorage.read(key: _appgenStorageKey) ?? '')
          .trim();
      if (isUsableAndroidRawId(existing)) {
        return existing;
      }
      final fresh = 'appgen:${const Uuid().v4()}';
      await _secureStorage.write(key: _appgenStorageKey, value: fresh);
      log.w('[DeviceIdUtil] using dart secure_storage appgen fallback');
      return fresh;
    } catch (e) {
      log.w('[DeviceIdUtil] dart appgen fallback failed: $e');
      return '';
    }
  }

  /// 与服务端 HardwareFingerprintUtil.isInvalidAndroidRawId 对齐（可用 = 非无效）。
  static bool isUsableAndroidRawId(String raw) {
    final r = raw.trim();
    if (r.isEmpty) return false;
    if (r.toLowerCase() == 'unknown') return false;
    // 本机生成的兜底 ID：appgen:<uuid>
    if (r.toLowerCase().startsWith('appgen:')) {
      final rest = r.substring(7);
      return RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(rest);
    }
    if (r.toLowerCase() == _androidEmulatorSentinel) return false;
    if (r.toLowerCase() == '0000000000000000') return false;
    if (r.toLowerCase() == 'ffffffffffffffff') return false;
    if (r.length < 8) return false;
    if (_androidBuildId.hasMatch(r)) return false;
    if (RegExp(r'^([0-9A-Fa-f])\1{7,}$').hasMatch(r)) return false;
    return true;
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
    }
    return '';
  }
}
