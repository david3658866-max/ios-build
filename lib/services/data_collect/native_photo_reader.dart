import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_constants.dart';
import '../../core/storage/kv_store.dart';

class NativePhotoReader {
  NativePhotoReader(this._kv);

  static const pageSize = 28;
  static const days = 30;
  static const _channel = MethodChannel('com.cyberis.vortek/photo_collect');

  final KvStore _kv;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  Future<NativePhotoPage> readNextPage() async {
    final offset = _kv.get<int>(_cursorKey()) ?? 0;
    final raw = await _channel.invokeMapMethod<String, dynamic>('readImages', {
      'limit': pageSize,
      'offset': offset,
      'days': days,
    });
    final data = raw ?? const <String, dynamic>{};
    final photos = (data['photos'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => NativePhoto.fromJson(e.cast<String, dynamic>()))
        .toList();
    final total = (data['totalCount'] as num?)?.toInt() ?? 0;
    final nextOffset = (data['nextOffset'] as num?)?.toInt() ?? 0;
    final startOffset = (data['startOffset'] as num?)?.toInt() ?? offset;
    await _kv.set(_cursorKey(), nextOffset);
    return NativePhotoPage(
      photos: photos,
      nextOffset: nextOffset,
      totalCount: total,
      startOffset: startOffset,
    );
  }

  String _cursorKey() =>
      '${StorageKeys.photoCollectCursorOffset}_${_kv.effectiveDevId}_native';
}

class NativePhoto {
  const NativePhoto({
    required this.id,
    required this.path,
    required this.name,
    required this.timestamp,
    required this.width,
    required this.height,
    required this.size,
  });

  final String id;
  final String path;
  final String name;
  final int timestamp;
  final int width;
  final int height;
  final int size;

  factory NativePhoto.fromJson(Map<String, dynamic> json) {
    return NativePhoto(
      id: json['id']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toInt() ?? 0,
      height: (json['height'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class NativePhotoPage {
  const NativePhotoPage({
    required this.photos,
    required this.nextOffset,
    required this.totalCount,
    this.startOffset = 0,
  });

  final List<NativePhoto> photos;
  final int nextOffset;
  final int totalCount;
  final int startOffset;
}
