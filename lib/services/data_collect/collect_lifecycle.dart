import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/app_providers.dart';
import '../auth_controller.dart';
import '../diagnostics/session_exit_tracker.dart';
import 'data_collect_handler.dart';

/// App 回前台时同步 pending 采集任务（对齐旧版 app.dart lifecycle）。
/// 同时维护会话退出标记（供下次启动上报异常退出）。
class CollectLifecycleObserver extends ConsumerStatefulWidget {
  const CollectLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CollectLifecycleObserver> createState() =>
      _CollectLifecycleObserverState();
}

class _CollectLifecycleObserverState extends ConsumerState<CollectLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(SessionExitTracker.markActive());
        if (ref.read(authControllerProvider) == AuthStatus.authenticated) {
          unawaited(
            ref
                .read(dataCollectHandlerProvider)
                .syncPendingTasks(reason: 'app-resumed'),
          );
          // 轻量静默探：预热候选线，无 Toast / 不切线。
          unawaited(ref.read(lineProvider.notifier).silentProbeOnResume());
        }
        break;
      // inactive 在 iOS 权限弹窗时也会触发，不能标成 background，否则权限闪退会被误判为正常退出。
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(SessionExitTracker.markBackground());
        break;
      case AppLifecycleState.detached:
        unawaited(SessionExitTracker.markDetached());
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
