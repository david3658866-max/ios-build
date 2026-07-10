import 'package:flutter/material.dart';

import '../theme/im_colors.dart';

/// iOS 风格开关。对齐 im-uniapp `switch-bar` 内原生 `<switch>`（scale 0.8）。
class ImSwitch extends StatelessWidget {
  const ImSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// 原生 switch 51×31，uniapp `transform: scale(0.8)`。
  static const _width = 41.0;
  static const _height = 25.0;
  static const _thumbSize = 21.0;
  static const _padding = 2.0;
  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: _duration,
          curve: Curves.easeInOut,
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_height / 2),
            color: value ? ImColors.switchOn : ImColors.switchOff,
          ),
          child: AnimatedAlign(
            duration: _duration,
            curve: Curves.easeInOut,
            alignment:
                value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _thumbSize,
              height: _thumbSize,
              margin: const EdgeInsets.all(_padding),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
