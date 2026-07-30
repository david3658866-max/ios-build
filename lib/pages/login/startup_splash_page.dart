import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';

/// Cold-start atmospheric splash (full-bleed), covers system logo splash.
/// Shown only while AuthStatus.unknown; router leaves after bootstrap.
class StartupSplashPage extends StatelessWidget {
  const StartupSplashPage({super.key});

  static const assetPath = 'assets/image/app_splash_screen.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthColors.heroStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: const BoxDecoration(gradient: AuthColors.heroGradient),
              alignment: Alignment.center,
              child: const Text(
                '星语',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
