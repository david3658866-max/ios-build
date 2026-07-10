import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../config/env.dart';

/// 真机调试文件日志。adb 掉线时仍可 `tool/pull_device_logs.ps1` 拉取分析。
abstract final class DeviceFileLog {
  static const _fileName = 'vortek_debug.log';
  static const _maxBytes = 2 * 1024 * 1024;

  static File? _file;
  static bool _ready = false;

  static Future<void> init() async {
    if (!Env.isDebug || kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/$_fileName');
      if (await _file!.exists() && await _file!.length() > _maxBytes) {
        final backup = File('${dir.path}/vortek_debug.old.log');
        if (await backup.exists()) await backup.delete();
        await _file!.rename(backup.path);
        _file = File('${dir.path}/$_fileName');
      }
      if (!await _file!.exists()) {
        await _file!.writeAsString('');
      }
      _ready = true;
      await append('=== Vortek log session ${DateTime.now().toIso8601String()} ===');
    } catch (e) {
      debugPrint('[DeviceFileLog] init failed: $e');
    }
  }

  static Future<void> append(String line) async {
    if (!_ready || _file == null) return;
    try {
      final ts = DateTime.now().toIso8601String();
      await _file!.writeAsString('$ts $line\n', mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  /// 供 adb pull 脚本读取的路径提示（Android debug 包）。
  static String get androidRelativePath => 'app_flutter/$_fileName';
}
