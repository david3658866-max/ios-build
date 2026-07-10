import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';

/// 确认弹窗。对齐 im-uniapp `popup-modal` 组件。
Future<bool?> showImConfirmDialog(
  BuildContext context, {
  required String title,
  String? content,
  Widget? body,
  String confirmText = '确定',
  String cancelText = '取消',
  bool showCancel = true,
  bool barrierDismissible = false,
  bool useRootNavigator = false,
}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => ImConfirmDialog(
      title: title,
      content: content,
      body: body,
      confirmText: confirmText,
      cancelText: cancelText,
      showCancel: showCancel,
    ),
  );
}

/// 与 uniapp `popup-modal` 同结构的确认弹窗，可直接用于 [showDialog]。
class ImConfirmDialog extends StatelessWidget {
  const ImConfirmDialog({
    super.key,
    required this.title,
    this.content,
    this.body,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.showCancel = true,
  });

  final String title;
  final String? content;
  final Widget? body;
  final String confirmText;
  final String cancelText;
  final bool showCancel;

  bool get _hasMiddle =>
      (content != null && content!.isNotEmpty) || body != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: rpx(context, 80)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(rpx(context, 15)),
      ),
      child: Padding(
        padding: EdgeInsets.all(rpx(context, 15)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: rpx(context, 60),
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rpx(context, 32),
                    fontWeight: FontWeight.w600,
                    color: ImColors.text,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            if (_hasMiddle)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  rpx(context, 30),
                  rpx(context, 12),
                  rpx(context, 30),
                  rpx(context, 32),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: rpx(context, 400),
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (content != null && content!.isNotEmpty)
                          Text(
                            content!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: rpx(context, 30),
                              color: ImColors.textLight,
                              height: 1.5,
                            ),
                          ),
                        if (body != null) body!,
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              height: rpx(context, 1),
              color: const Color(0xFFCCCCCC),
            ),
            SizedBox(
              height: rpx(context, 80),
              child: Row(
                children: [
                  if (showCancel)
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        child: Center(
                          child: Text(
                            cancelText,
                            style: TextStyle(
                              fontSize: rpx(context, 32),
                              color: ImColors.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (showCancel)
                    Container(
                      width: 1,
                      height: double.infinity,
                      color: const Color(0xFFCCCCCC),
                    ),
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Center(
                        child: Text(
                          confirmText,
                          style: TextStyle(
                            fontSize: rpx(context, 32),
                            color: ImColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
