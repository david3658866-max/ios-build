import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../chat/head_image.dart';

/// 群成员列表行。对齐 group-member.vue `.member-item`（120rpx 行高）。
class GroupMemberItem extends StatelessWidget {
  const GroupMemberItem({
    super.key,
    required this.member,
    this.group,
    this.mineId,
    this.avatarSize = 96,
    this.trailing,
    this.onTap,
  });

  final GroupMember member;
  final Group? group;
  final int? mineId;
  final double avatarSize;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: rpx(context, 120),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: rpx(context, 30)),
            child: Row(
              children: [
                HeadImage(
                  url: member.headImage,
                  name: member.showNickName,
                  online: member.online,
                  size: avatarSize,
                ),
                SizedBox(width: rpx(context, 20)),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          member.showNickName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: rpx(context, 32),
                            color: ImColors.text,
                          ),
                        ),
                      ),
                      if (member.companyName != null &&
                          member.companyName!.isNotEmpty)
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(left: rpx(context, 3)),
                            child: Text(
                              '@${member.companyName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: rpx(context, 24),
                                color: ImColors.companyTag,
                              ),
                            ),
                          ),
                        ),
                      ..._buildTags(context),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTags(BuildContext context) {
    final tags = <Widget>[];
    final ownerId = group?.ownerId;
    if (ownerId != null && member.userId == ownerId) {
      tags.add(_MemberTag(text: '群主', color: ImColors.danger));
    }
    if (mineId != null && member.userId == mineId) {
      tags.add(_MemberTag(text: '我', color: ImColors.textLighter));
    }
    if (member.isManager) {
      tags.add(_MemberTag(text: '管理员', color: ImColors.accent));
    }
    if (member.isMuted) {
      tags.add(_MemberTag(text: '禁言中', color: ImColors.companyTag));
    }
    return tags
        .map((t) => Padding(padding: EdgeInsets.only(left: rpx(context, 8)), child: t))
        .toList();
  }
}

class _MemberTag extends StatelessWidget {
  const _MemberTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, 8),
        vertical: rpx(context, 2),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(rpx(context, 6)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: rpx(context, 22),
          color: color,
        ),
      ),
    );
  }
}
