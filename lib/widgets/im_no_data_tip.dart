import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 无数据提示。对齐 no-data-tip.vue。
class ImNoDataTip extends StatelessWidget {
  const ImNoDataTip({super.key, required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: rpx(context, 120),
            color: ImColors.textLighter.withValues(alpha: 0.5),
          ),
          SizedBox(height: rpx(context, 10)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rpx(context, 48)),
            child: Text(
              tip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rpx(context, 32),
                color: ImColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
