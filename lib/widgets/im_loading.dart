import 'package:flutter/material.dart';

import '../theme/rpx.dart';

/// 全局 Loading 遮罩。对齐 uniapp `uni.showLoading` / `uni.hideLoading`。
abstract final class ImLoading {
  static int _refCount = 0;
  static OverlayEntry? _entry;

  static void show(BuildContext context, {String? title}) {
    _refCount++;
    if (_refCount > 1) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (ctx) => _ImLoadingOverlay(title: title),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    if (_refCount <= 0) return;
    _refCount--;
    if (_refCount > 0) return;
    _entry?.remove();
    _entry = null;
  }

  /// 测试/异常恢复用。
  static void reset() {
    _refCount = 0;
    _entry?.remove();
    _entry = null;
  }
}

class _ImLoadingOverlay extends StatelessWidget {
  const _ImLoadingOverlay({this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          color: Colors.black.withValues(alpha: 0.35),
          dismissible: false,
        ),
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: rpx(context, 40),
              vertical: rpx(context, 32),
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(rpx(context, 12)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: rpx(context, 48),
                  height: rpx(context, 48),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
                if (title != null && title!.isNotEmpty) ...[
                  SizedBox(height: rpx(context, 16)),
                  Text(
                    title!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: rpx(context, 28),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
