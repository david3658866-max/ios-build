import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../core/http/api_result.dart';
import '../core/utils/chat_media_util.dart';
import '../services/diagnostics/ui_breadcrumb.dart';
import 'im_feedback.dart';

/// 全屏预览图片。可选底部「保存到相册」。对齐 uniapp `uni.previewImage` + 保存。
Future<void> showNetworkImagePreview(
  BuildContext context,
  String? url, {
  String? cacheKey,
  bool enableSave = false,
}) async {
  final imageUrl = url?.trim();
  if (imageUrl == null || imageUrl.isEmpty) return;
  if (NetworkImageFailCache.isTemporarilyBlocked(imageUrl)) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => _ImagePreviewDialog(
      url: imageUrl,
      cacheKey: cacheKey,
      enableSave: enableSave,
    ),
  );
}

class _ImagePreviewDialog extends StatefulWidget {
  const _ImagePreviewDialog({
    required this.url,
    this.cacheKey,
    required this.enableSave,
  });

  final String url;
  final String? cacheKey;
  final bool enableSave;

  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> {
  bool _saving = false;

  bool get _isLocal =>
      !widget.url.startsWith('http://') && !widget.url.startsWith('https://');

  Future<void> _saveToAlbum() async {
    if (_saving) return;
    UiBreadcrumb.add('image_save_album');
    setState(() => _saving = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          if (mounted) ImFeedback.toast(context, '未获得相册权限');
          return;
        }
      }

      if (_isLocal) {
        final file = File(widget.url);
        if (!await file.exists()) {
          if (mounted) ImFeedback.toast(context, '本地图片不存在');
          return;
        }
        await Gal.putImage(widget.url);
      } else {
        final resp = await Dio().get<List<int>>(
          widget.url,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
        final bytes = resp.data;
        if (bytes == null || bytes.isEmpty) {
          if (mounted) ImFeedback.toast(context, '图片下载失败');
          return;
        }
        final name = 'im_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Gal.putImageBytes(Uint8List.fromList(bytes), name: name);
      }
      if (mounted) ImFeedback.toast(context, '已保存到相册');
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, '保存失败: ${asApiException(e).message}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: _buildImage(
                    width: size.width,
                    height: size.height * 0.85,
                  ),
                ),
              ),
            ),
          ),
          if (widget.enableSave)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: Center(
                child: SafeArea(
                  top: false,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xE63A3A3C),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _saving ? null : _saveToAlbum,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _saving ? '保存中...' : '保存到相册',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage({required double width, required double height}) {
    if (_isLocal) {
      return Image.file(
        File(widget.url),
        fit: BoxFit.contain,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        ),
      );
    }

    return Image(
      image: CachedNetworkImageProvider(
        widget.url,
        cacheKey: widget.cacheKey,
      ),
      fit: BoxFit.contain,
      width: width,
      height: height,
      frameBuilder: (context, child, frame, syncLoaded) {
        if (syncLoaded || frame != null) {
          NetworkImageFailCache.markSucceeded(widget.url);
        }
        return child;
      },
      errorBuilder: (_, _, _) {
        NetworkImageFailCache.markFailed(widget.url);
        return const Icon(
          Icons.broken_image_outlined,
          color: Colors.white54,
          size: 64,
        );
      },
    );
  }
}
