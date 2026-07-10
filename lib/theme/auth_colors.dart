import 'package:flutter/material.dart';

/// Auth 页色板。来源 im-uniapp/common/auth-page.scss + im-var.scss。
abstract final class AuthColors {
  static const heroStart = Color(0xFF262A8F);
  static const heroMid = Color(0xFF3E45D7);
  static const heroEnd = Color(0xFF6E73E1);
  static const accent = Color(0xFF3E45D7);
  static const accentDeep = Color(0xFF2F35B5);
  static const accentSoft = Color(0xFFE7E8FB);
  static const sheetBg = Color(0xFFF5F5FD);
  static const sheetBgEnd = Color(0xFFEEEEFB);
  static const pageBg = Color(0xFFE8E8F6);
  static const text = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const placeholder = Color(0xFF9CA3AF);
  static const inputBg = Color(0xFFFFFFFF);
  static const inputBorder = Color(0xFFDCDDF4);

  static const heroGradient = LinearGradient(
    begin: Alignment(-0.9, -1),
    end: Alignment(0.9, 1),
    colors: [heroStart, heroMid, heroEnd],
    stops: [0, 0.5, 1],
  );

  static const sheetGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sheetBg, sheetBgEnd],
  );

  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [heroMid, accent, heroEnd],
    stops: [0, 0.55, 1],
  );

  static const iconWrapperGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x1A3E45D7), Color(0x0F6E73E1)],
  );

  static const iconWrapperFocusedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x293E45D7), Color(0x1A6E73E1)],
  );
}
