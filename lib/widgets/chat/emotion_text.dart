import 'package:flutter/material.dart';

import '../../core/utils/emotion_util.dart';
import '../../theme/rpx.dart';
import 'emotion_image.dart';

/// 带表情 gif 的文本。对齐 uniapp `$emo.transform` + rich-text。
class EmotionText extends StatelessWidget {
  const EmotionText({
    super.key,
    required this.text,
    required this.style,
    this.emojiSize,
    this.emojiAlignment = PlaceholderAlignment.bottom,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final double? emojiSize;
  final PlaceholderAlignment emojiAlignment;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    if (!EmotionUtil.hasEmotion(text)) {
      return Text(text, style: style);
    }

    // im.scss `.emoji-normal` = 54rpx；消息气泡内表情尺寸。
    final size = emojiSize ?? rpx(context, 54);
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in EmotionUtil.pattern.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(text: text.substring(start, match.start), style: style),
        );
      }
      final word = match.group(1) ?? match.group(2);
      if (word == null) {
        spans.add(TextSpan(text: match.group(0), style: style));
      } else {
        spans.add(
          WidgetSpan(
            alignment: emojiAlignment,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: rpx(context, 1)),
              child: EmotionImage(
                word: word,
                size: size,
                fallbackStyle: style,
              ),
            ),
          ),
        );
      }
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
