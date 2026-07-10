import 'package:flutter/material.dart';

import '../../models/friend.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../chat/head_image.dart';

/// 好友列表项。对齐 im-uniapp components/friend-item/friend-item.vue。
class FriendItem extends StatelessWidget {
  const FriendItem({
    super.key,
    required this.friend,
    this.onTap,
    this.trailing,
  });

  final Friend friend;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(rpx(context, 20));
    return Padding(
      padding: EdgeInsets.only(bottom: rpx(context, 2)),
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: ImColors.bgActive,
          splashColor: ImColors.bgActive.withValues(alpha: 0.5),
          highlightColor: ImColors.bgActive,
          child: SizedBox(
            height: rpx(context, 120),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                rpx(context, 20),
                rpx(context, 10),
                rpx(context, 40),
                rpx(context, 10),
              ),
              child: Row(
                children: [
                  HeadImage(
                    url: friend.headImage,
                    name: friend.showNickName,
                    size: 84,
                    online: friend.online,
                  ),
                  SizedBox(width: rpx(context, 20)),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            friend.showNickName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: rpx(context, 34),
                              color: ImColors.text,
                            ),
                          ),
                        ),
                        if (friend.companyName != null &&
                            friend.companyName!.isNotEmpty)
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(left: rpx(context, 3)),
                              child: Text(
                                '@${friend.companyName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: rpx(context, 28),
                                  color: ImColors.companyTag,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
