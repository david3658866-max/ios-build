import 'package:flutter/material.dart';

import 'im_toast.dart';

/// 全局轻量反馈。Toast 对齐 uniapp `uni.showToast`。
abstract final class ImFeedback {
  static void toast(BuildContext context, String message) {
    ImToast.show(context, message);
  }
}
