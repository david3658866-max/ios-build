import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/utils/auth_form_util.dart';
import '../../core/utils/user_bind_util.dart';
import '../../core/http/api_result.dart';
import '../../theme/auth_colors.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/auth/reset_pwd_field.dart';
import '../../widgets/image_captcha_dialog.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_feedback.dart';

/// 找回密码方式（由路由 ?mode= 决定，页内不可切换）。
enum ResetMode { phone, email }

/// 重置密码页。1:1 复刻 im-uniapp pages/common/reset-pwd.vue。
class ResetPwdPage extends ConsumerStatefulWidget {
  const ResetPwdPage({super.key, this.mode = ResetMode.phone});

  final ResetMode mode;

  @override
  ConsumerState<ResetPwdPage> createState() => _ResetPwdPageState();
}

class _ResetPwdPageState extends ConsumerState<ResetPwdPage> {
  final _acctCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePwd = false;
  bool _obscureConfirm = false;
  bool _submitting = false;

  int _lock = 0;
  Timer? _lockTimer;

  bool get _isPhone => widget.mode == ResetMode.phone;

  @override
  void dispose() {
    _lockTimer?.cancel();
    _acctCtrl.dispose();
    _codeCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _validPhone() {
    final err = AuthFormUtil.phoneValidationError(_acctCtrl.text);
    if (err != null) {
      _toast(err);
      return false;
    }
    return true;
  }

  bool _validEmail() {
    final v = _acctCtrl.text.trim();
    if (v.isEmpty) {
      _toast('请输入邮箱');
      return false;
    }
    if (!UserBindUtil.isValidEmail(v)) {
      _toast('邮箱格式错误');
      return false;
    }
    return true;
  }

  void _startLock() {
    _lock = 60;
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _lock -= 1);
      if (_lock <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (_isPhone) {
      if (!_validPhone()) return;
      final captcha = await ImageCaptchaDialog.show(context);
      if (captcha == null) return;
      _startLock();
      try {
        await ref.read(authApiProvider).sendSmsCode({
          'phone': _acctCtrl.text.trim(),
          'id': captcha.id,
          'code': captcha.code,
        });
        _toast('验证码已发送至您的手机，请注意查收');
      } on ApiException catch (e) {
        if (!e.silent) _toast(e.message);
      } catch (e) {
        _toast('发送失败：${asApiException(e).message}');
      }
    } else {
      if (!_validEmail()) return;
      _startLock();
      try {
        await ref.read(authApiProvider).sendMailCode({
          'email': _acctCtrl.text.trim(),
        });
        _toast('验证码已发送至您的邮箱，请注意查收');
      } on ApiException catch (e) {
        if (!e.silent) _toast(e.message);
      } catch (e) {
        _toast('发送失败：${asApiException(e).message}');
      }
    }
  }

  Future<void> _submit() async {
    if (_isPhone) {
      if (!_validPhone()) return;
    } else {
      if (!_validEmail()) return;
    }
    final code = _codeCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    final confirm = _confirmCtrl.text;
    if (code.isEmpty) {
      _toast('请输入验证码');
      return;
    }
    if (pwd.isEmpty) {
      _toast('请输入密码');
      return;
    }
    if (confirm.isEmpty) {
      _toast('请输入确认密码');
      return;
    }
    if (confirm != pwd) {
      _toast('两次密码输入不一致');
      return;
    }

    setState(() => _submitting = true);
    try {
      final acct = _acctCtrl.text.trim();
      final body = <String, dynamic>{
        'mode': _isPhone ? 'phone' : 'email',
        'phone': _isPhone ? acct : '',
        'email': _isPhone ? '' : acct,
        'code': code,
        'password': pwd,
        'confirmPassword': confirm,
      };
      await ref.read(authApiProvider).resetPwd(body);
      if (!mounted) return;
      _toast('密码重置成功');
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!e.silent) _toast(e.message);
    } catch (e) {
      _toast(asApiException(e).message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ImFeedback.toast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '重置密码', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            rpx(context, 60),
            rpx(context, 60),
            rpx(context, 60),
            rpx(context, 40),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isPhone) ...[
                ResetPwdField(
                  controller: _acctCtrl,
                  hint: '请输入您的手机号码',
                  prefixIcon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                ResetPwdField(
                  controller: _codeCtrl,
                  hint: '请输入验证码',
                  prefixIcon: Icons.verified_outlined,
                  keyboardType: TextInputType.number,
                  suffix: ResetPwdCaptchaSuffix(
                    lockSeconds: _lock,
                    onSend: _sendCode,
                  ),
                ),
              ] else ...[
                ResetPwdField(
                  controller: _acctCtrl,
                  hint: '请输入您的邮箱',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                ResetPwdField(
                  controller: _codeCtrl,
                  hint: '请输入验证码',
                  prefixIcon: Icons.verified_outlined,
                  suffix: ResetPwdCaptchaSuffix(
                    lockSeconds: _lock,
                    onSend: _sendCode,
                  ),
                ),
              ],
              ResetPwdField(
                controller: _pwdCtrl,
                hint: '新的密码',
                prefixIcon: Icons.lock_outline,
                obscureText: !_obscurePwd,
                suffix: ResetPwdVisibilitySuffix(
                  visible: _obscurePwd,
                  onToggle: () => setState(() => _obscurePwd = !_obscurePwd),
                ),
              ),
              ResetPwdField(
                controller: _confirmCtrl,
                hint: '确认密码',
                prefixIcon: Icons.lock_outline,
                obscureText: !_obscureConfirm,
                onSubmitted: (_) => _submit(),
                suffix: ResetPwdVisibilitySuffix(
                  visible: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              GradientButton(
                label: '重置密码',
                topPadding: false,
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
              Padding(
                padding: EdgeInsets.only(top: rpx(context, 40), bottom: rpx(context, 60)),
                child: Text(
                  '验证身份，设置新密码',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rpx(context, 28),
                    color: AuthColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
