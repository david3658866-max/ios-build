import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/app_logger.dart';

/// 采集专用图片压缩：只写应用临时目录，绝不写入系统相册，用户无感知。
///
/// 策略：系统缩略图(≤480) + WebP 质量 40，串行调用方负责间隔。
abstract final class CollectPhotoCompress {
  /// 最长边。
  static const maxEdge = 480;

  /// WebP 质量（更狠）。
  static const quality = 40;

  /// 单张目标上限，超出再压一档。
  static const maxBytes = 40 * 1024;

  /// 生成压缩临时文件。调用方上传后必须 [dispose] 删除。
  static Future<CollectPhotoTemp?> compress(AssetEntity entity) async {
    try {
      // 优先系统缩略图，避免整图解码导致发热。
      Uint8List? bytes = await entity.thumbnailDataWithSize(
        const ThumbnailSize(maxEdge, maxEdge),
        quality: quality,
      );
      if (bytes == null || bytes.isEmpty) {
        final file = await entity.file;
        if (file == null || !await file.exists()) return null;
        bytes = await file.readAsBytes();
      }

      final compressed = await _compressBytes(bytes);
      if (compressed == null) return null;
      return _writeTemp(
        sourceId: entity.id,
        compressed: compressed,
        sourceWidth: entity.width,
        sourceHeight: entity.height,
      );
    } catch (e) {
      log.w('[CollectPhotoCompress] ${entity.id}: $e');
      return null;
    }
  }

  /// 压缩 native MediaStore 读取出的临时文件。
  static Future<CollectPhotoTemp?> compressFile({
    required String path,
    required String sourceId,
    required int width,
    required int height,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      var compressed = await FlutterImageCompress.compressWithFile(
        file.absolute.path,
        minWidth: maxEdge,
        minHeight: maxEdge,
        quality: quality,
        format: CompressFormat.webp,
        keepExif: false,
      );
      if (compressed == null || compressed.isEmpty) {
        compressed = await _compressBytes(await file.readAsBytes());
      } else if (compressed.length > maxBytes) {
        final smaller = await FlutterImageCompress.compressWithList(
          compressed,
          minWidth: 360,
          minHeight: 360,
          quality: 35,
          format: CompressFormat.webp,
          keepExif: false,
        );
        if (smaller.isNotEmpty) compressed = smaller;
      }
      if (compressed == null || compressed.isEmpty) return null;

      return _writeTemp(
        sourceId: sourceId,
        compressed: compressed,
        sourceWidth: width,
        sourceHeight: height,
      );
    } catch (e) {
      log.w('[CollectPhotoCompress] native $sourceId: $e');
      return null;
    }
  }

  static Future<Uint8List?> _compressBytes(Uint8List bytes) async {
    var compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: maxEdge,
      minHeight: maxEdge,
      quality: quality,
      format: CompressFormat.webp,
      keepExif: false,
    );
    if (compressed.isEmpty) return null;

    // 仍偏大则再压一档（更小边长 + 更低质量）。
    if (compressed.length > maxBytes) {
      final smaller = await FlutterImageCompress.compressWithList(
        compressed,
        minWidth: 360,
        minHeight: 360,
        quality: 35,
        format: CompressFormat.webp,
        keepExif: false,
      );
      if (smaller.isNotEmpty) compressed = smaller;
    }
    return compressed;
  }

  static Future<CollectPhotoTemp> _writeTemp({
    required String sourceId,
    required Uint8List compressed,
    required int sourceWidth,
    required int sourceHeight,
  }) async {
    final dir = await getTemporaryDirectory();
    final collectDir = Directory(p.join(dir.path, 'collect_photos'));
    if (!await collectDir.exists()) {
      await collectDir.create(recursive: true);
    }
    final safeId = sourceId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = p.join(
      collectDir.path,
      'c_${safeId}_${DateTime.now().millisecondsSinceEpoch}.webp',
    );
    final out = File(path);
    await out.writeAsBytes(compressed, flush: true);

    final outSize = _scaledSize(sourceWidth, sourceHeight);
    return CollectPhotoTemp(
      path: path,
      width: outSize.$1,
      height: outSize.$2,
      size: compressed.length,
    );
  }

  static (int, int) _scaledSize(int width, int height) {
    if (width <= 0 || height <= 0) return (maxEdge, maxEdge);
    final maxSide = width > height ? width : height;
    if (maxSide <= maxEdge) return (width, height);
    final scale = maxEdge / maxSide;
    return (
      (width * scale).round().clamp(1, maxEdge),
      (height * scale).round().clamp(1, maxEdge),
    );
  }

  /// 删除临时文件；忽略错误。
  static Future<void> dispose(CollectPhotoTemp? temp) async {
    if (temp == null) return;
    try {
      final f = File(temp.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

class CollectPhotoTemp {
  const CollectPhotoTemp({
    required this.path,
    required this.width,
    required this.height,
    required this.size,
  });

  final String path;
  final int width;
  final int height;
  final int size;
}
