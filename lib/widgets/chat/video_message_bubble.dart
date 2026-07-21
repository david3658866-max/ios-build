import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_providers.dart';
import '../../core/enums/message_status.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/file_download_util.dart';
import '../../core/utils/group_sender_util.dart';
import '../../router/app_router.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'chat_sender_name_row.dart';
import 'message_send_status.dart';

/// 视频消息气泡。对齐 chat-message-item.vue `.message-video`（MVP：封面+播放图标）。
class VideoMessageBubble extends ConsumerWidget {
  const VideoMessageBubble({
    super.key,
    required this.message,
    required this.selfSend,
    this.senderName,
    this.senderRoles = const {},
    this.onResend,
    this.onLongPress,
  });

  final Message message;
  final bool selfSend;
  final String? senderName;
  final Set<GroupSenderRole> senderRoles;
  final VoidCallback? onResend;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = _parse(message.content);
    final apiBase = ref.read(lineProvider).baseUrl;
    final token = ref.read(kvStoreProvider).accessToken;
    final fileId = content['fileId']?.toString();
    final preferDirect = content['useDirectMedia'] == true;
    final cover = FileDownloadUtil.toAuthedMediaUrl(
      apiBaseUrl: apiBase,
      accessToken: token,
      fileId: fileId,
      fileUrl: content['coverUrl']?.toString(),
      role: 'cover',
      preferDirect: preferDirect,
    );
    final videoUrl = FileDownloadUtil.toAuthedMediaUrl(
      apiBaseUrl: apiBase,
      accessToken: token,
      fileId: fileId,
      fileUrl: content['videoUrl']?.toString(),
      role: 'origin',
      preferDirect: preferDirect,
    );
    final tile = rpx(context, 240);

    return Column(
      crossAxisAlignment:
          selfSend ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ?chatSenderNameLine(
          context,
          selfSend: selfSend,
          name: senderName,
          roles: senderRoles,
        ),
        Row(
          mainAxisAlignment:
              selfSend ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (selfSend)
              MessageSendSideIcon(
                message: message,
                onResend: onResend,
                showSendingSpinner: false,
              ),
            Flexible(
              child: GestureDetector(
                onTap: () => _openVideo(context, videoUrl, cover),
                onLongPress: onLongPress,
                child: Container(
                  width: tile,
                  height: tile,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(rpx(context, 10)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover.isNotEmpty)
                        Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(),
                        ),
                      Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: rpx(context, 80),
                        ),
                      ),
                      if (message.status == MessageStatus.sending)
                        const MessageMediaSendingOverlay(),
                    ],
                  ),
                ),
              ),
            ),
            if (!selfSend) SizedBox(width: rpx(context, 8)),
          ],
        ),
        if (showPrivateReadLabel(message, selfSend))
          MessagePrivateReadLabel(message: message),
      ],
    );
  }

  Map<String, dynamic> _parse(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  Future<void> _openVideo(BuildContext context, String url, String cover) async {
    if (url.isEmpty) return;
    context.push(AppRoutes.chatVideoPath(url, poster: cover));
  }
}
