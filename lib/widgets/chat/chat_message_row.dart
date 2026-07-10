import 'package:flutter/material.dart';

import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'head_image.dart';

/// 居中提示行（TIP_TIME / TIP_TEXT / 撤回），无头像。对齐 `.message-tip`。
class ChatMessageTipRow extends StatelessWidget {
  const ChatMessageTipRow({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        rpx(context, 20),
        rpx(context, 15),
        rpx(context, 20),
        rpx(context, 15),
      ),
      child: Center(child: child),
    );
  }
}

/// 单条消息行外层布局。对齐 chat-message-item.vue `.message-normal`。
class ChatMessageRow extends StatelessWidget {
  const ChatMessageRow({
    super.key,
    required this.selfSend,
    required this.child,
    this.headUrl,
    this.headName,
    this.highlighted = false,
    this.onHeadTap,
    this.onHeadLongPress,
  });

  final bool selfSend;
  final Widget child;
  final String? headUrl;
  final String? headName;
  final bool highlighted;
  final VoidCallback? onHeadTap;
  final VoidCallback? onHeadLongPress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        rpx(context, 20),
        rpx(context, 15),
        rpx(context, 20),
        rpx(context, 15),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: rpx(context, 80)),
        child: Align(
          alignment: selfSend ? Alignment.centerRight : Alignment.centerLeft,
          child: DecoratedBox(
            decoration: highlighted
                ? BoxDecoration(
                    color: ImColors.messageHighlightBg,
                    borderRadius: BorderRadius.circular(rpx(context, 20)),
                  )
                : const BoxDecoration(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: selfSend ? null : 0,
                  right: selfSend ? 0 : null,
                  child: GestureDetector(
                    onTap: onHeadTap,
                    onLongPress: onHeadLongPress,
                    child: HeadImage(
                      url: headUrl,
                      name: headName,
                      size: 84,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: selfSend ? 0 : rpx(context, 105),
                    right: selfSend ? rpx(context, 105) : 0,
                  ),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
