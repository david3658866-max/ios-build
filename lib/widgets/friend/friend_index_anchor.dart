import 'package:flutter/material.dart';

import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 好友索引分组标题。对齐 friend.vue up-index-anchor（在线好友 / A-Z）。
class FriendIndexAnchor extends StatelessWidget {
  const FriendIndexAnchor({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: rpx(context, 60),
      width: double.infinity,
      color: ImColors.pageBg,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 24)),
      child: Text(
        text,
        style: TextStyle(
          fontSize: rpx(context, 28),
          color: ImColors.text,
        ),
      ),
    );
  }
}
