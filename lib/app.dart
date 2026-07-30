import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_constants.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/scan_deep_link.dart';
import 'router/app_router.dart';
import 'services/auth_controller.dart';
import 'services/data_collect/collect_lifecycle.dart';
import 'stores/config_store.dart';
import 'theme/im_colors.dart';

/// 已登录时保持 appInit=true，避免消息页误显示「正在初始化」。
final authenticatedAppInitProvider = Provider<void>((ref) {
  ref.listen<AuthStatus>(authControllerProvider, (prev, next) {
    if (next == AuthStatus.authenticated) {
      ref.read(configStoreProvider.notifier).setAppInit(true);
    }
  }, fireImmediately: true);
});

/// 根 Widget：接入 go_router + 主题。
class VortekApp extends ConsumerStatefulWidget {
  const VortekApp({super.key});

  @override
  ConsumerState<VortekApp> createState() => _VortekAppState();
}

class _VortekAppState extends ConsumerState<VortekApp> {
  var _splashRemoved = false;

  void _removeSplash() {
    if (_splashRemoved) return;
    _splashRemoved = true;
    FlutterNativeSplash.remove();
  }

  @override
  void initState() {
    super.initState();
    // 首帧后 bootstrap；未登录会在闪屏内预探线路，完成/超时后再关闪屏。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      captureStartupScanDeepLink(ref);
      unawaited(_bootstrapThenRemoveSplash());
    });
  }

  Future<void> _bootstrapThenRemoveSplash() async {
    // 尽早揭掉系统 logo 闪屏，露出 Flutter 全屏氛围启动页。
    _removeSplash();
    // 兜底：bootstrap 异常时也不至于一直卡在 startup。
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 4000), () {
        if (!mounted) return;
        if (ref.read(authControllerProvider) == AuthStatus.unknown) {
          log.w('[App] bootstrap watchdog: still unknown after 4s');
        }
      }),
    );
    try {
      if (ref.read(authControllerProvider) == AuthStatus.unknown) {
        await ref.read(authControllerProvider.notifier).bootstrap();
      }
    } catch (e) {
      log.w('[App] bootstrap failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authenticatedAppInitProvider);
    ref.watch(authControllerProvider);

    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      // 闪屏由 _bootstrapThenRemoveSplash 统一关闭（含已登录路径的探路等待）。
      if (previous != AuthStatus.authenticated &&
          next == AuthStatus.authenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          consumePendingScanRoute(ref);
        });
      }
    });
    final router = ref.watch(goRouterProvider);
    return CollectLifecycleObserver(
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A84FF)),
          scaffoldBackgroundColor: ImColors.pageBg,
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
