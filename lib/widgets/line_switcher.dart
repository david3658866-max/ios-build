import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../core/utils/line_switch_util.dart';
import '../core/ws/ws_event.dart';
import '../services/auth_controller.dart';
import '../stores/config_store.dart';
import '../theme/rpx.dart';
import 'im_toast.dart';
import 'line_auto_failover_offer.dart';
import 'line_switcher_panel.dart';

/// 线路切换 chip。对应 im-uniapp line-switcher.vue。
class LineSwitcher extends ConsumerStatefulWidget {
  const LineSwitcher({
    super.key,
    this.panelAlign = LinePanelAlign.left,
  });

  /// 下拉面板对齐 chip。登录页右上角用 [LinePanelAlign.right]。
  final LinePanelAlign panelAlign;

  @override
  ConsumerState<LineSwitcher> createState() => _LineSwitcherState();
}

class _LineSwitcherState extends ConsumerState<LineSwitcher> {
  final _chipKey = GlobalKey();
  bool _retrying = false;

  Future<void> _retryProbe() async {
    if (_retrying) return;
    ref.read(lineAutoFailoverProvider.notifier).cancel();
    setState(() => _retrying = true);
    ImToast.show(context, LineSwitchUtil.retryProbeToast);
    try {
      final ok = await ref
          .read(lineProvider.notifier)
          .checkCurrentLineStatus(allowFallback: true);
      if (!mounted) return;
      ImToast.show(
        context,
        ok
            ? LineSwitchUtil.retryProbeOkToast
            : LineSwitchUtil.retryProbeAllFailedToast,
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = ref.watch(lineProvider);
    final config = ref.watch(configStoreProvider);
    final failover = ref.watch(lineAutoFailoverProvider);
    final isAuthed =
        ref.watch(authControllerProvider) == AuthStatus.authenticated;
    final status = LineSwitchUtil.chipStatus(
      isAuthenticated: isAuthed,
      lineStatus: config.lineStatus,
      wsStatus: config.wsStatus,
    );
    final (bg, border, statusText, statusColor, showSpinner) = _style(status);
    final showRetry =
        status == WsStatus.disconnected && !_retrying && !failover.active;
    final countdownSec =
        status == WsStatus.disconnected && failover.active
            ? failover.secondsLeft
            : null;

    return GestureDetector(
      onTap: () {
        ref.read(lineAutoFailoverProvider.notifier).cancel();
        showLineSwitcherPanel(
          context,
          ref,
          anchorKey: _chipKey,
          align: widget.panelAlign,
        );
      },
      child: Semantics(
        button: true,
        label: [
          line.name,
          if (statusText.isNotEmpty) statusText,
          if (countdownSec != null)
            LineSwitchUtil.autoFailoverChipSeconds(countdownSec),
        ].join(' '),
        child: Container(
        key: _chipKey,
        padding: EdgeInsets.symmetric(
          horizontal: rpx(context, 16),
          vertical: rpx(context, 4),
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(rpx(context, 100)),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner || _retrying)
              Padding(
                padding: EdgeInsets.only(right: rpx(context, 8)),
                child: SizedBox(
                  width: rpx(context, 22),
                  height: rpx(context, 22),
                  child: CircularProgressIndicator(
                    strokeWidth: rpx(context, 3),
                    color: const Color(0xFFF3A73F),
                    backgroundColor: const Color(0x40F3A73F),
                  ),
                ),
              )
            else
              Container(
                width: rpx(context, 12),
                height: rpx(context, 12),
                margin: EdgeInsets.only(right: rpx(context, 8)),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: status == WsStatus.connected
                      ? const Color(0xFF3E45D7)
                      : (status == WsStatus.disconnected
                          ? const Color(0xFFE43D33)
                          : const Color(0xFF3E45D7)),
                ),
              ),
            Text(
              line.name,
              style: TextStyle(
                fontSize: rpx(context, 24),
                color: const Color(0xFF333333),
              ),
            ),
            if (statusText.isNotEmpty) ...[
              SizedBox(width: rpx(context, 4)),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: rpx(context, 22),
                  color: statusColor,
                ),
              ),
            ],
            if (countdownSec != null) ...[
              SizedBox(width: rpx(context, 4)),
              GestureDetector(
                onTap: () {
                  ref.read(lineAutoFailoverProvider.notifier).cancel();
                  ImToast.show(
                    context,
                    LineSwitchUtil.autoFailoverCancelledToast,
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Text(
                  LineSwitchUtil.autoFailoverChipSeconds(countdownSec),
                  style: TextStyle(
                    fontSize: rpx(context, 22),
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (showRetry) ...[
              SizedBox(width: rpx(context, 4)),
              GestureDetector(
                onTap: () {
                  unawaited(_retryProbe());
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  // 真机拇指热区至少约 44px，避免点刷新却打开面板。
                  padding: EdgeInsets.symmetric(
                    horizontal: rpx(context, 10),
                    vertical: rpx(context, 8),
                  ),
                  child: Icon(
                    Icons.refresh,
                    size: rpx(context, 28),
                    color: const Color(0xFFE43D33),
                  ),
                ),
              ),
            ],
            Icon(
              Icons.keyboard_arrow_down,
              size: rpx(context, 24),
              color: status == WsStatus.disconnected
                  ? const Color(0xFFE43D33)
                  : (showSpinner || _retrying
                      ? const Color(0xFFF3A73F)
                      : const Color(0xFF666666)),
            ),
          ],
        ),
      ),
      ),
    );
  }

  (Color, Color, String, Color, bool) _style(WsStatus status) {
    switch (status) {
      case WsStatus.connecting:
      case WsStatus.authing:
        return (
          const Color(0xFFFFF8ED),
          const Color(0x40F3A73F),
          '连接中',
          const Color(0xFFC8872B),
          true,
        );
      case WsStatus.disconnected:
        return (
          const Color(0xFFFFF5F5),
          const Color(0x33E43D33),
          '连接失败',
          const Color(0xFFE43D33),
          false,
        );
      case WsStatus.connected:
        return (
          const Color(0xFFF5F6F8),
          const Color(0x0F000000),
          '',
          Colors.transparent,
          false,
        );
    }
  }
}
