import 'package:flutter/material.dart';

import '../../core/storage/app_database.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 群回执消息已读人数。对齐 chat-message-item `.chat-receipt`。
class ChatReceiptBadge extends StatelessWidget {
  const ChatReceiptBadge({
    super.key,
    required this.message,
    required this.onTap,
  });

  final Message message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!message.receipt) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(top: rpx(context, 4)),
        child: message.receiptOk
            ? Icon(
                Icons.check_circle,
                size: rpx(context, 32),
                color: ImColors.success,
              )
            : Text(
                '${message.readedCount}人已读',
                style: TextStyle(
                  fontSize: rpx(context, 24),
                  color: ImColors.textLighter,
                ),
              ),
      ),
    );
  }
}
