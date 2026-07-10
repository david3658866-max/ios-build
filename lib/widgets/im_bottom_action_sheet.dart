import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 底部操作项。对齐 uniapp `popup-menu.vue` items。
class ImBottomActionItem<T> {
  const ImBottomActionItem({required this.label, required this.value});

  final String label;
  final T value;
}

/// 底部弹出菜单。对齐 uniapp `popup-menu`（圆角顶栏 + 取消）。
Future<T?> showImBottomActionSheet<T>(
  BuildContext context, {
  required List<ImBottomActionItem<T>> items,
  String cancelLabel = '取消',
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ImBottomActionSheetBody<T>(
      items: items,
      cancelLabel: cancelLabel,
    ),
  );
}

class _ImBottomActionSheetBody<T> extends StatelessWidget {
  const _ImBottomActionSheetBody({
    required this.items,
    required this.cancelLabel,
  });

  final List<ImBottomActionItem<T>> items;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          rpx(context, 16),
          0,
          rpx(context, 16),
          rpx(context, 16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(rpx(context, 15)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0)
                      Container(
                        height: 1,
                        color: const Color(0xFFEEEEEE),
                      ),
                    _ActionTile(
                      label: items[i].label,
                      onTap: () => Navigator.pop(context, items[i].value),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: rpx(context, 10)),
            ClipRRect(
              borderRadius: BorderRadius.circular(rpx(context, 15)),
              child: _ActionTile(
                label: cancelLabel,
                danger: true,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: rpx(context, 100),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: rpx(context, 32),
                color: danger ? ImColors.danger : ImColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
