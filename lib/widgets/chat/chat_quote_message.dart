import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/enums/message_status.dart';
import '../../core/enums/message_type.dart';
import '../../core/utils/message_long_press_util.dart';
import '../../core/utils/quote_message_util.dart';
import '../../models/quote_message.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'emotion_text.dart';

/// 气泡内引用块。对齐 chat-quote-message.vue。
class ChatQuoteMessage extends StatelessWidget {
  const ChatQuoteMessage({
    super.key,
    required this.quote,
    required this.showName,
    this.selfSend = false,
    this.onTap,
    this.onLongPress,
  });

  final QuoteMessage quote;
  final String showName;
  final bool selfSend;
  final VoidCallback? onTap;
  final MessageLongPressCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final recalled = quote.status == MessageStatus.recall;
    final labelStyle = TextStyle(
      fontSize: rpx(context, 24),
      color: selfSend ? Colors.white70 : ImColors.textLighter,
      height: 1.4,
    );
    final press = MessageLongPressCapture(onLongPress);

    return GestureDetector(
      onTap: onTap,
      onLongPressStart: press.enabled ? press.onStart : null,
      onLongPress: press.enabled ? press.onTriggered : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(top: rpx(context, 8)),
        padding: EdgeInsets.all(rpx(context, 12)),
        decoration: BoxDecoration(
          color: selfSend
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(rpx(context, 20)),
        ),
        child: recalled
            ? Text(quote.content ?? '消息已撤回', style: labelStyle)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$showName:',
                    style: labelStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: rpx(context, 12)),
                  Flexible(child: _quoteBody(context, labelStyle)),
                ],
              ),
      ),
    );
  }

  Widget _quoteBody(BuildContext context, TextStyle style) {
    switch (quote.type) {
      case MessageType.image:
        return _thumbImage(context, 'thumbUrl');
      case MessageType.video:
        return _thumbImage(context, 'coverUrl');
      case MessageType.text:
        return EmotionText(
          text: quote.content ?? '',
          style: style,
          emojiSize: rpx(context, 36),
        );
      default:
        return Text(
          QuoteMessageUtil.previewOfQuote(quote, showName).replaceFirst('$showName: ', ''),
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
    }
  }

  Widget _thumbImage(BuildContext context, String key) {
    String? url;
    try {
      final map = jsonDecode(quote.content ?? '{}');
      if (map is Map) url = map[key]?.toString();
    } catch (_) {}
    if (url == null || url.isEmpty) {
      return Text('[图片]', style: TextStyle(fontSize: rpx(context, 24)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(rpx(context, 4)),
      child: Image.network(
        url,
        width: rpx(context, 100),
        height: rpx(context, 80),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => SizedBox(
          width: rpx(context, 100),
          height: rpx(context, 80),
          child: Icon(Icons.image, size: rpx(context, 40)),
        ),
      ),
    );
  }
}
