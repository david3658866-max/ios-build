import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/http/api_result.dart';
import '../../router/app_router.dart';
import '../../services/auth_controller.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';

/// 设置页。对齐 im-uniapp pages/mine/mine-setting.vue。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> with RouteAware {
  bool _busy = false;
  bool _manualApprove = false;
  bool _audioTip = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeRoute();
      _syncFromStore();
    });
  }

  @override
  void dispose() {
    imRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _subscribeRoute() {
    final route = ModalRoute.of(context);
    if (route != null) {
      imRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _syncFromStore();
  }

  void _syncFromStore() {
    final user = ref.read(userStoreProvider);
    setState(() {
      _manualApprove = user?.isManualApprove ?? false;
      _audioTip = user?.isAudioTip ?? false;
    });
  }

  Future<void> _setManualApprove(bool enabled) async {
    if (_busy) return;
    final prev = _manualApprove;
    setState(() {
      _busy = true;
      _manualApprove = enabled;
    });
    try {
      await ref.read(userApiProvider).setManualApprove(enabled);
      await ref.read(userStoreProvider.notifier).loadSelf();
      if (mounted) _syncFromStore();
    } catch (e) {
      if (mounted) {
        setState(() => _manualApprove = prev);
        ImFeedback.toast(context, '设置失败: ${asApiException(e).message}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setAudioTip(bool enabled) async {
    if (_busy) return;
    final prev = _audioTip;
    setState(() {
      _busy = true;
      _audioTip = enabled;
    });
    try {
      await ref.read(userApiProvider).setAudioTip(enabled);
      await ref.read(userStoreProvider.notifier).loadSelf();
      if (mounted) _syncFromStore();
    } catch (e) {
      if (mounted) {
        setState(() => _audioTip = prev);
        ImFeedback.toast(context, '设置失败: ${asApiException(e).message}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showImConfirmDialog(
      context,
      title: '确认退出?',
    );
    if (ok != true || !mounted) return;

    await ref.read(authControllerProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(
        title: '设置',
        showBack: true,
      ),
      body: ListView(
        padding: EdgeInsets.only(top: rpx(context, 24)),
        children: [
          ImBarGroup(
            children: [
              ImSwitchBar(
                title: '加我为好友时需要验证',
                value: _manualApprove,
                onChanged: _busy ? null : _setManualApprove,
              ),
              ImSwitchBar(
                title: '新消息提示音',
                value: _audioTip,
                onChanged: _busy ? null : _setAudioTip,
              ),
            ],
          ),
          ImBarGroup(
            children: [
              ImBtnBar(
                title: '退出登录',
                danger: true,
                onTap: _busy ? null : _confirmLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
