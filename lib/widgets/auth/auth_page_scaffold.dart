import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_constants.dart';
import '../../core/di/app_providers.dart';
import '../../core/utils/line_switch_util.dart';
import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';
import '../im_toast.dart';
import '../line_switcher.dart';
import '../line_switcher_panel.dart';
import 'auth_hero.dart';
import 'auth_sheet.dart';

/// 登录/注册页共用骨架：Hero + Sheet + 右上角线路切换。
class AuthPageScaffold extends ConsumerStatefulWidget {
  const AuthPageScaffold({
    super.key,
    required this.heroTitle,
    required this.child,
    this.heroSubtitle = '',
  });

  final String heroTitle;
  final String heroSubtitle;
  final Widget child;

  @override
  ConsumerState<AuthPageScaffold> createState() => _AuthPageScaffoldState();
}

class _AuthPageScaffoldState extends ConsumerState<AuthPageScaffold> {
  @override
  void initState() {
    super.initState();
    // 登录/注册页：并发探活全部线路，不通则自动切到最快可用线。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_probeAuthLines());
    });
  }

  Future<void> _probeAuthLines() async {
    if (!mounted) return;
    final fromId = ref.read(lineProvider).id;
    final ok = await ref
        .read(lineProvider.notifier)
        .checkCurrentLineStatus(allowFallback: true);
    if (!mounted) return;
    final line = ref.read(lineProvider);
    if (!ok) {
      ImToast.show(context, LineSwitchUtil.allLinesFailedToast);
    } else if (line.id != fromId) {
      ImToast.show(context, LineSwitchUtil.autoSwitchToast(line.name));
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AuthColors.pageBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(bottom: keyboard + rpx(context, 24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHero(
                  brandName: AppConstants.appName,
                  title: widget.heroTitle,
                  subtitle: widget.heroSubtitle,
                ),
                AuthSheet(child: widget.child),
              ],
            ),
          ),
          Positioned(
            top: top + 8,
            right: 16,
            child: const LineSwitcher(panelAlign: LinePanelAlign.right),
          ),
        ],
      ),
    );
  }
}
