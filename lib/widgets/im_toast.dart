import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/rpx.dart';

/// 居中 Toast。对齐 uniapp `uni.showToast`（icon: none、屏幕居中）。
abstract final class ImToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static const Duration _defaultDuration = Duration(milliseconds: 1500);

  static void show(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
  }) {
    hide();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned.fill(
        child: IgnorePointer(
          child: Material(
            type: MaterialType.transparency,
            child: Center(
              child: _ImToastCard(message: message),
            ),
          ),
        ),
      ),
    );
    _entry = entry;

    void insert() {
      if (identical(_entry, entry)) {
        overlay.insert(entry);
      }
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      insert();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => insert());
    }

    _timer = Timer(duration, hide);
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ImToastCard extends StatelessWidget {
  const _ImToastCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: rpx(context, 560)),
      margin: EdgeInsets.symmetric(horizontal: rpx(context, 80)),
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, 32),
        vertical: rpx(context, 24),
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(rpx(context, 12)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: rpx(context, 30),
          height: 1.4,
        ),
      ),
    );
  }
}
