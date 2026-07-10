import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 设备信息快照。对应 im-uniapp common/version.js getDeviceInfo()。
class DevicePayload {
  const DevicePayload({
    required this.deviceInfo,
    required this.clientVersion,
    required this.loginType,
  });

  /// 型号|系统版本|厂商。
  final String deviceInfo;
  final String clientVersion;

  /// android / ios。
  final String loginType;
}

/// 读取设备信息，格式与 uniapp login.vue 上送字段一致。
abstract final class DeviceInfoUtil {
  static Future<DevicePayload> load() async {
    final plugin = DeviceInfoPlugin();
    final pkg = await PackageInfo.fromPlatform();
    var model = 'Unknown';
    var osVersion = 'Unknown';
    var vendor = 'Unknown';
    final loginType = Platform.isIOS ? 'ios' : 'android';

    try {
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        model = a.model;
        vendor = a.manufacturer;
        osVersion = 'Android ${a.version.release}';
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        model = i.utsname.machine;
        vendor = 'Apple';
        osVersion = '${i.systemName} ${i.systemVersion}';
      }
    } catch (_) {
      // 降级为 Platform 信息。
      model = Platform.operatingSystem;
      osVersion = Platform.operatingSystemVersion;
    }

    return DevicePayload(
      deviceInfo: '$model|$osVersion|$vendor',
      clientVersion: pkg.version,
      loginType: loginType,
    );
  }
}
