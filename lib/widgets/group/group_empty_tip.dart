import 'package:flutter/material.dart';

import '../im_primary_button.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 无群聊空状态。对齐 group.vue .group-tip。
class GroupEmptyTip extends StatelessWidget {
  const GroupEmptyTip({
    super.key,
    this.showCreateButton = false,
    this.onCreate,
  });

  /// 高级用户（userIdentity === 1）才显示创建按钮。
  final bool showCreateButton;
  final VoidCallback? onCreate;

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
                child: Icon(
                  Icons.groups_outlined,
                  size: rpx(context, 56),
                  color: const Color(0xFF6C757D).withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: rpx(context, 40)),
              Text(
                '还没有群聊',
                style: TextStyle(
                  fontSize: rpx(context, 34),
                  fontWeight: FontWeight.w500,
                  color: ImColors.text,
                ),
              ),
              SizedBox(height: rpx(context, 20)),
              Text(
                '创建或加入群聊，与朋友们一起畅聊吧',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rpx(context, 24),
                  color: ImColors.textLighter,
                  height: 1.6,
                ),
              ),
              if (showCreateButton) ...[
                SizedBox(height: rpx(context, 50)),
                SizedBox(
                  width: double.infinity,
                  child: ImPrimaryButton(
                    text: '创建群聊',
                    onPressed: onCreate,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
