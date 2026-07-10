import 'package:flutter/material.dart';

/// 渲染 im-uniapp iconfont 图标。
class ImIcon extends StatelessWidget {
  const ImIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
    );
  }
}
