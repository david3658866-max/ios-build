import 'package:flutter/material.dart';

import '../../core/enums/chat_type.dart';
import '../../core/enums/message_status.dart';
import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../theme/im_colors.dart';
import '../../theme/im_icons.dart';
import '../../theme/rpx.dart';

/// 是否展示私聊己方「已读/未读」。对齐 chat-message-item `.message-status`。
bool showPrivateReadLabel(Message message, bool selfSend) {
  if (!selfSend || message.chatType != ChatType.private) return false;
  if (MessageType.isAction(message.type)) return false;
  if (message.status == MessageStatus.recall) return false;
  return message.status != MessageStatus.sending &&
      message.status != MessageStatus.failed;
}

/// 私聊己方「已读/未读」标签。
class MessagePrivateReadLabel extends StatelessWidget {
  const MessagePrivateReadLabel({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final readed = message.status == MessageStatus.readed;
    return Padding(
      padding: EdgeInsets.only(top: rpx(context, 5)),
      child: Text(
        readed ? '已读' : '未读',
        style: TextStyle(
          fontSize: rpx(context, 26),
          color: readed ? ImColors.textLighter : ImColors.danger,
        ),
      ),
    );
  }
}

/// 气泡旁发送中/失败图标。
///
/// 对齐 uniapp：仅文字/语音在旁侧显示发送中转圈；失败时各类型均显示
/// `icon-warning-circle-fill`。
class MessageSendSideIcon extends StatelessWidget {
  const MessageSendSideIcon({
    super.key,
    required this.message,
    this.onResend,
    this.showSendingSpinner = true,
  });

  final Message message;
  final VoidCallback? onResend;

  /// 为 false 时图/文件/视频发送中不在旁侧显示转圈（遮罩内 dots 即可）。
  final bool showSendingSpinner;

  @override
  Widget build(BuildContext context) {
    if (message.status == MessageStatus.sending && showSendingSpinner) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
        child: SizedBox(
          width: rpx(context, 40),
          height: rpx(context, 40),
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
          padding: EdgeInsets.symmetric(horizontal: rpx(context, 5)),
          child: Icon(
            ImIcons.warningCircleFill,
            color: ImColors.sendFail,
            size: rpx(context, 50),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// 图/视频等媒体上的发送中遮罩。对齐 loading.vue `type="dots"` + mask。
class MessageMediaSendingOverlay extends StatefulWidget {
  const MessageMediaSendingOverlay({super.key});

  @override
  State<MessageMediaSendingOverlay> createState() =>
      _MessageMediaSendingOverlayState();
}

class _MessageMediaSendingOverlayState extends State<MessageMediaSendingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final phase = (_controller.value + index * 0.2) % 1.0;
                    final active = phase >= 0.2 && phase <= 0.6;
                    final scale = active ? 1.2 : 0.8;
                    final opacity = active ? 1.0 : 0.5;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: rpx(context, 6),
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: rpx(context, 16),
                            height: rpx(context, 16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEEEEEE),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
            SizedBox(height: rpx(context, 12)),
            Text(
              '上传中…',
              style: TextStyle(
                color: Colors.white,
                fontSize: rpx(context, 24),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
