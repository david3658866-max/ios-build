import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 顶部导航栏。对应 im-uniapp components/nav-bar/nav-bar.vue。
class ImNavBar extends StatelessWidget implements PreferredSizeWidget {
  const ImNavBar({
    super.key,
    this.title,
    this.subTitle,
    this.titleAlign = TextAlign.center,
    this.showBack = false,
    this.leading,
    this.titleExtra,
    this.actions = const [],
    this.showSearch = false,
    this.onSearch,
    this.onTitleTap,
    this.onTitleLongPress,
    this.bottom,
  });

  final String? title;
  final String? subTitle;

  /// 对齐 nav-bar.vue `back` 属性。
  final bool showBack;

  /// [TextAlign.left] 对应 title-align="left"。
  final TextAlign titleAlign;
  final Widget? leading;
  final Widget? titleExtra;
  final List<Widget> actions;
  final bool showSearch;
  final VoidCallback? onSearch;
  final VoidCallback? onTitleTap;
  final VoidCallback? onTitleLongPress;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    final h = kToolbarHeight + (bottom?.preferredSize.height ?? 0);
    return Size.fromHeight(h);
  }

  Widget? _resolveLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!showBack) return null;
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new, size: rpx(context, 36)),
      color: ImColors.text,
      onPressed: () => context.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leftAlign = titleAlign == TextAlign.left;
    final resolvedLeading = _resolveLeading(context);
    return AppBar(
      backgroundColor: ImColors.navBarBg,
      foregroundColor: ImColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: !leftAlign,
      titleSpacing: leftAlign ? rpx(context, 30) : NavigationToolbar.kMiddleSpacing,
      leading: resolvedLeading,
      automaticallyImplyLeading: resolvedLeading != null,
      title: title == null
          ? null
          : _NavTitle(
              title: title!,
              subTitle: subTitle,
              leftAlign: leftAlign,
              titleExtra: titleExtra,
              onTap: onTitleTap,
              onLongPress: onTitleLongPress,
            ),
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            iconSize: rpx(context, 48),
            onPressed: onSearch,
          ),
        ...actions,
        SizedBox(width: rpx(context, 8)),
      ],
      bottom: bottom,
    );
  }
}

class _NavTitle extends StatelessWidget {
  const _NavTitle({
    required this.title,
    required this.leftAlign,
    this.subTitle,
    this.titleExtra,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String? subTitle;
  final bool leftAlign;
  final Widget? titleExtra;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasGesture = onTap != null || onLongPress != null;
    final content = Column(
      crossAxisAlignment:
          leftAlign ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: rpx(context, 34),
                fontWeight: FontWeight.w500,
                color: ImColors.text,
                letterSpacing: 0.5,
              ),
            ),
            if (titleExtra != null) ...[
              SizedBox(width: rpx(context, 12)),
              titleExtra!,
            ],
          ],
        ),
        if (subTitle != null && subTitle!.isNotEmpty)
          Text(
            subTitle!,
            style: TextStyle(
              fontSize: rpx(context, 26),
              color: ImColors.textLighter,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );

    if (!hasGesture) {
      return Align(
        alignment: leftAlign ? Alignment.centerLeft : Alignment.center,
        child: content,
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: kToolbarHeight,
        width: double.infinity,
        child: Align(
          alignment: leftAlign ? Alignment.centerLeft : Alignment.center,
          child: content,
        ),
      ),
    );
  }
}
