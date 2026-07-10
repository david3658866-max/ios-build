import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 白卡片表单组。对齐 mine-edit.vue `.form`、mine-password.vue `.form-card`。
class ImFormCard extends StatelessWidget {
  const ImFormCard({
    super.key,
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: rpx(context, 24)),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rpx(context, 24)),
        boxShadow: [
          BoxShadow(
            color: ImColors.accent.withValues(alpha: 0.06),
            blurRadius: rpx(context, 24),
            offset: Offset(0, rpx(context, 6)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// 横向 label + value 行。对齐 mine-edit `.form-item`。
class ImFormRow extends StatelessWidget {
  const ImFormRow({
    super.key,
    required this.label,
    required this.child,
    this.showDivider = true,
    this.minHeight = 104,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String label;
  final Widget child;
  final bool showDivider;
  final double minHeight;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: rpx(context, 32)),
          constraints: BoxConstraints(minHeight: rpx(context, minHeight)),
          child: Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              SizedBox(
                width: rpx(context, 200),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: rpx(context, 32),
                    color: ImColors.text,
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        if (showDivider)
          Positioned(
            left: rpx(context, 32),
            right: 0,
            bottom: 0,
            child: Divider(
              height: 0.5,
              thickness: 0.5,
              color: ImColors.formDivider,
            ),
          ),
      ],
    );
  }
}

/// 只读 value 右对齐。
class ImFormReadRow extends StatelessWidget {
  const ImFormReadRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return ImFormRow(
      label: label,
      showDivider: showDivider,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: rpx(context, 30),
          color: ImColors.textLighter,
        ),
      ),
    );
  }
}

/// 可点击绑定行（去绑定）。
class ImFormBindRow extends StatelessWidget {
  const ImFormBindRow({
    super.key,
    required this.label,
    required this.actionText,
    this.onTap,
    this.showDivider = true,
  });

  final String label;
  final String actionText;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return ImFormRow(
      label: label,
      showDivider: showDivider,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              actionText,
              style: TextStyle(
                fontSize: rpx(context, 30),
                color: ImColors.accent,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: rpx(context, 28),
              color: ImColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

/// 右对齐单行输入。
class ImFormInputRow extends StatelessWidget {
  const ImFormInputRow({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.maxLength,
    this.showDivider = true,
    this.obscureText = false,
    this.keyboardType,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final int? maxLength;
  final bool showDivider;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ImFormRow(
      label: label,
      showDivider: showDivider,
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: rpx(context, 30),
          color: readOnly ? ImColors.textLighter : ImColors.text,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          counterText: '',
          hintText: placeholder,
          hintStyle: TextStyle(
            fontSize: rpx(context, 30),
            color: ImColors.textLighter,
          ),
        ),
      ),
    );
  }
}

/// 个性签名等多行输入。
class ImFormTextAreaRow extends StatelessWidget {
  const ImFormTextAreaRow({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.maxLength = 64,
    this.showDivider = true,
    this.readOnly = false,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final int maxLength;
  final bool showDivider;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return ImFormRow(
      label: label,
      showDivider: showDivider,
      crossAxisAlignment: CrossAxisAlignment.start,
      minHeight: 120,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: rpx(context, 14)),
        child: TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: 4,
          minLines: 1,
          readOnly: readOnly,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: rpx(context, 30),
            color: readOnly ? ImColors.textLighter : ImColors.text,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            counterText: '',
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: rpx(context, 30),
              color: ImColors.textLighter,
            ),
          ),
        ),
      ),
    );
  }
}

/// 性别单选。对齐 mine-edit radio-group。
class ImFormRadioRow extends StatelessWidget {
  const ImFormRadioRow({
    super.key,
    required this.label,
    required this.groupValue,
    required this.onChanged,
    this.showDivider = true,
  });

  final String label;
  final int groupValue;
  final ValueChanged<int> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return ImFormRow(
      label: label,
      showDivider: showDivider,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ImRadioOption(
            label: '男',
            value: 0,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
          SizedBox(width: rpx(context, 50)),
          ImRadioOption(
            label: '女',
            value: 1,
            groupValue: groupValue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class ImRadioOption extends StatelessWidget {
  const ImRadioOption({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int groupValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: rpx(context, 32),
            height: rpx(context, 32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? ImColors.accent : ImColors.border,
                width: rpx(context, 2),
              ),
            ),
            alignment: Alignment.center,
            child: selected
                ? Container(
                    width: rpx(context, 16),
                    height: rpx(context, 16),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: ImColors.accent,
                    ),
                  )
                : null,
          ),
          SizedBox(width: rpx(context, 10)),
          Text(
            label,
            style: TextStyle(
              fontSize: rpx(context, 30),
              color: ImColors.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// label 在上方的表单项。对齐 mine-password uni-forms-item。
class ImFormTopField extends StatelessWidget {
  const ImFormTopField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.obscureText = false,
    this.maxLength,
    this.keyboardType,
    this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final bool obscureText;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: rpx(context, 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: rpx(context, 28),
              fontWeight: FontWeight.w500,
              color: ImColors.text,
            ),
          ),
          SizedBox(height: rpx(context, 8)),
          TextField(
            controller: controller,
            obscureText: obscureText,
            maxLength: maxLength,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: rpx(context, 30)),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: rpx(context, 20),
                vertical: rpx(context, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(rpx(context, 8)),
                borderSide: BorderSide(color: ImColors.formDivider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(rpx(context, 8)),
                borderSide: BorderSide(color: ImColors.formDivider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(rpx(context, 8)),
                borderSide: BorderSide(color: ImColors.accent),
              ),
              hintText: placeholder,
              hintStyle: TextStyle(
                fontSize: rpx(context, 30),
                color: ImColors.textLighter,
              ),
              counterText: '',
              suffixIcon: suffix == null
                  ? null
                  : Padding(
                      padding: EdgeInsets.only(right: rpx(context, 8)),
                      child: suffix,
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
