import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_constants.dart';
import '../../core/di/app_providers.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';
import '../../widgets/im_feedback.dart';

/// 青少年模式。对齐 mine-teenager.vue（本地 KV 存储）。
class TeenagerPage extends ConsumerStatefulWidget {
  const TeenagerPage({super.key});

  @override
  ConsumerState<TeenagerPage> createState() => _TeenagerPageState();
}

class _TeenagerPageState extends ConsumerState<TeenagerPage> {
  int _step = 1;
  bool _enabled = false;
  String _password = '';
  int _pinNonce = 0;

  String? get _storageKey {
    final userId = ref.read(userStoreProvider)?.id;
    if (userId == null) return null;
    return 'chats-app-$userId-teenagerMode';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromStorage());
  }

  void _loadFromStorage() {
    final key = _storageKey;
    if (key == null) return;
    final raw = ref.read(kvStoreProvider).get<String>(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _enabled = data['enabled'] == true;
        _password = data['password'] as String? ?? '';
      });
    } catch (_) {}
  }

  Future<void> _saveMode({required bool enabled, required String password}) async {
    final key = _storageKey;
    if (key == null) return;
    await ref.read(kvStoreProvider).set(
          key,
          jsonEncode({'enabled': enabled, 'password': password}),
        );
  }

  Future<void> _removeMode() async {
    final key = _storageKey;
    if (key == null) return;
    await ref.read(kvStoreProvider).remove(key);
  }

  void _snack(String msg) => ImFeedback.toast(context, msg);

  void _onPasswordComplete(String code) {
    setState(() {
      _password = code;
      _step = 3;
    });
  }

  Future<void> _onPasswordConfirm(String code) async {
    if (_password == code) {
      await _saveMode(enabled: true, password: _password);
      if (!mounted) return;
      setState(() {
        _enabled = true;
        _step = 1;
      });
    } else {
      _snack('密码不一致,请重新设置');
      setState(() {
        _step = 3;
        _pinNonce++;
      });
    }
  }

  Future<void> _onPasswordVerify(String code) async {
    if (_password == code) {
      await _removeMode();
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _password = '';
        _step = 1;
      });
      _snack('青少年模式已关闭');
    } else {
      _snack('密码错误，请重新输入');
      setState(() {
        _step = 4;
        _pinNonce++;
      });
    }
  }

  Future<void> _onCloseTeenagerMode() async {
    final ok = await showImConfirmDialog(
      context,
      title: '关闭青少年模式',
      content: '关闭后,将解除功能限制，确认关闭?',
      confirmText: '确认',
    );
    if (ok == true && mounted) {
      setState(() => _step = 4);
    }
  }

  Widget _buildStepTeenager({required bool enabled}) {
    return Padding(
      padding: EdgeInsets.all(rpx(context, 60)),
      child: Column(
        children: [
          Icon(
            Icons.child_care,
            size: rpx(context, 100),
            color: ImColors.accent.withValues(alpha: 0.8),
          ),
          SizedBox(height: rpx(context, 50)),
          Text(
            '青少年模式已开启',
            style: TextStyle(
              fontSize: rpx(context, 40),
              fontWeight: FontWeight.bold,
              color: ImColors.text,
            ),
          ),
          SizedBox(height: rpx(context, 40)),
          Text(
            enabled
                ? '部分功能将受限使用'
                : '为呵护未成年人健康成长，${AppConstants.appName}推出青少年模式。该模式下部分功能将受限使用，请监护人主动设置。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rpx(context, 28),
              color: ImColors.textLight,
              height: 1.6,
            ),
          ),
          SizedBox(height: rpx(context, 120)),
          if (enabled)
            SizedBox(
              width: double.infinity,
              height: rpx(context, 88),
              child: Material(
                color: ImColors.danger,
                borderRadius: BorderRadius.circular(rpx(context, 8)),
                child: InkWell(
                  onTap: _onCloseTeenagerMode,
                  borderRadius: BorderRadius.circular(rpx(context, 8)),
                  child: Center(
                    child: Text(
                      '关闭青少年模式',
                      style: TextStyle(
                        fontSize: rpx(context, 32),
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            ImPrimaryButton(
              text: '开 启',
              onPressed: () => setState(() => _step = 2),
            ),
        ],
      ),
    );
  }

  Widget _buildStepPassword({
    required String title,
    String? tip,
    required ValueChanged<String> onComplete,
    int stepKey = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: rpx(context, 100)),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: rpx(context, 40),
              fontWeight: FontWeight.bold,
              color: ImColors.text,
            ),
          ),
          if (tip != null) ...[
            SizedBox(height: rpx(context, 40)),
            Text(
              tip,
              style: TextStyle(
                fontSize: rpx(context, 28),
                color: ImColors.textLight,
                height: 1.6,
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.all(rpx(context, 60)),
            child: _PinCodeInput(
              key: ValueKey(stepKey),
              onComplete: onComplete,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '青少年模式', showBack: true),
      body: SingleChildScrollView(
        child: switch (_step) {
          1 when !_enabled => _buildStepTeenager(enabled: false),
          1 => _buildStepTeenager(enabled: true),
          2 => _buildStepPassword(
              title: '设置独立密码',
              tip: '使用独立密码管理青少年模式',
              stepKey: 2,
              onComplete: _onPasswordComplete,
            ),
          3 => _buildStepPassword(
              title: '确认独立密码',
              tip: '使用独立密码管理青少年模式',
              stepKey: 300 + _pinNonce,
              onComplete: _onPasswordConfirm,
            ),
          _ => _buildStepPassword(
              title: '验证独立密码',
              stepKey: 400 + _pinNonce,
              onComplete: _onPasswordVerify,
            ),
        },
      ),
    );
  }
}

class _PinCodeInput extends StatefulWidget {
  const _PinCodeInput({super.key, required this.onComplete});

  final ValueChanged<String> onComplete;

  @override
  State<_PinCodeInput> createState() => _PinCodeInputState();
}

class _PinCodeInputState extends State<_PinCodeInput> {
  final _focusNode = FocusNode();
  final _ctrl = TextEditingController();
  String _value = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) return;
    setState(() => _value = digits);
    _ctrl.value = TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
    if (digits.length == 4) {
      widget.onComplete(digits);
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = rpx(context, 96);
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < _value.length;
              return Container(
                width: boxSize,
                height: boxSize,
                margin: EdgeInsets.symmetric(horizontal: rpx(context, 12)),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: filled ? ImColors.accent : ImColors.border,
                    width: rpx(context, 2),
                  ),
                  borderRadius: BorderRadius.circular(rpx(context, 12)),
                ),
                alignment: Alignment.center,
                child: filled
                    ? Container(
                        width: rpx(context, 20),
                        height: rpx(context, 20),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: ImColors.text,
                        ),
                      )
                    : null,
              );
            }),
          ),
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _ctrl,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                obscureText: true,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
