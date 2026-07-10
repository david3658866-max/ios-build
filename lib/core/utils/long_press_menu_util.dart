import 'dart:ui';

import 'package:flutter/material.dart' show EdgeInsets;

/// 长按菜单定位。对齐 long-press-menu.vue `open()`。
///
/// uniapp 用 `position:fixed` + top/left 或 bottom/right，菜单宽度随内容收缩。
/// Flutter 的 [Positioned] 若只设 bottom/right 会把子组件撑满象限，故统一换算为 top/left。
Offset computeLongPressMenuTopLeft({
  required Offset touch,
  required Size menuSize,
  required Size windowSize,
  EdgeInsets padding = EdgeInsets.zero,
  double gap = 20,
}) {
  final belowCenter = touch.dy <= windowSize.height / 2;
  final rightHalf = touch.dx > windowSize.width / 2;

  var top = belowCenter ? touch.dy + gap : touch.dy - gap - menuSize.height;
  var left = rightHalf ? touch.dx - menuSize.width : touch.dx;

  final minLeft = padding.left + 8;
  final maxLeft = windowSize.width - padding.right - menuSize.width - 8;
  final minTop = padding.top + 8;
  final maxTop =
      windowSize.height - padding.bottom - menuSize.height - 8;

  if (maxLeft >= minLeft) {
    left = left.clamp(minLeft, maxLeft);
  }
  if (maxTop >= minTop) {
    top = top.clamp(minTop, maxTop);
  }

  return Offset(left, top);
}

/// 按屏宽 rpx 估算菜单尺寸（首帧定位，减少跳动）。
Size estimateLongPressMenuSize(double screenWidth, int itemCount) {
  double rpx(num v) => v * screenWidth / 750;
  return Size(
    rpx(280),
    rpx(8) * 2 + rpx(88) * itemCount,
  );
}
