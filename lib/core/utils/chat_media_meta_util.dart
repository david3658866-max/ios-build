import 'dart:io';
import 'dart:ui' as ui;

import 'package:video_player/video_player.dart';

/// 聊天媒体元数据。对齐 uniapp `getImageInfo` / `chooseVideo` 宽高字段。
abstract final class ChatMediaMetaUtil {
  ChatMediaMetaUtil._();

  static Future<({int? width, int? height})> readImageSize(String path) async {
    try {
      final data = await File(path).readAsBytes();
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      final size = (width: frame.image.width, height: frame.image.height);
      frame.image.dispose();
      return size;
    } catch (_) {
      return (width: null, height: null);
    }
  }

  /// 读取视频宽高。对齐 uniapp `chooseVideo` 返回的 width/height。
  static Future<({int? width, int? height})> readVideoSize(String path) async {
    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
      final size = controller.value.size;
      if (size.width <= 0 || size.height <= 0) {
        return (width: null, height: null);
      }
      return (width: size.width.toInt(), height: size.height.toInt());
    } catch (_) {
      return (width: null, height: null);
    } finally {
      await controller.dispose();
    }
  }
}
