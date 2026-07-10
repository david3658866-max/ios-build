import 'package:flutter/material.dart';

import '../../theme/rpx.dart';

/// CSS 电脑插画。对应 qr-login-confirm.vue .computer-icon。
class QrComputerIllustration extends StatelessWidget {
  const QrComputerIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    final screenW = rpx(context, 220);
    final screenH = rpx(context, 160);
    return Column(
      children: [
        Container(
          width: screenW,
          height: screenH,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
            ),
            borderRadius: BorderRadius.circular(rpx(context, 16)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: rpx(context, 32),
                offset: Offset(0, rpx(context, 12)),
              ),
            ],
          ),
          padding: EdgeInsets.all(rpx(context, 16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Dot(color: const Color(0xFFFF5F57), size: rpx(context, 12)),
                  SizedBox(width: rpx(context, 8)),
                  _Dot(color: const Color(0xFFFFBD2E), size: rpx(context, 12)),
                  SizedBox(width: rpx(context, 8)),
                  _Dot(color: const Color(0xFF28CA42), size: rpx(context, 12)),
                ],
              ),
              SizedBox(height: rpx(context, 20)),
              _FormLine(width: double.infinity, height: rpx(context, 8)),
              SizedBox(height: rpx(context, 12)),
              _FormLine(width: screenW * 0.6, height: rpx(context, 8)),
              SizedBox(height: rpx(context, 12)),
              _FormLine(width: double.infinity, height: rpx(context, 8)),
            ],
          ),
        ),
        SizedBox(height: rpx(context, 12)),
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: rpx(context, 280),
              height: rpx(context, 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(rpx(context, 24)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: rpx(context, 16),
                    offset: Offset(0, rpx(context, 6)),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -rpx(context, 8),
              child: Container(
                width: rpx(context, 40),
                height: rpx(context, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(rpx(context, 4)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _FormLine extends StatelessWidget {
  const _FormLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFC7D2FE),
        borderRadius: BorderRadius.circular(rpx(context, 4)),
      ),
    );
  }
}
