import 'package:flutter/material.dart';

import '../../theme/im_icons.dart';
import '../im_icon.dart';
import '../im_primary_button.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 无好友空状态。对齐 friend.vue .friend-tip。
class FriendEmptyTip extends StatelessWidget {
  const FriendEmptyTip({
    super.key,
    required this.onAdd,
  });

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: rpx(context, 48)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: rpx(context, 500)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: rpx(context, 120),
                height: rpx(context, 120),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ImColors.emptyIconGradient,
                  border: Border.all(color: ImColors.bgActive, width: rpx(context, 2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: rpx(context, 12),
                      offset: Offset(0, rpx(context, 4)),
                    ),
                  ],
                ),
                child: ImIcon(
                  ImIcons.addFriend,
                  size: rpx(context, 56),
                  color: const Color(0xFF6C757D).withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: rpx(context, 40)),
              Text(
                '还没有好友',
                style: TextStyle(
                  fontSize: rpx(context, 34),
                  fontWeight: FontWeight.w500,
                  color: ImColors.text,
                ),
              ),
              SizedBox(height: rpx(context, 20)),
              Text(
                '添加好友，开始精彩的聊天之旅',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rpx(context, 28),
                  color: ImColors.textLighter,
                  height: 1.6,
                ),
              ),
              SizedBox(height: rpx(context, 50)),
              SizedBox(
                width: double.infinity,
                child: ImPrimaryButton(
                  text: '添加好友',
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
