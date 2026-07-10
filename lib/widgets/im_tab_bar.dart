import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// Tab 项定义。
class ImTabItem {
  const ImTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String icon;
  final String activeIcon;
}

/// 底部 TabBar。对应 pages.json tabBar（PNG 图标 + #3e45d7 选中色）。
class ImTabBar extends StatelessWidget {
  const ImTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.badgeCounts = const [0, 0],
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ImTabItem> items;

  /// [消息 Tab 角标, 通讯录 Tab 角标]。
  final List<int> badgeCounts;

  static const defaultItems = [
    ImTabItem(
      label: '消息',
      icon: 'assets/tabbar/chat.png',
      activeIcon: 'assets/tabbar/chat_active.png',
    ),
    ImTabItem(
      label: '好友',
      icon: 'assets/tabbar/friend.png',
      activeIcon: 'assets/tabbar/friend_active.png',
    ),
    ImTabItem(
      label: '我的',
      icon: 'assets/tabbar/mine.png',
      activeIcon: 'assets/tabbar/mine_active.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ImColors.tabBarBg,
        border: Border(top: BorderSide(color: ImColors.borderLight)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: rpx(context, 100),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _TabButton(
                    item: items[i],
                    selected: i == currentIndex,
                    badgeCount: i < badgeCounts.length ? badgeCounts[i] : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  final ImTabItem item;
  final bool selected;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? ImColors.tabSelected : ImColors.tabUnselected;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  selected ? item.activeIcon : item.icon,
                  width: rpx(context, 48),
                  height: rpx(context, 48),
                  fit: BoxFit.contain,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -rpx(context, 8),
                    top: -rpx(context, 6),
                    child: _TabBadge(count: badgeCount),
                  ),
              ],
            ),
            SizedBox(height: rpx(context, 4)),
            Text(
              item.label,
              style: TextStyle(
                fontSize: rpx(context, 22),
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, count > 9 ? 8 : 10),
        vertical: rpx(context, 2),
      ),
      constraints: BoxConstraints(minWidth: rpx(context, 32)),
      decoration: BoxDecoration(
        color: ImColors.danger,
        borderRadius: BorderRadius.circular(rpx(context, 20)),
        border: Border.all(color: ImColors.tabBarBg, width: rpx(context, 2)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: rpx(context, 18),
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}
