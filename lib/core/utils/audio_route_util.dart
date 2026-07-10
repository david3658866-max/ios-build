import 'dart:io';

import 'package:flutter/services.dart';

import 'app_logger.dart';

/// 通话音频路由（听筒/扬声器）。对齐 uniapp chat-private-video setAudioRoute。
abstract final class AudioRouteUtil {
  static const _channel = MethodChannel('com.cyberis.vortek/audio_route');

  static Future<void> setSpeakerphoneOn(bool isSpeaker) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'setSpeakerphoneOn',
        {'isSpeaker': isSpeaker},
      );
      log.d('[AudioRoute] speaker=$isSpeaker');
    } catch (e) {
      log.w('[AudioRoute] setSpeakerphoneOn failed: $e');
    }
  }
}
