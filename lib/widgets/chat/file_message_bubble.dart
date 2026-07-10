import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/enums/message_status.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/group_sender_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/im_icons.dart';
import '../../theme/rpx.dart';
import 'chat_sender_name_row.dart';
import 'message_send_status.dart';

/// 文件消息气泡。对齐 chat-message-item.vue `.message-file`。
class FileMessageBubble extends StatelessWidget {
  const FileMessageBubble({
    super.key,
    required this.message,
    required this.selfSend,
    this.senderName,
    this.senderRoles = const {},
    this.onResend,
    this.onLongPress,
    this.onTap,
    this.downloadProgress,
  });

  final Message message;
  final bool selfSend;
  final String? senderName;
  final Set<GroupSenderRole> senderRoles;
  final VoidCallback? onResend;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  /// 0–100；非 null 表示下载中。对齐 `.download-progress`。
  final int? downloadProgress;

  @override
  Widget build(BuildContext context) {
    final content = _parse(message.content);
    final name = content['name']?.toString() ?? '文件';
    final size = (content['size'] as num?)?.toInt() ?? 0;
    final sending = message.status == MessageStatus.sending;
    final downloading = downloadProgress != null;

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
                onTap: onTap,
                onLongPress: onLongPress,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: rpx(context, 520),
                    minHeight: rpx(context, 120),
                  ),
                  padding: EdgeInsets.all(rpx(context, 30)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(rpx(context, 20)),
                    boxShadow: ImColors.cardBoxShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        ImIcons.file,
                        color: const Color(0xFFD42E07),
                        size: rpx(context, 80),
                      ),
                      SizedBox(width: rpx(context, 16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: rpx(context, 28),
                                fontWeight: FontWeight.w600,
                                color: ImColors.text,
                              ),
                            ),
                            SizedBox(height: rpx(context, 30)),
                            Wrap(
                              spacing: rpx(context, 12),
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _formatSize(size),
                                  style: TextStyle(
                                    fontSize: rpx(context, 24),
                                    color: ImColors.textLighter,
                                  ),
                                ),
                                if (downloading)
                                  Text(
                                    '$downloadProgress%',
                                    style: TextStyle(
                                      fontSize: rpx(context, 24),
                                      color: ImColors.textLighter,
                                    ),
                                  )
                                else if (sending)
                                  Text(
                                    '发送中...',
                                    style: TextStyle(
                                      fontSize: rpx(context, 24),
                                      color: ImColors.textLighter,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (downloading) ...[
                        SizedBox(width: rpx(context, 12)),
                        SizedBox(
                          width: rpx(context, 36),
                          height: rpx(context, 36),
                          child: CircularProgressIndicator(
                            strokeWidth: rpx(context, 3),
                            color: const Color(0xFF4A90E2),
                          ),
                        ),
                      ],
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

  String _formatSize(int size) {
    if (size > 1024 * 1024) return '${(size / 1024 / 1024).round()}M';
    if (size > 1024) return '${(size / 1024).round()}KB';
    return '${size}B';
  }
}
