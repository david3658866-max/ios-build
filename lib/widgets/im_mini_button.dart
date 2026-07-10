import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// mini 按钮。对齐 uniapp button size="mini"。
class ImMiniButton extends StatelessWidget {
  const ImMiniButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.primary = true,
    this.warn = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool primary;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final bg = warn
        ? ImColors.danger
        : (primary ? ImColors.accent : ImColors.bgActive);
    final fg = primary || warn ? Colors.white : ImColors.text;

    return Material(
      color: onPressed == null ? bg.withValues(alpha: 0.5) : bg,
      borderRadius: BorderRadius.circular(rpx(context, 8)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(rpx(context, 8)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: rpx(context, 24),
            vertical: rpx(context, 8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: rpx(context, 24),
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
