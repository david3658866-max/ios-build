import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/http/api_result.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_form.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';
import '../../widgets/im_feedback.dart';

/// 修改密码。对齐 mine-password.vue。
class PasswordPage extends ConsumerStatefulWidget {
  const PasswordPage({super.key});

  @override
  ConsumerState<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends ConsumerState<PasswordPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPwd = _oldCtrl.text;
    final newPwd = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (oldPwd.isEmpty) {
      _snack('请输入原密码');
      return;
    }
    if (newPwd.length < 6 || newPwd.length > 20) {
      _snack('新密码需 6-20 位');
      return;
    }
    if (newPwd != confirm) {
      _snack('两次输入的密码不一致');
      return;
    }
    if (newPwd == oldPwd) {
      _snack('新密码不能和原密码一致');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authApiProvider).modifyPwd({
        'oldPassword': oldPwd,
        'newPassword': newPwd,
      });
      if (mounted) {
        _snack('修改密码成功');
        await Future<void>.delayed(const Duration(seconds: 1));
        if (mounted) context.pop();
      }
    } catch (e) {
      _snack(asApiException(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String msg) => ImFeedback.toast(context, msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '修改密码', showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: rpx(context, 24)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              rpx(context, 36),
              0,
              rpx(context, 36),
              rpx(context, 20),
            ),
            child: Text(
              '为了账号安全，请设置 6-20 位密码，建议包含字母与数字。',
              style: TextStyle(
                fontSize: rpx(context, 28),
                color: ImColors.textLighter,
                height: 1.5,
              ),
            ),
          ),
          ImFormCard(
            padding: EdgeInsets.fromLTRB(
              rpx(context, 32),
              rpx(context, 24),
              rpx(context, 32),
              rpx(context, 32),
            ),
            children: [
              ImFormTopField(
                label: '原密码',
                controller: _oldCtrl,
                placeholder: '请输入原密码',
                obscureText: true,
                maxLength: 20,
              ),
              ImFormTopField(
                label: '新密码',
                controller: _newCtrl,
                placeholder: '请输入新密码（6-20 位）',
                obscureText: true,
                maxLength: 20,
              ),
              ImFormTopField(
                label: '确认密码',
                controller: _confirmCtrl,
                placeholder: '请再次输入新密码',
                obscureText: true,
                maxLength: 20,
              ),
            ],
          ),
          const Spacer(),
          ImPrimaryButton(
            text: '提交',
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
