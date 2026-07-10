import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 消息长按回调（带全局触点）。对齐 long-press-menu.vue。
typedef MessageLongPressCallback = void Function(Offset globalPosition);

/// 在 [GestureDetector] 中捕获长按触点。
class MessageLongPressCapture {
  MessageLongPressCapture(this._callback);

  final MessageLongPressCallback? _callback;
  Offset? _anchor;

  bool get enabled => _callback != null;

  void onStart(LongPressStartDetails details) {
    _anchor = details.globalPosition;
  }

  void onTriggered() {
    _callback?.call(_anchor ?? Offset.zero);
  }
}

/// 为消息气泡包一层长按触点捕获。
Widget wrapMessageLongPress(
  Widget child,
  MessageLongPressCallback? onLongPress,
) {
  final press = MessageLongPressCapture(onLongPress);
  if (!press.enabled) return child;
  return GestureDetector(
    onLongPressStart: press.onStart,
    onLongPress: press.onTriggered,
    behavior: HitTestBehavior.deferToChild,
    child: child,
  );
}
