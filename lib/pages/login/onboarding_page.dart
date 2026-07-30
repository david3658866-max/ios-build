import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/di/app_providers.dart';
import '../../router/app_router.dart';
import '../../theme/auth_colors.dart';

/// 首次安装引导：两页介绍图 → 进入登录（无跳过）。
/// 进入本页即启动线路预探，利用翻页时间完成探路 / 拉配置。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const _pages = <String>[
    'assets/onboarding/onboarding_1.webp',
    'assets/onboarding/onboarding_2.webp',
  ];

  final _controller = PageController();
  var _index = 0;
  var _entering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(lineProvider.notifier).warmupAuthLines());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishToLogin() async {
    if (_entering) return;
    setState(() => _entering = true);
    try {
      try {
        await ref
            .read(lineProvider.notifier)
            .warmupAuthLines()
            .timeout(const Duration(milliseconds: 1500));
      } on TimeoutException {
        // 进登录后可继续补探。
      }
      final kv = ref.read(kvStoreProvider);
      await kv.setHasSeenOnboarding(true);
      // 再次写入安装时间，避免仅标记 seen 时与重装判定脱节。
      try {
        final pkg = await PackageInfo.fromPlatform();
        final installMs = pkg.installTime?.millisecondsSinceEpoch ?? 0;
        await kv.syncOnboardingForInstall(installMs);
      } catch (_) {}
      if (!mounted) return;
      GoRouter.of(context).go(AppRoutes.login);
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  Future<void> _onPrimary() async {
    if (_entering) return;
    if (_index < _pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    await _finishToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index >= _pages.length - 1;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AuthColors.heroStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              return Image.asset(
                _pages[i],
                fit: BoxFit.cover,
                alignment: Alignment.center,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Container(
                  color: AuthColors.heroMid,
                  alignment: Alignment.center,
                  child: const Text(
                    '星语',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          // 底部渐变，保证指示点与按钮可读，不挡主文案区。
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220 + bottomInset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AuthColors.heroStart.withValues(alpha: 0.55),
                      AuthColors.heroStart.withValues(alpha: 0.92),
                    ],
                    stops: const [0, 0.35, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final on = i == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: on ? 18 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: on ? 0.95 : 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AuthColors.buttonGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: _entering ? null : _onPrimary,
                            child: Center(
                              child: _entering
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      last ? '进入' : '下一步',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
