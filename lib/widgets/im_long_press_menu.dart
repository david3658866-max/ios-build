import 'package:flutter/material.dart';

import '../core/utils/long_press_menu_util.dart';
import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 长按菜单项。对齐 long-press-menu.vue items。
class ImLongPressMenuItem {
  const ImLongPressMenuItem({
    required this.key,
    required this.name,
    this.danger = false,
    this.icon,
  });

  final String key;
  final String name;
  final bool danger;
  final IconData? icon;
}

/// 触点弹出菜单。对齐 long-press-menu.vue（fixed + 内容宽收缩）。
abstract final class ImLongPressMenu {
  ImLongPressMenu._();

  static Future<String?> show(
    BuildContext context, {
    required Offset anchor,
    required List<ImLongPressMenuItem> items,
  }) {
    if (items.isEmpty) return Future.value(null);

    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '关闭长按菜单',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => _ImLongPressMenuOverlay(
        anchor: anchor,
        items: items,
      ),
    );
  }
}

class _ImLongPressMenuOverlay extends StatefulWidget {
  const _ImLongPressMenuOverlay({
    required this.anchor,
    required this.items,
  });

  final Offset anchor;
  final List<ImLongPressMenuItem> items;

  @override
  State<_ImLongPressMenuOverlay> createState() =>
      _ImLongPressMenuOverlayState();
}

class _ImLongPressMenuOverlayState extends State<_ImLongPressMenuOverlay> {
  final _menuKey = GlobalKey();
  Offset? _topLeft;
  bool _refined = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refinePosition());
  }

  void _refinePosition() {
    if (!mounted) return;
    final box = _menuKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refinePosition());
      return;
    }
    final mq = MediaQuery.of(context);
    final refined = computeLongPressMenuTopLeft(
      touch: widget.anchor,
      menuSize: box.size,
      windowSize: mq.size,
      padding: mq.padding,
    );
    setState(() {
      _topLeft = refined;
      _refined = true;
    });
  }

  Offset _initialTopLeft(MediaQueryData mq) {
    return computeLongPressMenuTopLeft(
      touch: widget.anchor,
      menuSize: estimateLongPressMenuSize(
        mq.size.width,
        widget.items.length,
      ),
      windowSize: mq.size,
      padding: mq.padding,
    );
  }

  void _pop(String? value) {
    if (mounted) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topLeft = _topLeft ?? _initialTopLeft(mq);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => _pop(null),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          Positioned(
            left: topLeft.dx,
            top: topLeft.dy,
            child: AnimatedOpacity(
              opacity: _refined ? 1 : 0.92,
              duration: const Duration(milliseconds: 16),
              child: _MenuPanel(
                menuKey: _menuKey,
                items: widget.items,
                onSelect: _pop,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  const _MenuPanel({
    required this.menuKey,
    required this.items,
    required this.onSelect,
  });

  final GlobalKey menuKey;
  final List<ImLongPressMenuItem> items;
  final void Function(String key) onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: menuKey,
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(rpx(context, 16)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(minWidth: rpx(context, 200)),
        padding: EdgeInsets.symmetric(vertical: rpx(context, 8)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rpx(context, 16)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                InkWell(
                  onTap: () => onSelect(item.key),
                  child: SizedBox(
                    height: rpx(context, 88),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: rpx(context, 32),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.icon != null) ...[
                            Icon(
                              item.icon,
                              size: rpx(context, 36),
                              color: item.danger
                                  ? ImColors.danger
                                  : ImColors.text,
                            ),
                            SizedBox(width: rpx(context, 20)),
                          ],
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: rpx(context, 30),
                              fontWeight: FontWeight.w500,
                              color: item.danger
                                  ? ImColors.danger
                                  : ImColors.text,
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
    );
  }
}
