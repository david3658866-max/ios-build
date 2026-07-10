import 'package:flutter/material.dart';

import '../../theme/im_colors.dart';
import '../../theme/im_icons.dart';
import '../../theme/rpx.dart';
import '../im_icon.dart';

/// 通讯录顶部固定项（新的朋友 / 我的群聊）。对齐 friend.vue .top-item。
class FriendTopItem extends StatelessWidget {
  const FriendTopItem({
    super.key,
    required this.title,
    this.leading,
    this.badgeCount = 0,
    this.onTap,
  });

  final String title;
  final Widget? leading;
  final int badgeCount;
  final VoidCallback? onTap;

  /// 「新的朋友」入口。
  factory FriendTopItem.newFriend({
    Key? key,
    int badgeCount = 0,
    VoidCallback? onTap,
  }) {
    return FriendTopItem(
      key: key,
      title: '新的朋友',
      badgeCount: badgeCount,
      onTap: onTap,
      leading: const _NewFriendAvatar(),
    );
  }

  /// 「我的群聊」入口。
  factory FriendTopItem.myGroups({
    Key? key,
    VoidCallback? onTap,
  }) {
    return FriendTopItem(
      key: key,
      title: '我的群聊',
      onTap: onTap,
      leading: const _GroupEntryAvatar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: rpx(context, 1)),
      child: Material(
        color: ImColors.navBarBg,
        child: InkWell(
          onTap: onTap,
          hoverColor: ImColors.bgActive,
          splashColor: ImColors.bgActive,
          highlightColor: ImColors.bgActive,
          child: SizedBox(
            height: rpx(context, 100),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                rpx(context, 20),
                rpx(context, 10),
                rpx(context, 10),
                rpx(context, 10),
              ),
              child: Row(
                children: [
                  leading ?? const SizedBox.shrink(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: rpx(context, 20)),
                      child: Row(
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: rpx(context, 30),
                              color: ImColors.text,
                            ),
                          ),
                          if (badgeCount > 0) ...[
                            SizedBox(width: rpx(context, 12)),
                            _FriendBadge(count: badgeCount),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewFriendAvatar extends StatelessWidget {
  const _NewFriendAvatar();

  static const _asset = 'assets/image/new_friend.png';

  @override
  Widget build(BuildContext context) {
    final size = rpx(context, 84);
    return ClipOval(
      child: Image.asset(
        _asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: const Color(0xFF5DAA31).withValues(alpha: 0.15),
          alignment: Alignment.center,
          child: ImIcon(
            ImIcons.addFriend,
            size: rpx(context, 44),
            color: const Color(0xFF5DAA31),
          ),
        ),
      ),
    );
  }
}

class _GroupEntryAvatar extends StatelessWidget {
  const _GroupEntryAvatar();

  @override
  Widget build(BuildContext context) {
    final size = rpx(context, 80);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: ImColors.groupEntryGradient,
      ),
      alignment: Alignment.center,
      child: ImIcon(
        ImIcons.createGroup,
        size: rpx(context, 40),
        color: Colors.white,
      ),
    );
  }
}

class _FriendBadge extends StatelessWidget {
  const _FriendBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, count > 9 ? 10 : 12),
        vertical: rpx(context, 2),
      ),
      constraints: BoxConstraints(minWidth: rpx(context, 36)),
      decoration: BoxDecoration(
        color: const Color(0xFFE54D42),
        borderRadius: BorderRadius.circular(rpx(context, 20)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: rpx(context, 22),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
