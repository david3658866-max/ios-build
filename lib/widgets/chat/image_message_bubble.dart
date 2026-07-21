import 'dart:convert';

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_providers.dart';
import '../../core/enums/message_status.dart';
import '../../core/utils/chat_media_util.dart';
import '../../core/utils/file_download_util.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/group_sender_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../image_preview_dialog.dart';
import 'chat_sender_name_row.dart';
import 'message_send_status.dart';

/// 图片消息气泡。对齐 chat-message-item.vue `.message-image`。

class ImageMessageBubble extends ConsumerStatefulWidget {
  const ImageMessageBubble({
    super.key,

    required this.message,

    required this.selfSend,

    this.senderName,

    this.senderRoles = const {},

    this.onResend,

    this.onContentChanged,
  });

  final Message message;

  final bool selfSend;

  final String? senderName;

  final Set<GroupSenderRole> senderRoles;

  final VoidCallback? onResend;

  /// 缩略图加载完成后写回 message.content（对齐 uniapp thumbLoad 持久化）。
  final ValueChanged<String>? onContentChanged;

  @override
  ConsumerState<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends ConsumerState<ImageMessageBubble> {
  bool _thumbLoad = false;
  final Set<String> _failedDisplayUrls = <String>{};

  @override
  void initState() {
    super.initState();

    final content = _parseContent(widget.message.content);

    _thumbLoad = content['thumbLoad'] == true;
  }

  @override
  void didUpdateWidget(covariant ImageMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.message.content != widget.message.content) {
      final content = _parseContent(widget.message.content);

      _thumbLoad = content['thumbLoad'] == true;
      _failedDisplayUrls.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _parseContent(widget.message.content);

    final displayUrl = _displayUrl(content);
    final displayCacheKey = _cacheKey(content, displayUrl);

    final size = _imageSize(context, content);

    final radius = BorderRadius.circular(rpx(context, 10));

    final sending = widget.message.status == MessageStatus.sending;

    return Column(
      crossAxisAlignment: widget.selfSend
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,

      children: [
        ?chatSenderNameLine(
          context,

          selfSend: widget.selfSend,

          name: widget.senderName,

          roles: widget.senderRoles,
        ),

        Row(
          mainAxisAlignment: widget.selfSend
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,

          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            if (widget.selfSend)
              MessageSendSideIcon(
                message: widget.message,

                onResend: widget.onResend,

                showSendingSpinner: false,
              ),

            Flexible(
              child: GestureDetector(
                onTap: displayUrl.isEmpty
                    ? null
                    : () => _showFullImage(context, content),

                child: SizedBox(
                  width: size.width,

                  height: size.height,

                  child: Stack(
                    fit: StackFit.expand,

                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: sending
                              ? Colors.transparent
                              : const Color(0xFFF4F6FA),
                          borderRadius: radius,
                        ),

                        clipBehavior: Clip.antiAlias,

                        child: displayUrl.isEmpty
                            ? SizedBox(width: size.width, height: size.height)
                            : _ImageContent(
                                url: displayUrl,
                                cacheKey: displayCacheKey,

                                size: size,

                                onLoaded: () =>
                                    _onThumbLoaded(content, displayUrl),

                                onError: () =>
                                    _onThumbError(content, displayUrl),
                              ),
                      ),

                      if (sending)
                        ClipRRect(
                          borderRadius: radius,

                          child: const MessageMediaSendingOverlay(),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            if (!widget.selfSend) SizedBox(width: rpx(context, 8)),
          ],
        ),

        if (showPrivateReadLabel(widget.message, widget.selfSend))
          MessagePrivateReadLabel(message: widget.message),
      ],
    );
  }

  void _onThumbLoaded(Map<String, dynamic> content, String loadedUrl) {
    final preview = content['previewUrl'] as String?;

    if (preview == null || preview.isEmpty || preview == loadedUrl) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      _persistThumbLoad(content);
    });
  }

  void _onThumbError(Map<String, dynamic> content, String failedUrl) {
    final normalized = failedUrl.trim();
    if (normalized.isNotEmpty && !_failedDisplayUrls.contains(normalized)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _failedDisplayUrls.contains(normalized)) return;
        setState(() => _failedDisplayUrls.add(normalized));
      });
    }

    final preview = content['previewUrl'] as String?;

    if (preview == null || preview.isEmpty) return;

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _persistThumbLoad(content);
      }
    });
  }

  void _persistThumbLoad(Map<String, dynamic> content) {
    final next = Map<String, dynamic>.from(content)..['thumbLoad'] = true;

    setState(() => _thumbLoad = true);

    widget.onContentChanged?.call(jsonEncode(next));
  }

  Map<String, dynamic> _parseContent(String? raw) {
    if (raw == null || raw.isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) return decoded;

      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return {};
  }

  String _displayUrl(Map<String, dynamic> content) {
    final candidates = _displayCandidates(content);
    for (final url in candidates) {
      if (_failedDisplayUrls.contains(url)) continue;
      return url;
    }
    return candidates.isEmpty ? '' : candidates.first;
  }

  List<String> _displayCandidates(Map<String, dynamic> content) {
    final urls = <String>[];
    if (_thumbLoad) {
      _addMediaCandidate(urls, content, 'previewUrl', 'preview');
      _addMediaCandidate(urls, content, 'originUrl', 'origin');
      _addMediaCandidate(urls, content, 'thumbUrl', 'thumb');
      // 文件通道发来的图片仅有 url
      _addMediaCandidate(urls, content, 'url', 'origin');
    } else {
      _addMediaCandidate(urls, content, 'thumbUrl', 'thumb');
      _addMediaCandidate(urls, content, 'previewUrl', 'preview');
      _addMediaCandidate(urls, content, 'originUrl', 'origin');
      _addMediaCandidate(urls, content, 'url', 'origin');
    }
    return urls;
  }

  void _addMediaCandidate(
    List<String> target,
    Map<String, dynamic> content,
    String field,
    String role,
  ) {
    final raw = content[field]?.toString().trim() ?? '';
    final fileId = content['fileId']?.toString();
    final preferDirect = content['useDirectMedia'] == true;
    final apiBase = ref.read(lineProvider).baseUrl;
    final token = ref.read(kvStoreProvider).accessToken;
    final proxied = FileDownloadUtil.toAuthedMediaUrl(
      apiBaseUrl: apiBase,
      accessToken: token,
      fileId: fileId,
      fileUrl: raw.isEmpty ? null : raw,
      role: role,
      preferDirect: preferDirect,
    );
    if (proxied.isNotEmpty && !target.contains(proxied)) {
      target.add(proxied);
    }
    // Fallback direct CDN while anonymous remains open (Phase A).
    if (raw.isNotEmpty && !target.contains(raw)) {
      target.add(raw);
    }
  }

  void _addIfNotBlank(List<String> target, Object? raw) {
    if (raw == null) return;
    final value = raw.toString().trim();
    if (value.isEmpty) return;
    if (target.contains(value)) return;
    target.add(value);
  }

  String _fullImageUrl(Map<String, dynamic> content) {
    final urls = <String>[];
    _addMediaCandidate(urls, content, 'originUrl', 'origin');
    _addMediaCandidate(urls, content, 'previewUrl', 'preview');
    _addMediaCandidate(urls, content, 'thumbUrl', 'thumb');
    _addMediaCandidate(urls, content, 'url', 'origin');
    return urls.isEmpty ? '' : urls.first;
  }

  String? _cacheKey(Map<String, dynamic> content, String url) {
    final fileId = content['fileId'];
    if (fileId == null) return null;
    final normalized = fileId.toString().trim();
    if (normalized.isEmpty) return null;
    final role = _urlRole(content, url);
    return 'img_${normalized}_$role';
  }

  String _urlRole(Map<String, dynamic> content, String url) {
    final normalized = url.trim();
    if (normalized.isEmpty) return 'unknown';
    final uri = Uri.tryParse(normalized);
    final roleQ = uri?.queryParameters['role'];
    if (roleQ != null && roleQ.isNotEmpty) {
      return roleQ;
    }
    final thumb = content['thumbUrl']?.toString().trim();
    final preview = content['previewUrl']?.toString().trim();
    final origin = content['originUrl']?.toString().trim();
    if (thumb != null && thumb.isNotEmpty && thumb == normalized) {
      return 'thumb';
    }
    if (preview != null && preview.isNotEmpty && preview == normalized) {
      return 'preview';
    }
    if (origin != null && origin.isNotEmpty && origin == normalized) {
      return 'origin';
    }
    return 'extra';
  }

  Size _imageSize(BuildContext context, Map<String, dynamic> content) {
    final screenW = MediaQuery.sizeOf(context).width;

    final maxSize = screenW * 0.6;

    final minSize = screenW * 0.2;

    final width = (content['width'] as num?)?.toDouble();

    final height = (content['height'] as num?)?.toDouble();

    if (width != null && height != null && width > 0 && height > 0) {
      final ratio = width < height ? width / height : height / width;

      final w = width > height
          ? maxSize.clamp(minSize, maxSize)
          : (ratio * maxSize).clamp(minSize, maxSize);

      final h = width > height
          ? (ratio * maxSize).clamp(minSize, maxSize)
          : maxSize.clamp(minSize, maxSize);

      return Size(w, h);
    }

    const legacyMin = 100.0;

    return Size(
      maxSize.clamp(legacyMin, maxSize),

      maxSize.clamp(legacyMin, maxSize),
    );
  }

  void _showFullImage(BuildContext context, Map<String, dynamic> content) {
    final url = _fullImageUrl(content);

    if (url.isEmpty) return;

    showNetworkImagePreview(
      context,
      url,
      cacheKey: _cacheKey(content, url),
      enableSave: true,
    );
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({
    required this.url,
    this.cacheKey,

    required this.size,

    this.fit = BoxFit.cover,

    this.onLoaded,

    this.onError,
  });

  final String url;
  final String? cacheKey;

  final Size size;

  final BoxFit fit;

  final VoidCallback? onLoaded;

  final VoidCallback? onError;

  @override
  Widget build(BuildContext context) {
    if (_isLocalPath(url)) {
      return Image.file(
        File(url),

        width: size.width,

        height: size.height,

        fit: fit,

        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          final ready = wasSynchronouslyLoaded || frame != null;
          if (ready) onLoaded?.call();
          return _withLoadingPlaceholder(
            context,
            child: child,
            ready: ready,
            wasSynchronouslyLoaded: wasSynchronouslyLoaded,
          );
        },

        errorBuilder: (_, _, _) {
          onError?.call();

          return _placeholder();
        },
      );
    }

    if (_isNetworkTemporarilyBlocked(url)) {
      onError?.call();
      return _placeholder();
    }

    return Image(
      image: CachedNetworkImageProvider(url, cacheKey: cacheKey),
      width: size.width,
      height: size.height,
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final ready = wasSynchronouslyLoaded || frame != null;
        if (ready) {
          _clearNetworkFailure(url);
          onLoaded?.call();
        }
        return _withLoadingPlaceholder(
          context,
          child: child,
          ready: ready,
          wasSynchronouslyLoaded: wasSynchronouslyLoaded,
        );
      },
      errorBuilder: (_, _, _) {
        _rememberNetworkFailure(url);
        onError?.call();
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: size.width,

      height: size.height,

      color: ImColors.bgActive,

      alignment: Alignment.center,

      child: Icon(Icons.broken_image_outlined, color: ImColors.textLighter),
    );
  }

  Widget _withLoadingPlaceholder(
    BuildContext context, {
    required Widget child,
    required bool ready,
    required bool wasSynchronouslyLoaded,
  }) {
    if (wasSynchronouslyLoaded) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        _loadingPlaceholder(),
        AnimatedOpacity(
          opacity: ready ? 1 : 0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: child,
        ),
      ],
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: size.width,
      height: size.height,
      color: const Color(0xFFF4F6FA),
    );
  }

  static bool _isLocalPath(String url) {
    if (url.startsWith('file:')) return true;

    if (url.startsWith('/')) return true;

    return url.length > 1 && url[1] == ':';
  }

  static bool _isNetworkTemporarilyBlocked(String url) {
    return NetworkImageFailCache.isTemporarilyBlocked(url);
  }

  static void _rememberNetworkFailure(String url) {
    NetworkImageFailCache.markFailed(url);
  }

  static void _clearNetworkFailure(String url) {
    NetworkImageFailCache.markSucceeded(url);
  }
}
