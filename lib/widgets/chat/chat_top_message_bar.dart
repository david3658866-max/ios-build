import 'package:flutter/material.dart';

import '../../core/utils/quote_message_util.dart';
import '../../models/group.dart';
import '../../models/group_message.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 群置顶消息条。对齐 chat-top-message.vue。
class ChatTopMessageBar extends StatelessWidget {
  const ChatTopMessageBar({
    super.key,
    required this.group,
    required this.topMessage,
    required this.showName,
    required this.canManage,
    required this.onLocate,
    required this.onClose,
  });

  final Group group;
  final GroupMessage topMessage;
  final String showName;
  final bool canManage;
  final VoidCallback onLocate;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final preview = _preview(topMessage, showName);
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

  String _preview(GroupMessage msg, String name) {
    return QuoteMessageUtil.preview(
      showName: name,
      type: msg.type,
      content: msg.content,
      status: msg.status,
    );
  }
}
