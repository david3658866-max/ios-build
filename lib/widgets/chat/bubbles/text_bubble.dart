import 'package:flutter/material.dart';

import '../../../core/enums/message_status.dart';
import '../../../core/enums/message_type.dart';
import '../../../core/storage/app_database.dart';
import '../../../core/utils/group_sender_util.dart';
import '../../../core/utils/date_util.dart';
import '../../../core/utils/message_long_press_util.dart';
import '../../../core/utils/quote_message_util.dart';
import '../../../theme/im_colors.dart';
import '../../../theme/rpx.dart';
import '../chat_quote_message.dart';
import '../emotion_text.dart';
import '../chat_sender_name_row.dart';
import '../message_send_status.dart';

/// 文字气泡。对齐 chat-message-item.vue 文本消息 + design-tokens-chat-box。
class TextBubble extends StatelessWidget {
  const TextBubble({
    super.key,
    required this.message,
    required this.selfSend,
    this.senderName,
    this.senderRoles = const {},
    this.quoteShowName,
    this.onResend,
    this.onLongPress,
    this.onQuoteTap,
    this.onQuoteLongPress,
  });

  final Message message;
  final bool selfSend;
  final String? senderName;
  final Set<GroupSenderRole> senderRoles;
  final String? quoteShowName;
  final VoidCallback? onResend;
  final MessageLongPressCallback? onLongPress;
  final VoidCallback? onQuoteTap;
  final MessageLongPressCallback? onQuoteLongPress;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.tipTime) {
      return _TimeTip(time: message.sendTime);
    }
    if (message.type == MessageType.tipText ||
        message.status == MessageStatus.recall) {
      return _TimeTip(text: message.content ?? '');
    }

    final quote = QuoteMessageUtil.parse(message.quoteMessage);
    final textStyle = TextStyle(
      fontSize: rpx(context, 32),
      color: selfSend ? Colors.white : ImColors.text,
      height: 1.6,
    );

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (selfSend)
              MessageSendSideIcon(message: message, onResend: onResend),
            Flexible(
              child: Builder(
                builder: (context) {
                  final press = MessageLongPressCapture(onLongPress);
                  return GestureDetector(
                    onLongPressStart:
                        press.enabled ? press.onStart : null,
                    onLongPress:
                        press.enabled ? press.onTriggered : null,
                    child: _BubbleBody(
                  selfSend: selfSend,
                  quote: quote,
                  quoteShowName: quoteShowName,
                  message: message,
                  textStyle: textStyle,
                  onQuoteTap: onQuoteTap,
                  onQuoteLongPress: onQuoteLongPress,
                ),
                  );
                },
              ),
            ),
            if (!selfSend)
              MessageSendSideIcon(message: message, onResend: onResend),
          ],
        ),
        if (showPrivateReadLabel(message, selfSend))
          MessagePrivateReadLabel(message: message),
        ],
      );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.selfSend,
    required this.quote,
    required this.quoteShowName,
    required this.message,
    required this.textStyle,
    this.onQuoteTap,
    this.onQuoteLongPress,
  });

  final bool selfSend;
  final dynamic quote;
  final String? quoteShowName;
  final Message message;
  final TextStyle textStyle;
  final VoidCallback? onQuoteTap;
  final MessageLongPressCallback? onQuoteLongPress;

  @override
  Widget build(BuildContext context) {
    final radius = rpx(context, 20);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            rpx(context, selfSend ? 16 : 20),
            rpx(context, 16),
            rpx(context, selfSend ? 20 : 16),
            rpx(context, 16),
          ),
          decoration: BoxDecoration(
            color: selfSend ? ImColors.bubbleMine : Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quote != null)
                ChatQuoteMessage(
                  quote: quote,
                  showName: quoteShowName ?? '',
                  selfSend: selfSend,
                  onTap: onQuoteTap,
                  onLongPress: onQuoteLongPress,
                ),
              EmotionText(
                text: message.content ?? '',
                style: textStyle,
              ),
            ],
          ),
        ),
        Positioned(
          top: rpx(context, 20),
          left: selfSend ? null : -rpx(context, 10),
          right: selfSend ? -rpx(context, 10) : null,
          child: CustomPaint(
            painter: _BubbleTailPainter(
              color: selfSend ? ImColors.bubbleMine : Colors.white,
              pointLeft: !selfSend,
            ),
            size: Size(rpx(context, 12), rpx(context, 12)),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  _BubbleTailPainter({required this.color, required this.pointLeft});

  final Color color;
  final bool pointLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.color != color ||       oldDelegate.pointLeft != pointLeft;
}

class _TimeTip extends StatelessWidget {
  const _TimeTip({this.time, this.text});

  final int? time;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final label = text ?? DateUtil.formatBubbleTime(time);
    return Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: rpx(context, 26),
        color: ImColors.textLighter,
        // 对齐 uniapp .message-tip line-height: 60rpx，允许多行完整展示
        height: 60 / 26,
      ),
    );
  }
}
