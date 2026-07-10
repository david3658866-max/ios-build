import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/enums/message_type.dart';
import '../../core/utils/date_util.dart';
import '../../core/storage/app_database.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'head_image.dart';

/// 聊天记录项。对齐 chat-history-item.vue。
class ChatHistoryItem extends StatelessWidget {
  const ChatHistoryItem({
    super.key,
    required this.headImage,
    required this.showName,
    required this.message,
    this.onTap,
    this.onAvatarTap,
  });

  final String? headImage;
  final String showName;
  final Message message;
  final VoidCallback? onTap;
  final VoidCallback? onAvatarTap;

  /// 对齐 uniapp `$date.toTimeText(sendTime, true)`。
  static String formatItemTime(int? ms) =>
      DateUtil.toTimeText(ms, simple: true);

  String _preview() {
    if (message.type == MessageType.text) {
      return message.content ?? '';
    }
    if (message.type == MessageType.file) {
      try {
        final map = jsonDecode(message.content ?? '{}');
        if (map is Map) {
          final name = map['name']?.toString() ?? '';
          return '[文件] $name';
        }
      } catch (_) {}
      return '[文件]';
    }
    return message.content ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = rpx(context, 84);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: ImColors.bgActive,
        highlightColor: ImColors.bgActive,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            rpx(context, 20),
            rpx(context, 15),
            rpx(context, 20),
            rpx(context, 15),
          ),
          margin: EdgeInsets.only(bottom: rpx(context, 3)),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.only(left: avatarSize + rpx(context, 26)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            showName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: rpx(context, 24),
                              height: 1,
                              color: ImColors.textLighter,
                            ),
                          ),
                        ),
                        Text(
                          formatItemTime(message.sendTime),
                          style: TextStyle(
                            fontSize: rpx(context, 24),
                            height: 1,
                            color: ImColors.textLighter,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: rpx(context, 5)),
                    Text(
                      _preview(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rpx(context, 32),
                        color: ImColors.text,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: GestureDetector(
                  onTap: onAvatarTap,
                  child: HeadImage(
                    url: headImage,
                    name: showName,
                    size: avatarSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
