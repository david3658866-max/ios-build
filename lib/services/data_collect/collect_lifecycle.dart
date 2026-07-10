import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth_controller.dart';
import 'data_collect_handler.dart';

/// App 回前台时同步 pending 采集任务（对齐旧版 app.dart lifecycle）。
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
    if (state != AppLifecycleState.resumed) return;
    if (ref.read(authControllerProvider) != AuthStatus.authenticated) return;
    unawaited(
      ref
          .read(dataCollectHandlerProvider)
          .syncPendingTasks(reason: 'app-resumed'),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
