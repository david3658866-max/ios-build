import 'package:characters/characters.dart';
import 'package:flutter/material.dart';

import '../../core/utils/emotion_util.dart';
import '../../theme/rpx.dart';
import 'emotion_image.dart';

/// 输入框内联渲染表情 gif。对齐 uniapp editor `insertImage` + `emoji-small`。
class EmotionTextEditingController extends TextEditingController {
  EmotionTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final displayStyle = style ?? const TextStyle();
    if (!value.composing.isValid || !withComposing) {
      return _buildSpan(context, value.text, displayStyle);
    }

    final composingStyle = displayStyle.merge(
      const TextStyle(decoration: TextDecoration.underline),
    );
    return TextSpan(
      style: displayStyle,
      children: <InlineSpan>[
        _buildSpan(
          context,
          value.composing.textBefore(value.text),
          displayStyle,
        ),
        TextSpan(
          style: composingStyle,
          text: value.composing.textInside(value.text),
        ),
        _buildSpan(
          context,
          value.composing.textAfter(value.text),
          displayStyle,
        ),
      ],
    );
  }

  TextSpan _buildSpan(BuildContext context, String text, TextStyle style) {
    if (text.isEmpty) {
      return TextSpan(text: '', style: style);
    }
    if (!EmotionUtil.containsInputToken(text) && !EmotionUtil.hasEmotion(text)) {
      return TextSpan(text: text, style: style);
    }

    // im.scss `.emoji-small` = 36rpx
    final emojiSize = rpx(context, 36);
    final spans = <InlineSpan>[];
    for (final char in text.characters) {
      final word = EmotionUtil.wordFromInputToken(char);
      if (word != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: EmotionImage(
              word: word,
              size: emojiSize,
              fallbackStyle: style,
            ),
          ),
        );
        continue;
      }
      spans.add(TextSpan(text: char, style: style));
    }
    return TextSpan(children: spans, style: style);
  }
}
