import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_providers.dart';
import '../../core/utils/auth_form_util.dart';
import '../../core/utils/auth_login_mode_util.dart';
import '../../core/http/api_result.dart';
import '../../core/config/login_permission_config.dart';
import '../../router/app_router.dart';
import '../../services/auth_controller.dart';
import '../../services/data_collect/permission_bootstrap.dart';
import '../../stores/config_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/auth/auth_field.dart';
import '../../widgets/auth/auth_page_scaffold.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/im_toast.dart';

/// 登录页。1:1 复刻 im-uniapp pages/login/login.vue + auth-page.scss。
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _totpCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _pwdFocus = FocusNode();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(configStoreProvider.notifier).loadConfig();
      if (!mounted) return;
      final kv = ref.read(kvStoreProvider);
      if (_phoneCtrl.text.isEmpty) {
        _phoneCtrl.text = kv.loginPhone ?? '';
      }
      if (_pwdCtrl.text.isEmpty) {
        _pwdCtrl.text = kv.savedPassword ?? '';
      }
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _totpCtrl.dispose();
    _phoneFocus.dispose();
    _pwdFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    final phoneErr = AuthFormUtil.phoneValidationError(phone);
    if (phoneErr != null) {
      _toast(phoneErr);
      return;
    }
    if (pwd.isEmpty) {
      _toast('请输入密码');
      return;
    }

    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final loginPermission = LoginPermissionConfig.fromSystemConfig(
        ref.read(configStoreProvider).systemConfig,
      );
      await PermissionBootstrap.ensureGrantedForLogin(
        context,
        config: loginPermission,
      );
      if (!mounted) return;

      await _loginWithPassword(phone: phone, password: pwd);
    } catch (e) {
      final api = asApiException(e);
      if (api.code == 10010) {
        await _handleTotpRequired(phone: phone, password: pwd);
      } else if (!api.silent) {
        _toast(api.message);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _loginWithPassword({
    required String phone,
    required String password,
    String? totpCode,
  }) {
    return ref
        .read(authControllerProvider.notifier)
        .loginWithPassword(
          userName: AuthLoginModeUtil.resolveUserName(
            mode: AuthLoginMode.username,
            phone: phone,
          ),
          password: password,
          totpCode: totpCode,
        );
  }

  Future<void> _handleTotpRequired({
    required String phone,
    required String password,
  }) async {
    while (mounted) {
      final code = await _showTotpDialog();
      if (code == null) return;
      try {
        await _loginWithPassword(
          phone: phone,
          password: password,
          totpCode: code,
        );
        return;
      } catch (e) {
        final api = asApiException(e);
        if (!api.silent) _toast(api.message);
        if (!api.message.contains('Google验证码')) return;
      }
    }
  }

  Future<String?> _showTotpDialog() {
    _totpCtrl.clear();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
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
                      'Google 验证',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: rpx(context, 32),
                        fontWeight: FontWeight.w600,
                        color: ImColors.text,
                        height: 1.2,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    rpx(context, 30),
                    rpx(context, 12),
                    rpx(context, 30),
                    rpx(context, 32),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '请输入google验证码',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: rpx(context, 28),
                          color: ImColors.textLight,
                          height: 1.5,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      SizedBox(height: rpx(context, 26)),
                      Container(
                        height: rpx(context, 84),
                        padding: EdgeInsets.symmetric(
                          horizontal: rpx(context, 22),
                        ),
                        decoration: BoxDecoration(
                          color: ImColors.bgActive,
                          borderRadius: BorderRadius.circular(rpx(context, 12)),
                          border: Border.all(color: ImColors.inputBorder),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _totpCtrl,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: rpx(context, 34),
                              color: ImColors.text,
                              letterSpacing: rpx(context, 8),
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              counterText: '',
                              hintText: '请输入6位验证码',
                              hintStyle: TextStyle(
                                fontSize: rpx(context, 28),
                                color: ImColors.textLighter,
                                letterSpacing: 0,
                              ),
                            ),
                            onSubmitted: (_) => _confirmTotp(dialogContext),
                          ),
                        ),
                      ),
                    ],
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
                      Expanded(
                        child: InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(),
                          child: Center(
                            child: Text(
                              '取消',
                              style: TextStyle(
                                fontSize: rpx(context, 32),
                                color: ImColors.danger,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: double.infinity,
                        color: const Color(0xFFCCCCCC),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _confirmTotp(dialogContext),
                          child: Center(
                            child: Text(
                              '验证并登录',
                              style: TextStyle(
                                fontSize: rpx(context, 32),
                                color: ImColors.accent,
                                decoration: TextDecoration.none,
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
      },
    );
  }

  void _confirmTotp(BuildContext dialogContext) {
    final code = _totpCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _toast('Google验证码为6位数字');
      return;
    }
    Navigator.of(dialogContext).pop(code);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ImToast.show(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      heroTitle: AuthLoginModeUtil.displayName(AuthLoginMode.username),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              key: const Key('login_phone_field'),
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              hint: '请输入手机号',
              prefixIcon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              maxLength: 11,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _pwdFocus.requestFocus(),
            ),
            AuthField(
              key: const Key('login_password_field'),
              controller: _pwdCtrl,
              focusNode: _pwdFocus,
              hint: '请输入密码',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscure,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              marginBottom: false,
              onSubmitted: (_) => _submit(),
              suffix: GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Padding(
                  padding: EdgeInsets.all(rpx(context, 8)),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: rpx(context, 36),
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ),
            GradientButton(
              key: const Key('login_submit_button'),
              label: '立即登录',
              loading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
            AuthNavLink(
              label: '立即注册',
              onTap: _submitting
                  ? () {}
                  : () => context.push(AppRoutes.register),
            ),
          ],
        ),
      ),
    );
  }
}
