import "dart:io" show Platform;

import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/foundation.dart";

/// Physical device / emulator heuristic signals (not 100%).
class DeviceIntegrityPayload {
  const DeviceIntegrityPayload({
    required this.isPhysicalDevice,
    required this.emulatorSuspect,
  });

  final bool isPhysicalDevice;
  final bool emulatorSuspect;
}

abstract final class DeviceIntegrityUtil {
  static final _emulatorHints = RegExp(
    r"(sdk_gphone|emulator|generic|unknown|vbox|genymotion|bluestacks|nox|mumu|ldplayer|tencent_game)",
    caseSensitive: false,
  );

  static Future<DeviceIntegrityPayload> probe() async {
    if (kIsWeb) {
      return const DeviceIntegrityPayload(
        isPhysicalDevice: false,
        emulatorSuspect: true,
      );
    }
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        final physical = a.isPhysicalDevice;
        final blob = [
          a.model,
          a.brand,
          a.manufacturer,
          a.product,
          a.hardware,
          a.fingerprint,
        ].join("|");
        final suspect = !physical || _emulatorHints.hasMatch(blob);
        return DeviceIntegrityPayload(
          isPhysicalDevice: physical,
          emulatorSuspect: suspect,
        );
      }
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        final physical = i.isPhysicalDevice;
        return DeviceIntegrityPayload(
          isPhysicalDevice: physical,
          emulatorSuspect: !physical,
        );
      }
    } catch (_) {}
    return const DeviceIntegrityPayload(
      isPhysicalDevice: true,
      emulatorSuspect: false,
    );
  }
}