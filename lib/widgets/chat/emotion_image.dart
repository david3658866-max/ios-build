import 'package:flutter/material.dart';

import '../../core/utils/emotion_util.dart';

/// 单个表情 gif。对齐 im-uniapp `.emoji-large|normal|small`。
class EmotionImage extends StatelessWidget {
  const EmotionImage({
    super.key,
    required this.word,
    required this.size,
    this.fallbackStyle,
  });

  final String word;
  final double size;
  final TextStyle? fallbackStyle;

  @override
  Widget build(BuildContext context) {
    final asset = EmotionUtil.assetPathForWord(word);
    if (asset == null) {
      return Text(
        EmotionUtil.wrap(word),
        style: fallbackStyle,
      );
    }
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Text(
        EmotionUtil.wrap(word),
        style: fallbackStyle,
      ),
    );
  }
}
