import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_logger.dart';
import 'chat_media_util.dart';

/// 聊天发图前预处理：服务端 [FileUtil.isImage] 只认 jpeg/jpg/bmp/png/webp/gif，
/// iOS 相册原图常为 HEIC，直接上传会被拒「图片格式不合法」。
abstract final class ChatImagePrepareUtil {
  ChatImagePrepareUtil._();

  /// 服务端 `/image/upload` 允许的扩展名（与 FileUtil.isImage 对齐）。
  static const serverImageExtensions = {
    'jpeg',
    'jpg',
    'bmp',
    'png',
    'webp',
    'gif',
  };

  /// 转为可上传文件。HEIC/无扩展名 → JPEG；超 10MB → 压缩到上限内。
  /// 失败返回 null（调用方 toast）。
  static Future<ChatPreparedImage?> prepareForUpload(
    String path, {
    int? width,
    int? height,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        log.w('[ChatImagePrepare] missing path=$path');
        return null;
      }

      final absPath = file.absolute.path;
      final ext = _extOf(absPath);
      final bytes = await file.length();
      final needsConvert = !serverImageExtensions.contains(ext);
      final needsCompress = bytes > ChatMediaUtil.maxImageBytes;

      if (!needsConvert && !needsCompress) {
        return ChatPreparedImage(
          path: absPath,
          width: width,
          height: height,
          bytes: bytes,
        );
      }

      log.i(
        '[ChatImagePrepare] convert ext=$ext bytes=$bytes '
        'needsConvert=$needsConvert needsCompress=$needsCompress',
      );

      final prepared = await _toJpegUnderLimit(
        absPath,
        preferQuality: needsCompress ? 85 : 92,
      );
      if (prepared == null) {
        log.w('[ChatImagePrepare] compress failed path=$absPath');
        return null;
      }

      return ChatPreparedImage(
        path: prepared.path,
        width: width,
        height: height,
        bytes: prepared.bytes,
      );
    } catch (e, st) {
      log.w('[ChatImagePrepare] failed path=$path err=$e\n$st');
      return null;
    }
  }

  static String _extOf(String path) {
    final cleaned = path.split('?').first.trim().toLowerCase();
    final dot = cleaned.lastIndexOf('.');
    if (dot < 0 || dot >= cleaned.length - 1) return '';
    return cleaned.substring(dot + 1);
  }

  static bool isServerAcceptedFileName(String nameOrPath) {
    return serverImageExtensions.contains(_extOf(nameOrPath));
  }

  static Future<({String path, int bytes})?> _toJpegUnderLimit(
    String sourcePath, {
    required int preferQuality,
  }) async {
    final dir = await getTemporaryDirectory();
    final outDir = Directory(p.join(dir.path, 'chat_send_images'));
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    var quality = preferQuality;
    for (var attempt = 0; attempt < 4; attempt++) {
      final outPath = p.join(
        outDir.path,
        'chat_${DateTime.now().millisecondsSinceEpoch}_$attempt.jpg',
      );
      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        outPath,
        quality: quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (result == null) {
        quality = (quality - 15).clamp(40, 95);
        continue;
      }
      final outFile = File(result.path);
      final outBytes = await outFile.length();
      if (outBytes <= ChatMediaUtil.maxImageBytes && outBytes > 0) {
        return (path: outFile.absolute.path, bytes: outBytes);
      }
      try {
        if (await outFile.exists()) await outFile.delete();
      } catch (_) {}
      quality = (quality - 15).clamp(40, 95);
    }
    return null;
  }
}

class ChatPreparedImage {
  const ChatPreparedImage({
    required this.path,
    required this.bytes,
    this.width,
    this.height,
  });

  final String path;
  final int bytes;
  final int? width;
  final int? height;
}
