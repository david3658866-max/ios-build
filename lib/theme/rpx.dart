import 'package:flutter/material.dart';

/// rpx 换算。uni-app 750rpx = 屏宽。
double rpx(BuildContext context, num value) {
  final w = MediaQuery.sizeOf(context).width;
  return value * w / 750;
}
