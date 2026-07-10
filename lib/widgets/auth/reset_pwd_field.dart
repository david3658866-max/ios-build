import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';

/// 找回密码页输入框。对应 reset-pwd.vue scoped scss .form-item。
class ResetPwdField extends StatefulWidget {
  const ResetPwdField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.suffix,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  @override
  State<ResetPwdField> createState() => _ResetPwdFieldState();
}

class _ResetPwdFieldState extends State<ResetPwdField> {
  FocusNode? _ownedFocus;
  bool _focused = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocus!;

  static const _iconBg = Color(0xFFF7F8FC);
  static const _suffixColor = Color(0xFF8B90E6);

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocus = FocusNode();
    }
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _ownedFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = rpx(context, 25);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: rpx(context, 100),
      margin: EdgeInsets.symmetric(vertical: rpx(context, 24)),
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 30)),
      transform: _focused
          ? Matrix4.translationValues(0, -rpx(context, 2), 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _focused ? AuthColors.accent : Colors.transparent,
          width: rpx(context, 2),
        ),
        boxShadow: [
          BoxShadow(
            color: _focused
                ? AuthColors.accent.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: rpx(context, _focused ? 32 : 20),
            offset: Offset(0, rpx(context, _focused ? 8 : 4)),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedScale(
            scale: _focused ? 1.1 : 1,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: rpx(context, 60),
              height: rpx(context, 60),
              margin: EdgeInsets.only(right: rpx(context, 30)),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _iconBg,
              ),
              child: Icon(
                widget.prefixIcon,
                size: rpx(context, 32),
                color: AuthColors.accent,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              onSubmitted: widget.onSubmitted,
              style: TextStyle(
                fontSize: rpx(context, 32),
                color: const Color(0xFF333333),
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                counterText: '',
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: rpx(context, 30),
                  color: const Color(0xFF6A6A6A),
                ),
              ),
            ),
          ),
          if (widget.suffix != null) widget.suffix!,
        ],
      ),
    );
  }
}

/// 验证码区域 suffix。对应 .captcha-section。
class ResetPwdCaptchaSuffix extends StatelessWidget {
  const ResetPwdCaptchaSuffix({
    super.key,
    required this.lockSeconds,
    required this.onSend,
  });

  final int lockSeconds;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    if (lockSeconds > 0) {
      return Padding(
        padding: EdgeInsets.only(left: rpx(context, 20)),
        child: Text(
          '${lockSeconds}秒后重新获取',
          style: TextStyle(
            fontSize: rpx(context, 24),
            color: const Color(0xFF6A6A6A),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: onSend,
      child: Container(
        margin: EdgeInsets.only(left: rpx(context, 20)),
        padding: EdgeInsets.symmetric(
          horizontal: rpx(context, 16),
          vertical: rpx(context, 8),
        ),
        decoration: BoxDecoration(
          color: AuthColors.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(rpx(context, 20)),
        ),
        child: Text(
          '获取验证码',
          style: TextStyle(
            fontSize: rpx(context, 28),
            color: AuthColors.accent,
          ),
        ),
      ),
    );
  }
}

/// 密码可见性切换 suffix。对应 .icon-suffix。
class ResetPwdVisibilitySuffix extends StatelessWidget {
  const ResetPwdVisibilitySuffix({
    super.key,
    required this.visible,
    required this.onToggle,
  });

  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: EdgeInsets.all(rpx(context, 10)),
        child: Icon(
          visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: rpx(context, 36),
          color: _ResetPwdFieldState._suffixColor,
        ),
      ),
    );
  }
}
