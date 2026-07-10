import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/auth_colors.dart';
import '../../theme/rpx.dart';

/// 手机号专用九宫格键盘，避免系统弹出带运算符的数字键盘。
class AuthPhoneKeypad extends StatelessWidget {
  const AuthPhoneKeypad({
    super.key,
    required this.controller,
    this.maxLength = 11,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int maxLength;
  final VoidCallback? onCompleted;

  void _append(String digit) {
    final text = controller.text;
    if (text.length >= maxLength) return;
    controller.value = TextEditingValue(
      text: text + digit,
      selection: TextSelection.collapsed(offset: text.length + 1),
    );
    HapticFeedback.selectionClick();
    if (controller.text.length >= maxLength) {
      onCompleted?.call();
    }
  }

  void _backspace() {
    final text = controller.text;
    if (text.isEmpty) return;
    controller.value = TextEditingValue(
      text: text.substring(0, text.length - 1),
      selection: TextSelection.collapsed(offset: text.length - 1),
    );
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final keys = <List<String>>[
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Container(
      margin: EdgeInsets.only(bottom: rpx(context, 20)),
      padding: EdgeInsets.all(rpx(context, 12)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(rpx(context, 20)),
      ),
      child: Column(
        children: [
          for (final row in keys)
            Padding(
              padding: EdgeInsets.only(bottom: rpx(context, 10)),
              child: Row(
                children: [
                  for (final key in row)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: rpx(context, 6),
                        ),
                        child: key.isEmpty
                            ? SizedBox(height: rpx(context, 88))
                            : _KeypadButton(
                                label: key,
                                onTap: key == '⌫'
                                    ? _backspace
                                    : () => _append(key),
                              ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDelete = label == '⌫';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(rpx(context, 16)),
      child: InkWell(
        onTap: onTap,
        onLongPress: isDelete ? onTap : null,
        borderRadius: BorderRadius.circular(rpx(context, 16)),
        child: SizedBox(
          height: rpx(context, 88),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: rpx(context, isDelete ? 36 : 40),
                fontWeight: FontWeight.w600,
                color: AuthColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
