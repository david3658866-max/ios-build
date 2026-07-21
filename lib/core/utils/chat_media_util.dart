// 聊天媒体选取常量。对齐 chat-box.vue / image-upload / video-upload。

// 压缩策略（与 uniapp 一致，客户端不压缩）：
// - 图片：`sizeType: ['original']`，服务端 `/image/upload?thumbSize=50` 生成缩略图
// - 视频：`compressed: false`，服务端 `/video/upload` 生成封面

abstract final class ChatMediaUtil {
  static const int maxAlbumImageCount = 9;

  static const int maxFileCount = 9;

  static const int maxImageBytes = 10 * 1024 * 1024;

  static const int maxFileBytes = 10 * 1024 * 1024;

  static const int maxVideoBytes = 50 * 1024 * 1024;

  /// 对齐 image-upload `thumbSize` 默认 50。

  static const int imageThumbSize = 50;

  /// 对齐 image-upload `isPermanent` 默认 false。

  static const bool imageIsPermanent = false;

  /// 对齐 chat-record 最长 60s、最短 >1s 才发送。
  static const int maxAudioDurationSec = 60;
  static const int minAudioDurationSec = 1;

  /// uniapp APP `format:'mp3'`；Flutter record 无 mp3，用 AAC 原文件上传（有损一次，无二次压缩）。
  static const String audioFileExtension = 'm4a';

  static const Set<String> imageExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  /// 文件名/路径是否为图片（用户从「文件」选截图时用）。
  static bool isImageFileName(String? nameOrPath) {
    if (nameOrPath == null || nameOrPath.isEmpty) return false;
    final cleaned = nameOrPath.split('?').first.trim().toLowerCase();
    final dot = cleaned.lastIndexOf('.');
    if (dot < 0 || dot >= cleaned.length - 1) return false;
    return imageExtensions.contains(cleaned.substring(dot + 1));
  }
}

/// 相册选取的单张图片（原图路径 + 宽高）。

class ChatPickedImage {
  const ChatPickedImage({required this.path, this.width, this.height});

  final String path;

  final int? width;

  final int? height;
}

class NetworkImageFailCache {
  static const Duration _defaultCooldown = Duration(minutes: 5);
  static const int _maxEntries = 512;
  static final Map<String, int> _blockedUntilMs = <String, int>{};

  static bool isTemporarilyBlocked(String url) {
    final normalized = url.trim();
    if (normalized.isEmpty) return false;
    final until = _blockedUntilMs[normalized];
    if (until == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (until <= now) {
      _blockedUntilMs.remove(normalized);
      return false;
    }
    return true;
  }

  static void markFailed(String url, {Duration cooldown = _defaultCooldown}) {
    final normalized = url.trim();
    if (normalized.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _blockedUntilMs[normalized] = now + cooldown.inMilliseconds;
    _trim(now);
  }

  static void markSucceeded(String url) {
    final normalized = url.trim();
    if (normalized.isEmpty) return;
    _blockedUntilMs.remove(normalized);
  }

  static void _trim(int nowMs) {
    if (_blockedUntilMs.length <= _maxEntries) return;
    final expired = <String>[];
    _blockedUntilMs.forEach((key, until) {
      if (until <= nowMs) expired.add(key);
    });
    for (final key in expired) {
      _blockedUntilMs.remove(key);
    }
    if (_blockedUntilMs.length <= _maxEntries) return;
    final removeCount = _blockedUntilMs.length - _maxEntries;
    final keys = _blockedUntilMs.keys.take(removeCount).toList();
    for (final key in keys) {
      _blockedUntilMs.remove(key);
    }
  }
}
