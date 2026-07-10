import 'package:flutter/material.dart';

import '../../core/utils/emotion_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'emotion_image.dart';

/// 工具/表情面板默认高度（px）。对齐 uniapp `chatPanelHeight = 290`。
const kChatPanelHeight = 290.0;

/// 表情选择面板。对齐 uniapp `.chat-emotion` + `.emotion-item-list`（flex 换行，非固定 4 列）。
class ChatEmotionPanel extends StatelessWidget {
  const ChatEmotionPanel({
    super.key,
    required this.onSelect,
  });

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final iconSize = rpx(context, 64);
    final itemPad = rpx(context, 5);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ImColors.pageBg,
        border: Border(top: BorderSide(color: ImColors.borderLight)),
      ),
      child: SizedBox(
        height: kChatPanelHeight + bottom,
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              rpx(context, 40),
              rpx(context, 40),
              rpx(context, 40),
              rpx(context, 40) + bottom,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cell = iconSize + itemPad * 2;
                final cols =
                    (constraints.maxWidth / cell).floor().clamp(1, 32);
                return Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: itemPad,
                  children: [
                    for (final word in EmotionUtil.emoTextList)
                      SizedBox(
                        width: constraints.maxWidth / cols,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onSelect(word),
                            child: Padding(
                              padding: EdgeInsets.all(itemPad),
                              child: Center(
                                child: EmotionImage(
                                  word: word,
                                  size: iconSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
