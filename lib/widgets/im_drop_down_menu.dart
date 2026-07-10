import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 下拉菜单项。对齐 drop-down-menu.vue items。
class ImDropDownMenuItem {
  const ImDropDownMenuItem({
    required this.key,
    required this.name,
    this.icon,
  });

  final String key;
  final String name;
  final IconData? icon;
}

/// 右上角下拉菜单。对齐 drop-down-menu.vue（top:0 right:20rpx 相对 tab-page）。
abstract final class ImDropDownMenu {
  ImDropDownMenu._();

  static Future<String?> show(
    BuildContext context, {
    required List<ImDropDownMenuItem> items,
  }) {
    final mq = MediaQuery.of(context);
    // tab-page 顶部 = 状态栏 + 导航栏高度（对齐 App.vue .tab-page top）
    final top = mq.padding.top + kToolbarHeight;
    final right = rpx(context, 20);
    return showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: top,
              right: right,
              child: Material(
                color: Colors.white,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(rpx(context, 16)),
                child: Container(
                  constraints: BoxConstraints(minWidth: rpx(context, 220)),
                  padding: EdgeInsets.symmetric(vertical: rpx(context, 12)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(rpx(context, 16)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final item in items)
                        InkWell(
                          onTap: () => Navigator.pop(ctx, item.key),
                          child: SizedBox(
                            height: rpx(context, 96),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: rpx(context, 32),
                              ),
                              child: Row(
                                children: [
                                  if (item.icon != null) ...[
                                    Icon(
                                      item.icon,
                                      size: rpx(context, 36),
                                      color: ImColors.text,
                                    ),
                                    SizedBox(width: rpx(context, 20)),
                                  ],
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: rpx(context, 30),
                                      fontWeight: FontWeight.w500,
                                      color: ImColors.text,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
