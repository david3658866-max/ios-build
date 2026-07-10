import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 底部主按钮。对齐 uniapp `.bottom-btn`。
class ImPrimaryButton extends StatelessWidget {
  const ImPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        rpx(context, 24),
        rpx(context, 48),
        rpx(context, 24),
        rpx(context, 24),
      ),
      child: SizedBox(
        width: double.infinity,
        height: rpx(context, 88),
        child: Material(
          color: onPressed == null || loading
              ? ImColors.accent.withValues(alpha: 0.5)
              : ImColors.accent,
          borderRadius: BorderRadius.circular(rpx(context, 8)),
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(rpx(context, 8)),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: rpx(context, 36),
                      height: rpx(context, 36),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: rpx(context, 32),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
