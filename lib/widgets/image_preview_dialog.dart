import 'package:flutter/material.dart';

import '../core/utils/chat_media_util.dart';

/// 全屏预览网络图片。对齐 uniapp `uni.previewImage`。
Future<void> showNetworkImagePreview(BuildContext context, String? url) async {
  final imageUrl = url?.trim();
  if (imageUrl == null || imageUrl.isEmpty) return;
  if (NetworkImageFailCache.isTemporarilyBlocked(imageUrl)) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: ColoredBox(
        color: Colors.transparent,
        child: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            width: MediaQuery.sizeOf(ctx).width * 0.9,
            height: MediaQuery.sizeOf(ctx).height * 0.8,
            frameBuilder: (context, child, frame, syncLoaded) {
              if (syncLoaded || frame != null) {
                NetworkImageFailCache.markSucceeded(imageUrl);
              }
              return child;
            },
            errorBuilder: (_, _, _) {
              NetworkImageFailCache.markFailed(imageUrl);
              return const Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: 64,
              );
            },
          ),
        ),
      ),
    ),
  );
}
