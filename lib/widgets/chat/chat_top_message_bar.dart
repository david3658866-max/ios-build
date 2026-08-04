import 'package:flutter/material.dart';

import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 置顶消息条（私聊/群聊共用）。对齐 chat-top-message.vue。
class ChatTopMessageBar extends StatelessWidget {
  const ChatTopMessageBar({
    super.key,
    required this.preview,
    required this.onLocate,
    required this.onClose,
  });

  final String preview;
  final VoidCallback onLocate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        rpx(context, 16),
        rpx(context, 8),
        rpx(context, 16),
        0,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, 20),
        vertical: rpx(context, 16),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDEEEFD),
        borderRadius: BorderRadius.circular(rpx(context, 20)),
      ),
      child: Row(
        children: [
          Icon(Icons.push_pin, size: rpx(context, 40), color: ImColors.accent),
          SizedBox(width: rpx(context, 10)),
          Expanded(
            child: GestureDetector(
              onTap: onLocate,
              child: Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: rpx(context, 28),
                  color: ImColors.textLight,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: rpx(context, 40),
              color: ImColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
