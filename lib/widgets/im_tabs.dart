import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 简易 Tab 切换。对齐 uniapp components/tabs/tabs.vue。
class ImTabs extends StatelessWidget {
  const ImTabs({
    super.key,
    required this.items,
    required this.current,
    required this.onChanged,
  });

  final List<String> items;
  final int current;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: rpx(context, 16)),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: i == current
                          ? ImColors.accent
                          : Colors.transparent,
                      width: rpx(context, 4),
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  items[i],
                  style: TextStyle(
                    fontSize: rpx(context, 28),
                    color: i == current ? ImColors.accent : ImColors.textLight,
                    fontWeight:
                        i == current ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
