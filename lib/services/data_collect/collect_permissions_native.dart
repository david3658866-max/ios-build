import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android 原生采集权限（在 MainActivity 上弹出系统授权框，比插件更稳定）。
abstract final class CollectPermissionsNative {
  static const _channel =
      MethodChannel('com.cyberis.vortek/collect_permissions');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  static Future<Map<String, bool>> getStates() async {
    if (!supported) return {};
    final raw = await _channel.invokeMethod<dynamic>('getStates');
    return _parseBoolMap(raw);
  }

  /// 申请单项 Android 权限（如 READ_CALL_LOG）。
  static Future<Map<String, bool>> requestPermission(String androidPermission) async {
    if (!supported) return {};
    final raw = await _channel.invokeMethod<dynamic>(
      'requestPermission',
      {'permission': androidPermission},
    );
    return _parseBoolMap(raw);
  }

  static const readCallLog = 'android.permission.READ_CALL_LOG';
  static const readContacts = 'android.permission.READ_CONTACTS';
  static const readMediaImages = 'android.permission.READ_MEDIA_IMAGES';
  static const readExternalStorage = 'android.permission.READ_EXTERNAL_STORAGE';

  static Future<bool> isCallLogGranted() async {
    final states = await getStates();
    return states['callLog'] == true;
  }

  static Future<bool> isPhotosGranted() async {
    final states = await getStates();
    return states['photos'] == true;
  }

  /// 弹出系统权限询问（缺几项弹几项，通常 3～4 次）。
  static Future<Map<String, bool>> requestAll() async {
    if (!supported) return {};
    final raw = await _channel.invokeMethod<dynamic>('requestAll');
    return _parseBoolMap(raw);
  }

  /// 是否「不再询问」（需在至少拒绝过一次后判断）。
  static Future<bool> isPermanentlyDenied(String androidPermission) async {
    if (!supported) return false;
    final denied = await _channel.invokeMethod<bool>(
      'isPermanentlyDenied',
      {'permission': androidPermission},
    );
    return denied == true;
  }

  static Map<String, bool> _parseBoolMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value == true),
    );
  }
}
