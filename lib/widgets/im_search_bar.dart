import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 搜索栏。对齐 uni-search-bar + `.nav-bar`（friend.vue / friend-add.vue）。
///
/// 远程搜索：传 [onConfirm]、[onCancel]（如 friend-add）。
/// 本地过滤：传 [onChanged]、[focusNode]，不传 [onConfirm]、[onCancel]（如 friend.vue cancelButton="none"）。
class ImSearchBar extends StatelessWidget {
  const ImSearchBar({
    super.key,
    required this.controller,
    required this.placeholder,
    this.onConfirm,
    this.onCancel,
    this.onChanged,
    this.focusNode,
    this.loading = false,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final String placeholder;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool loading;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: rpx(context, 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: ImColors.formDivider, width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
      alignment: Alignment.center,
      child: Row(
        children: [
          if (onCancel != null)
            GestureDetector(
              onTap: onCancel,
              child: Padding(
                padding: EdgeInsets.only(right: rpx(context, 16)),
                child: Text(
                  '取消',
                  style: TextStyle(
                    fontSize: rpx(context, 28),
                    color: ImColors.textLight,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Container(
              height: rpx(context, 72),
              decoration: BoxDecoration(
                color: ImColors.bgActive,
                borderRadius: BorderRadius.circular(rpx(context, 100)),
              ),
              padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: rpx(context, 32),
                    color: ImColors.textLighter,
                  ),
                  SizedBox(width: rpx(context, 12)),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: autofocus,
                      textInputAction: onConfirm != null
                          ? TextInputAction.search
                          : TextInputAction.done,
                      onSubmitted:
                          onConfirm != null ? (_) => onConfirm!() : null,
                      onChanged: onChanged,
                      style: TextStyle(fontSize: rpx(context, 28)),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: placeholder,
                        hintStyle: TextStyle(
                          fontSize: rpx(context, 28),
                          color: ImColors.textLighter,
                        ),
                      ),
                    ),
                  ),
                  if (loading)
                    SizedBox(
                      width: rpx(context, 32),
                      height: rpx(context, 32),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ImColors.accent,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
