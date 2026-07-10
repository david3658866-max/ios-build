import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';

/// Auth 白色浮层。对应 auth-page.scss .auth-sheet。
class AuthSheet extends StatelessWidget {
  const AuthSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -rpx(context, 64)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AuthColors.sheetGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(rpx(context, 48))),
          boxShadow: [
            BoxShadow(
              color: const Color(0x142B2F9C),
              blurRadius: rpx(context, 48),
              offset: Offset(0, -rpx(context, 12)),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          rpx(context, 48),
          rpx(context, 56),
          rpx(context, 48),
          rpx(context, 64),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: rpx(context, 20),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: rpx(context, 64),
                  height: rpx(context, 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(rpx(context, 6)),
                    gradient: const LinearGradient(
                      colors: [
                        AuthColors.accentSoft,
                        AuthColors.accent,
                        AuthColors.accentSoft,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
