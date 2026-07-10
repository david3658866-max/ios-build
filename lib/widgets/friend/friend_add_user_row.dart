import 'package:flutter/material.dart';

import '../../core/utils/avatar_util.dart';
import '../../models/user.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../chat/head_image.dart';
import '../im_mini_button.dart';

/// 添加好友搜索结果行。对齐 friend-add.vue `.user-item`。
class FriendAddUserRow extends StatelessWidget {
  const FriendAddUserRow({
    super.key,
    required this.user,
    required this.searchText,
    required this.isFriend,
    required this.pending,
    required this.onTap,
    required this.onAdd,
  });

  final User user;
  final String searchText;
  final bool isFriend;
  final bool pending;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final lineInfo = searchText == user.phone
        ? '手机:${user.phone}'
        : (searchText == user.email
            ? '邮箱:${user.email}'
            : 'ID:${user.userName ?? ''}');

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: rpx(context, 100),
          margin: EdgeInsets.only(bottom: rpx(context, 1)),
          padding: EdgeInsets.symmetric(
            horizontal: rpx(context, 20),
            vertical: rpx(context, 18),
          ),
          child: Row(
            children: [
              HeadImage(
                url: AvatarUtil.pick(
                  thumb: user.headImageThumb,
                  origin: user.headImage,
                ),
                name: user.nickName,
                size: 84,
                online: user.online,
              ),
              SizedBox(width: rpx(context, 20)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.nickName ?? user.userName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: rpx(context, 32)),
                            ),
                          ),
                          if (user.companyName != null &&
                              user.companyName!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(left: rpx(context, 3)),
                              child: Text(
                                '@${user.companyName}',
                                style: TextStyle(
                                  fontSize: rpx(context, 28),
                                  color: ImColors.companyTag,
                                ),
                              ),
                            ),
                          if (user.status == 1) _miniTag(context, '已注销'),
                          if (user.isBanned) _miniTag(context, '已封禁'),
                        ],
                      ),
                      SizedBox(height: rpx(context, 8)),
                      Text(
                        lineInfo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: rpx(context, 28),
                          color: ImColors.textLighter,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isFriend)
                Text(
                  '已添加',
                  style: TextStyle(
                    fontSize: rpx(context, 30),
                    color: ImColors.textLighter,
                  ),
                )
              else if (pending)
                Text(
                  '等待对方验证',
                  style: TextStyle(
                    fontSize: rpx(context, 30),
                    color: ImColors.textLighter,
                  ),
                )
              else
                ImMiniButton(
                  text: '加为好友',
                  onPressed: onAdd,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniTag(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(left: rpx(context, 6)),
      child: Text(
        text,
        style: TextStyle(fontSize: rpx(context, 22), color: ImColors.danger),
      ),
    );
  }
}
