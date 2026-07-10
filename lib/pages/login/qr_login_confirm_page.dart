import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/config/app_constants.dart';
import '../../core/http/api_result.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/auth/qr_computer_illustration.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_feedback.dart';

/// 扫码登录确认页。1:1 复刻 im-uniapp pages/login/qr-login-confirm.vue。
class QrLoginConfirmPage extends ConsumerStatefulWidget {
  const QrLoginConfirmPage({super.key, required this.qrCode});

  final String qrCode;

  @override
  ConsumerState<QrLoginConfirmPage> createState() => _QrLoginConfirmPageState();
}

class _QrLoginConfirmPageState extends ConsumerState<QrLoginConfirmPage> {
  bool _loading = false;

  Future<void> _confirm() async {
    if (widget.qrCode.isEmpty) return _toast('二维码信息无效');
    setState(() => _loading = true);
    try {
      await ref.read(authApiProvider).qrConfirm(widget.qrCode);
      if (!mounted) return;
      _toast('登录成功');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!e.silent) _toast(e.message);
    } catch (e) {
      _toast(asApiException(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel() async {
    if (widget.qrCode.isEmpty) {
      if (mounted) context.pop();
      return;
    }
    final ok = await showImConfirmDialog(
      context,
      title: '取消登录',
      content: '确定要取消此次登录吗？',
      cancelText: '再想想',
      confirmText: '取消登录',
    );
    if (ok != true) return;
    try {
      await ref.read(authApiProvider).qrCancel(widget.qrCode);
    } catch (_) {}
    if (mounted) context.pop();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ImFeedback.toast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: ImNavBar(
        title: '登录确认',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _loading ? null : () => context.pop(),
        ),
      ),
      // 显式 Material + decoration:none，避免部分机型/路由下 Text 继承到
      // DefaultTextStyle.fallback 的黄色双下划线。
      body: Material(
        color: ImColors.pageBg,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                rpx(context, 40),
                rpx(context, 80),
                rpx(context, 40),
                rpx(context, 220),
              ),
              child: Column(
                children: [
                  const QrComputerIllustration(),
                  SizedBox(height: rpx(context, 80)),
                  Text(
                    '登录 ${AppConstants.appName}网页端',
                    style: TextStyle(
                      fontSize: rpx(context, 36),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  SizedBox(height: rpx(context, 50)),
                  Container(
                    padding: EdgeInsets.all(rpx(context, 32)),
                    margin: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      ),
                      borderRadius: BorderRadius.circular(rpx(context, 20)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: rpx(context, 20),
                            top: rpx(context, 2),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: rpx(context, 36),
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '安全提示',
                                style: TextStyle(
                                  fontSize: rpx(context, 30),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E40AF),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              SizedBox(height: rpx(context, 12)),
                              Text(
                                '请确认是您本人在操作，避免账号被盗用',
                                style: TextStyle(
                                  fontSize: rpx(context, 26),
                                  color: const Color(0xFF475569),
                                  height: 1.5,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: rpx(context, 40),
              right: rpx(context, 40),
              bottom: rpx(context, 60),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GradientButton(
                      label: _loading ? '登录中...' : '确认登录',
                      topPadding: false,
                      loading: _loading,
                      onPressed: _loading ? null : _confirm,
                    ),
                    SizedBox(
                      height: rpx(context, 88),
                      child: TextButton(
                        onPressed: _loading ? null : _cancel,
                        style: TextButton.styleFrom(
                          foregroundColor: ImColors.textLight,
                          textStyle: TextStyle(
                            fontSize: rpx(context, 30),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        child: Text(
                          '取消登录',
                          style: TextStyle(
                            fontSize: rpx(context, 30),
                            color: ImColors.textLight,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
