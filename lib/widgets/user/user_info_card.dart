import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils/avatar_util.dart';
import '../../models/user.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../chat/head_image.dart';
import '../im_feedback.dart';

/// 用户信息卡片。对齐 user-info-card.vue。
class UserInfoCard extends StatelessWidget {
  const UserInfoCard({
    super.key,
    required this.user,
    this.onAvatarTap,
  });

  final User user;
  final VoidCallback? onAvatarTap;

  Future<void> _copyId(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: '${user.id}'));
    if (context.mounted) {
      ImFeedback.toast(context, "内容'${user.id}'已复制");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(rpx(context, 24)),
      padding: EdgeInsets.fromLTRB(
        rpx(context, 32),
        rpx(context, 40),
        rpx(context, 32),
        rpx(context, 40),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF3F4FF)],
        ),
        borderRadius: BorderRadius.circular(rpx(context, 24)),
        boxShadow: [
          BoxShadow(
            color: ImColors.accent.withValues(alpha: 0.08),
            blurRadius: rpx(context, 28),
            offset: Offset(0, rpx(context, 8)),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: rpx(context, 5)),
                boxShadow: [
                  BoxShadow(
                    color: ImColors.accent.withValues(alpha: 0.18),
                    blurRadius: rpx(context, 20),
                    offset: Offset(0, rpx(context, 8)),
                  ),
                ],
              ),
              child: HeadImage(
                url: AvatarUtil.pick(
                  thumb: user.headImageThumb,
                  origin: user.headImage,
                ),
                name: user.nickName,
                size: 160,
                online: user.online,
              ),
            ),
          ),
          SizedBox(width: rpx(context, 32)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.nickName ?? user.userName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: rpx(context, 34),
                          fontWeight: FontWeight.w600,
                          color: ImColors.text,
                        ),
                      ),
                    ),
                    if (user.sex == 0) ...[
                      SizedBox(width: rpx(context, 10)),
                      Icon(Icons.male, size: rpx(context, 28), color: ImColors.accent),
                    ] else if (user.sex == 1) ...[
                      SizedBox(width: rpx(context, 10)),
                      Icon(Icons.female, size: rpx(context, 28), color: ImColors.danger),
                    ],
                    if (user.status == 1) _tag(context, '已注销'),
                    if (user.isBanned) _tag(context, '已封禁'),
                  ],
                ),
                if (user.companyName != null && user.companyName!.isNotEmpty) ...[
                  SizedBox(height: rpx(context, 14)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: rpx(context, 18),
                      vertical: rpx(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: ImColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(rpx(context, 100)),
                    ),
                    child: Text(
                      '@${user.companyName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rpx(context, 24),
                        color: ImColors.accent,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: rpx(context, 14)),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    rpx(context, 20),
                    rpx(context, 6),
                    rpx(context, 8),
                    rpx(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: ImColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(rpx(context, 100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ID:',
                        style: TextStyle(
                          fontSize: rpx(context, 30),
                          color: ImColors.textLight,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          ' ${user.id}',
                          style: TextStyle(
                            fontSize: rpx(context, 30),
                            color: ImColors.textLight,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _copyId(context),
                        child: Container(
                          width: rpx(context, 40),
                          height: rpx(context, 40),
                          margin: EdgeInsets.only(left: rpx(context, 12)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ImColors.accent.withValues(alpha: 0.12),
                                blurRadius: rpx(context, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.copy,
                            size: rpx(context, 22),
                            color: ImColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: rpx(context, 14)),
                Text(
                  (user.signature != null && user.signature!.isNotEmpty)
                      ? user.signature!
                      : '这个人很懒，什么也没留下',
                  style: TextStyle(
                    fontSize: rpx(context, 30),
                    color: ImColors.textLighter,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(BuildContext context, String text) {
    return Container(
      margin: EdgeInsets.only(left: rpx(context, 8)),
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, 10),
        vertical: rpx(context, 2),
      ),
      decoration: BoxDecoration(
        color: ImColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(rpx(context, 6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: rpx(context, 22),
          color: ImColors.danger,
        ),
      ),
    );
  }
}
