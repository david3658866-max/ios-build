import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';

/// Auth Hero 区。对应 auth-page.scss .auth-hero。
class AuthHero extends StatelessWidget {
  const AuthHero({
    super.key,
    required this.brandName,
    required this.title,
    this.subtitle = '',
  });

  final String brandName;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: rpx(context, 500)),
      padding: EdgeInsets.fromLTRB(
        rpx(context, 56),
        topPad + rpx(context, 88),
        rpx(context, 56),
        rpx(context, 100),
      ),
      decoration: const BoxDecoration(gradient: AuthColors.heroGradient),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: rpx(context, -100),
            right: rpx(context, -80),
            child: _DecorCircle(size: rpx(context, 400), opacity: 0.12),
          ),
          Positioned(
            bottom: rpx(context, -140),
            left: rpx(context, -100),
            child: _DecorCircle(
              size: rpx(context, 340),
              opacity: 0.22,
              color: const Color(0xFF969AEB),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: rpx(context, 112),
                height: rpx(context, 112),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(rpx(context, 28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: rpx(context, 24),
                      offset: Offset(0, rpx(context, 8)),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(rpx(context, 28)),
                  child: Image.asset(
                    'assets/image/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: rpx(context, 20)),
              Text(
                brandName,
                style: TextStyle(
                  fontSize: rpx(context, 64),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: rpx(context, 10),
                  height: 1.2,
                  shadows: const [
                    Shadow(
                      color: Color(0x4D2B2F9C),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              SizedBox(height: rpx(context, 16)),
              Text(
                title,
                style: TextStyle(
                  fontSize: rpx(context, 36),
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.96),
                  letterSpacing: rpx(context, 2),
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: rpx(context, 10)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: rpx(context, 26),
                    color: const Color.fromRGBO(224, 235, 255, 0.92),
                    letterSpacing: rpx(context, 1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({
    required this.size,
    required this.opacity,
    this.color = Colors.white,
  });

  final double size;
  final double opacity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: opacity), Colors.transparent],
          stops: const [0, 0.68],
        ),
      ),
    );
  }
}
