import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';

/// Auth 圆角输入框。对应 auth-page.scss .form-item。
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.maxLength,
    this.inputFormatters,
    this.suffix,
    this.onSubmitted,
    this.marginBottom = true,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  /// 最后一个输入框可设为 false 去掉底部间距。
  final bool marginBottom;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  FocusNode? _ownedFocus;
  bool _focused = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocus!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocus = FocusNode();
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AuthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) {
        _ownedFocus?.removeListener(_onFocusChange);
        _ownedFocus?.dispose();
        _ownedFocus = null;
      }
      if (widget.focusNode == null) {
        _ownedFocus = FocusNode();
      }
      _focusNode.addListener(_onFocusChange);
    }
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
    final borderColor = _focused ? AuthColors.accent : AuthColors.inputBorder;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: rpx(context, 108),
      margin: widget.marginBottom
          ? EdgeInsets.only(bottom: rpx(context, 28))
          : EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(rpx(context, 20), 0, rpx(context, 24), 0),
      decoration: BoxDecoration(
        color: AuthColors.inputBg,
        borderRadius: BorderRadius.circular(rpx(context, 20)),
        border: Border.all(color: borderColor, width: rpx(context, 2)),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: AuthColors.accent.withValues(alpha: 0.1),
                  blurRadius: 0,
                  spreadRadius: rpx(context, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: rpx(context, 56),
            height: rpx(context, 56),
            margin: EdgeInsets.only(right: rpx(context, 18)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: _focused
                  ? AuthColors.iconWrapperFocusedGradient
                  : AuthColors.iconWrapperGradient,
            ),
            child: Icon(
              widget.prefixIcon,
              size: rpx(context, 34),
              color: _focused ? AuthColors.accentDeep : AuthColors.accent,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              // 手机号用电话键盘（九宫格），避免华为等机型弹出带 +-=/ 的数字键盘。
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              autofillHints: widget.autofillHints,
              maxLength: widget.maxLength,
              inputFormatters: widget.inputFormatters,
              onSubmitted: widget.onSubmitted,
              autocorrect: false,
              enableSuggestions: false,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              // 保证聚焦时输入框滚到键盘上方，不被挡住。
              scrollPadding: EdgeInsets.only(
                bottom: bottomInset + rpx(context, 120),
              ),
              style: TextStyle(
                fontSize: rpx(context, 32),
                color: AuthColors.text,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                counterText: '',
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: rpx(context, 30),
                  color: AuthColors.placeholder,
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
