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
    // 首帧后启动 bootstrap，并立刻关掉原生闪屏（避免卡在白屏）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _removeSplash();
      if (ref.read(authControllerProvider) == AuthStatus.unknown) {
        unawaited(ref.read(authControllerProvider.notifier).bootstrap());
      }
      captureStartupScanDeepLink(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authenticatedAppInitProvider);
    final auth = ref.watch(authControllerProvider);

    ref.listen<AuthStatus>(authControllerProvider, (previous, next) {
      _removeSplash();
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
