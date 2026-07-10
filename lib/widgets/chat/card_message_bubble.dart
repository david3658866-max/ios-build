import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/enums/message_status.dart';
import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/group_sender_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'chat_sender_name_row.dart';
import 'head_image.dart';

/// 个人/群名片消息气泡。对齐 chat-message-item.vue `.message-card`。
class CardMessageBubble extends StatelessWidget {
  const CardMessageBubble({
    super.key,
    required this.message,
    required this.selfSend,
    this.senderName,
    this.senderRoles = const {},
    this.onResend,
    this.onLongPress,
    this.onTap,
  });

  final Message message;
  final bool selfSend;
  final String? senderName;
  final Set<GroupSenderRole> senderRoles;
  final VoidCallback? onResend;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  static const _expireMs = 7 * 24 * 3600 * 1000;

  @override
  Widget build(BuildContext context) {
    final data = _parse(message.content);
    final isUser = message.type == MessageType.userCard;
    final isGroup = message.type == MessageType.groupCard;
    final displayName = isUser
        ? data['nickName']?.toString()
        : data['groupName']?.toString();
    final avatarUrl = data['headImage']?.toString();
    final footer = isUser ? '个人名片' : '群名片';
    final expired = isGroup && _isExpired(message.sendTime);

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
              if (selfSend) _StatusIcon(message: message, onResend: onResend),
              GestureDetector(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Container(
                  width: rpx(context, 320),
                  height: rpx(context, 160),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(rpx(context, 10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: rpx(context, 8),
                        offset: Offset(0, rpx(context, 2)),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: rpx(context, 20),
                          ),
                          child: Row(
                            children: [
                              HeadImage(
                                url: avatarUrl,
                                name: displayName,
                                size: 80,
                              ),
                              SizedBox(width: rpx(context, 20)),
                              Expanded(
                                child: Text(
                                  displayName ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: rpx(context, 30),
                                    fontWeight: FontWeight.w600,
                                    color: ImColors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: rpx(context, 1),
                        color: ImColors.formDivider,
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: rpx(context, 20),
                          vertical: rpx(context, 10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              footer,
                              style: TextStyle(
                                fontSize: rpx(context, 24),
                                color: ImColors.textLight,
                              ),
                            ),
                            if (expired) ...[
                              const Spacer(),
                              Text(
                                '已过期',
                                style: TextStyle(
                                  fontSize: rpx(context, 22),
                                  color: ImColors.danger,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!selfSend) SizedBox(width: rpx(context, 8)),
            ],
          ),
        ],
    );
  }

  static bool isGroupCardExpired(int? sendTimeMs) {
    if (sendTimeMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch - sendTimeMs > _expireMs;
  }

  bool _isExpired(int? sendTimeMs) => isGroupCardExpired(sendTimeMs);

  Map<String, dynamic> _parse(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.message, this.onResend});

  final Message message;
  final VoidCallback? onResend;

  @override
  Widget build(BuildContext context) {
    if (message.status == MessageStatus.sending) {
      return Padding(
        padding: EdgeInsets.only(right: rpx(context, 8)),
        child: SizedBox(
          width: rpx(context, 32),
          height: rpx(context, 32),
          child: CircularProgressIndicator(
            strokeWidth: rpx(context, 3),
            color: ImColors.bubbleMine,
          ),
        ),
      );
    }
    if (message.status == MessageStatus.failed) {
      return GestureDetector(
        onTap: onResend,
        child: Padding(
          padding: EdgeInsets.only(right: rpx(context, 8)),
          child: Icon(
            Icons.error_outline,
            color: ImColors.sendFail,
            size: rpx(context, 50),
          ),
        ),
      );
    }
    return SizedBox(width: rpx(context, 8));
  }
}
