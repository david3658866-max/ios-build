import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/utils/user_bind_util.dart';
import '../../core/http/api_result.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_form.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';
import '../../widgets/im_feedback.dart';

/// 绑定邮箱。对齐 mine-email.vue。
class BindEmailPage extends ConsumerStatefulWidget {
  const BindEmailPage({super.key});

  @override
  ConsumerState<BindEmailPage> createState() => _BindEmailPageState();
}

class _BindEmailPageState extends ConsumerState<BindEmailPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  int _lock = 0;
  Timer? _lockTimer;

  static final _emailReg = UserBindUtil.emailReg;

  @override
  void dispose() {
    _lockTimer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ImFeedback.toast(context, msg);

  bool _validEmail() {
    final v = _emailCtrl.text.trim();
    if (v.isEmpty) {
      _snack('请输入邮箱');
      return false;
    }
    if (!_emailReg.hasMatch(v)) {
      _snack('邮箱格式错误');
      return false;
    }
    return true;
  }

  void _startLock() {
    _lock = UserBindUtil.smsCodeLockSeconds;
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _lock -= 1);
      if (_lock <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (!_validEmail()) return;
    try {
      await ref.read(authApiProvider).sendMailCode({
        'email': _emailCtrl.text.trim(),
      });
      _startLock();
      _snack('验证码已发送至您的邮箱，请注意查收');
    } on ApiException catch (e) {
      if (!e.silent) _snack(e.message);
    } catch (e) {
      _snack('发送失败：${asApiException(e).message}');
    }
  }

  Future<void> _submit() async {
    if (!_validEmail()) return;
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      _snack('请输入验证码');
      return;
    }

    final ok = await showImConfirmDialog(
      context,
      title: '确认绑定？',
      content: '邮箱绑定后将无法更改，是否绑定?',
      confirmText: '确认',
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(userApiProvider).bindEmail({
        'email': _emailCtrl.text.trim(),
        'code': code,
      });
      await ref.read(userStoreProvider.notifier).loadSelf();
      if (!mounted) return;
      _snack('邮箱绑定成功');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!e.silent) _snack(e.message);
    } catch (e) {
      _snack(asApiException(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _captchaSuffix() {
    if (_lock > 0) {
      return Text(
        '$_lock秒后重新获取',
        style: TextStyle(
          fontSize: rpx(context, 26),
          color: ImColors.textLighter,
        ),
      );
    }
    return GestureDetector(
      onTap: _sendCode,
      child: Text(
        '获取验证码',
        style: TextStyle(
          fontSize: rpx(context, 28),
          color: ImColors.accent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '绑定邮箱', showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: rpx(context, 24)),
          ImFormCard(
            padding: EdgeInsets.fromLTRB(
              rpx(context, 32),
              rpx(context, 24),
              rpx(context, 32),
              rpx(context, 32),
            ),
            children: [
              ImFormTopField(
                label: '邮箱',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
              ),
              ImFormTopField(
                label: '验证码',
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                suffix: _captchaSuffix(),
              ),
            ],
          ),
          const Spacer(),
          ImPrimaryButton(
            text: '绑定',
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
