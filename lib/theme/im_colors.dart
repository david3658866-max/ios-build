import 'package:flutter/material.dart';

/// IM 主界面色板。来源 im-uniapp im-var.scss + pages.json tabBar。
abstract final class ImColors {
  static const pageBg = Color(0xFFEEF0F5);
  static const accent = Color(0xFF3E45D7);
  static const accentLight = Color(0xFF6E73E1);
  /// chat-record.vue 波形渐变。对应 `$im-color-primary-light-1/6`。
  static const accentWaveLight = Color(0xFFECEDFB);
  static const accentWaveDark = Color(0xFF8B90E7);
  static const navBarBg = Color(0xFFFFFFFF);
  static const text = Color(0xFF333333);
  static const textLight = Color(0xFF6A6A6A);
  static const textLighter = Color(0xFF909399);
  static const border = Color(0xFFEDEDED);
  /// 表单/列表内缩分隔线。对应 im-var `$im-border` #F0F0F0。
  static const formDivider = Color(0xFFF0F0F0);
  static const borderLight = Color(0xFFF0F0F0);
  static const bgActive = Color(0xFFF7F8FC);
  /// @我 / @全体成员、未读角标。对应 im-uniapp $im-color-danger。
  static const danger = Color(0xFFE43D33);
  /// 回执已确认。对应 im-uniapp $im-color-success。
  static const success = Color(0xFF18BC37);
  static const tabUnselected = Color(0xFF000000);
  static const tabSelected = accent;
  static const tabBarBg = Color(0xFFFFFFFF);

  static const mineHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );

  /// 公司标签色。对应 im-uniapp .company-tag-mini。
  static const companyTag = Color(0xFFFA9D3B);

  /// 群聊入口头像渐变。对应 friend.vue .top-item-avatar。
  static const groupEntryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6EB5FF), accent],
  );

  /// 空状态图标圆底渐变。对应 chat.vue / friend.vue .tip-icon。
  static const emptyIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
  );

  /// 置顶角标叠加渐变。对应 chat-item .chat-top（225deg 白→黑叠于 primary）。
  static const topCornerGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0x80FFFFFF), Color(0x99000000)],
    stops: [0.25, 1.0],
  );

  // --- chat-box（design-tokens-chat-box.md）---

  /// 消息滚动区背景 `.chat-msg`。
  static const msgAreaBg = Color(0xFFF6F8FA);

  /// 己方文字气泡 `$im-color-primary-light-2`。
  static const bubbleMine = Color(0xFF656ADF);

  /// 图片气泡描边 `$im-color-primary-light-5`（primary 与 white 各 50%）。
  static const bubbleImageBorder = Color(0xFF9FA2EB);

  /// 发送失败图标 `#e60c0c`。
  static const sendFail = Color(0xFFE60C0C);

  /// 输入框边框 H5 `#e8e8ef`。
  static const inputBorder = Color(0xFFE8E8EF);

  /// send-bar 图标 `rgba(0,0,0,0.8)`。
  static const sendBarIcon = Color(0xCC000000);

  /// send-bar 引用条背景 `#eee`。
  static const quotePreviewBg = Color(0xFFEEEEEE);

  /// 引用清除图标 `#888`。
  static const quoteRemoveIcon = Color(0xFF888888);

  /// 开关开启轨道色。对齐 uniapp 原生 switch / iOS 系统绿。
  static const switchOn = Color(0xFF34C759);

  /// 开关关闭轨道色。
  static const switchOff = Color(0xFFE9E9EA);

  /// 消息定位高亮 `$im-color-primary-light-9` ≈ `#ececfb`。
  static const messageHighlightBg = Color(0xFFECECFB);

  /// 「回到底部 / 有人@我」浮层背景。
  static const locateTipBg = Color(0xFFFFFFFF);

  /// 文件/名片卡片阴影。对应 im-var `$im-box-shadow`。
  static const cardBoxShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];
}
