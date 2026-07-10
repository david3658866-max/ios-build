import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';

/// Auth 渐变胶囊按钮。对应 auth-page.scss .submit-btn。
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.topPadding = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// 找回密码等页按钮不需要 auth 页默认上边距。
  final bool topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding ? rpx(context, 48) : 0),
      child: SizedBox(
        width: double.infinity,
        height: rpx(context, 100),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: onPressed == null ? null : AuthColors.buttonGradient,
            color: onPressed == null ? AuthColors.accent.withValues(alpha: 0.5) : null,
            borderRadius: BorderRadius.circular(rpx(context, 50)),
            boxShadow: onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: AuthColors.accent.withValues(alpha: 0.35),
                      blurRadius: rpx(context, 32),
                      offset: Offset(0, rpx(context, 12)),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onPressed,
              borderRadius: BorderRadius.circular(rpx(context, 50)),
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
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: rpx(context, 34),
                          fontWeight: FontWeight.w600,
                          letterSpacing: rpx(context, 4),
                          decoration: TextDecoration.none,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部注册/登录链接。对应 .nav-tool-bar。
class AuthNavLink extends StatelessWidget {
  const AuthNavLink({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: rpx(context, 40)),
      child: Center(
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: rpx(context, 40),
              vertical: rpx(context, 16),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: rpx(context, 30),
              color: AuthColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
