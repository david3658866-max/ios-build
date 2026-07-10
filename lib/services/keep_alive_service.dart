import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_constants.dart';
import '../core/di/app_providers.dart';
import '../core/utils/app_logger.dart';

/// Android 前台保活（对齐 im-uniapp App.vue initKeepLive）。
abstract final class KeepAliveService {
  static const _channel = MethodChannel('com.cyberis.vortek/keep_alive');

  /// 启动保活：仅 Android、keepAliveLevel >= 1 且已登录时生效。
  static Future<void> startKeepAlive(Ref ref) async {
    if (!Platform.isAndroid) return;
    if (AppConstants.keepAliveLevel < 1) return;
    final token = ref.read(kvStoreProvider).accessToken;
    if (token == null || token.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('start');
      log.d('[KeepAlive] started');
    } catch (e) {
      log.w('[KeepAlive] start failed: $e');
    }
  }

  /// 停止保活。iOS 与其它平台为 no-op。
  static Future<void> stopKeepAlive(Ref ref) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stop');
      log.d('[KeepAlive] stopped');
    } catch (e) {
      log.w('[KeepAlive] stop failed: $e');
    }
  }
}
