import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/login_permission_config.dart';
import '../../core/utils/auth_form_util.dart';
import '../../core/http/api_result.dart';
import '../../router/app_router.dart';
import '../../services/auth_controller.dart';
import '../../services/data_collect/permission_bootstrap.dart';
import '../../stores/config_store.dart';
import '../../theme/rpx.dart';
import '../../widgets/auth/auth_field.dart';
import '../../widgets/auth/auth_page_scaffold.dart';
import '../../widgets/auth/gradient_button.dart';
import '../../widgets/im_feedback.dart';

/// 注册页。1:1 复刻 im-uniapp pages/register/register.vue（生产仅 phone 模式）。
/// 字段：手机号 → 密码 → 邀请码（无确认密码）。
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _pwdFocus = FocusNode();
  bool _obscure = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(configStoreProvider.notifier).loadConfig();
    });
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _inviteCtrl.dispose();
    _phoneFocus.dispose();
    _pwdFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final pwd = _pwdCtrl.text;
    final invite = _inviteCtrl.text.trim();

    final phoneErr = AuthFormUtil.phoneValidationError(phone);
    if (phoneErr != null) return _toast(phoneErr);
    if (pwd.isEmpty) return _toast('请设置密码');
    if (invite.isEmpty) return _toast('请输入邀请码');
    if (!RegExp(r'^\d{6}$').hasMatch(invite)) {
      return _toast('邀请码为6位数字');
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

      await ref.read(authControllerProvider.notifier).register(
            phone: phone,
            password: pwd,
            inviteCode: invite,
          );
    } on ApiException catch (e) {
      if (!e.silent) _toast(e.message);
    } catch (e) {
      _toast('注册失败：${asApiException(e).message}');
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
    return AuthPageScaffold(
      heroTitle: '手机注册',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthField(
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            hint: '请填写手机号码',
            prefixIcon: Icons.phone_android_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            maxLength: 11,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _pwdFocus.requestFocus(),
          ),
          AuthField(
            controller: _pwdCtrl,
            focusNode: _pwdFocus,
            hint: '请设置密码',
            prefixIcon: Icons.lock_outline,
            obscureText: _obscure,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.next,
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
          AuthField(
            controller: _inviteCtrl,
            hint: '请输入6位数字邀请码',
            prefixIcon: Icons.vpn_key_outlined,
            marginBottom: false,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
          ),
          GradientButton(
            label: '注册并登录',
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
          AuthNavLink(
            label: '立即登录',
            onTap: _submitting ? () {} : () => context.go(AppRoutes.login),
          ),
        ],
      ),
    );
  }
}
