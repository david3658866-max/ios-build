import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 底部 ActionSheet。对齐 uniapp `uni.showActionSheet`。
abstract final class ImActionSheet {
  ImActionSheet._();

  /// 返回被点击项的 index；取消返回 null。
  static Future<int?> show(
    BuildContext context, {
    required List<String> itemList,
  }) {
    if (itemList.isEmpty) return Future.value(null);
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final radius = BorderRadius.vertical(top: Radius.circular(rpx(ctx, 24)));
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              rpx(ctx, 16),
              0,
              rpx(ctx, 16),
              rpx(ctx, 16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: radius,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < itemList.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: ImColors.borderLight,
                          ),
                        InkWell(
                          onTap: () => Navigator.pop(ctx, i),
                          child: SizedBox(
                            width: double.infinity,
                            height: rpx(ctx, 112),
                            child: Center(
                              child: Text(
                                itemList[i],
                                style: TextStyle(
                                  fontSize: rpx(ctx, 32),
                                  color: ImColors.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: rpx(ctx, 12)),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(rpx(ctx, 24)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: SizedBox(
                      width: double.infinity,
                      height: rpx(ctx, 112),
                      child: Center(
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: rpx(ctx, 32),
                            fontWeight: FontWeight.w600,
                            color: ImColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
