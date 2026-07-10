import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/http/api_result.dart';
import '../../core/utils/group_permission_util.dart';
import '../../models/group.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';

/// 群设置。对齐 group-setting.vue。
class GroupSettingPage extends ConsumerStatefulWidget {
  const GroupSettingPage({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<GroupSettingPage> createState() => _GroupSettingPageState();
}

class _GroupSettingPageState extends ConsumerState<GroupSettingPage> {
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (ref.read(groupStoreProvider.notifier).byId(widget.groupId) != null) {
      _loading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    try {
      await ref.read(groupStoreProvider.notifier).loadGroupDetail(widget.groupId);
      await ref.read(groupStoreProvider.notifier).loadMembers(widget.groupId);
      if (!mounted) return;
      final group = _resolveGroup();
      final mineId = ref.read(userStoreProvider)?.id;
      final members = ref
          .read(groupStoreProvider.notifier)
          .membersOf(widget.groupId)
          .where((m) => !m.quit)
          .toList();
      if (group != null &&
          !GroupPermissionUtil.canAccessGroupSetting(
            group: group,
            members: members,
            mineId: mineId,
          )) {
        ImFeedback.toast(context, '您没有操作权限');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Group? _resolveGroup() {
    for (final g in ref.watch(groupStoreProvider)) {
      if (g.id == widget.groupId) return g;
    }
    return null;
  }

  Future<void> _toggle(
    Future<void> Function() action, {
    required String errorTip,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _resolveGroup();

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '群设置', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : group == null
              ? const Center(child: Text('群聊不存在'))
              : ListView(
                  children: [
                    ImBarGroup(
                      children: [
                        ImSwitchBar(
                          title: '全员禁言',
                          value: group.isAllMuted,
                          onChanged: _busy
                              ? null
                              : (v) => _toggle(
                                    () => ref
                                        .read(groupStoreProvider.notifier)
                                        .setAllMuted(widget.groupId, v),
                                    errorTip: '设置失败',
                                  ),
                        ),
                      ],
                    ),
                    ImBarGroup(
                      children: [
                        ImSwitchBar(
                          title: '允许普通成员邀请好友',
                          value: group.isAllowInvite,
                          onChanged: _busy
                              ? null
                              : (v) => _toggle(
                                    () => ref
                                        .read(groupStoreProvider.notifier)
                                        .setAllowInvite(widget.groupId, v),
                                    errorTip: '设置失败',
                                  ),
                        ),
                        ImSwitchBar(
                          title: '允许普通成员分享名片',
                          value: group.isAllowShareCard,
                          onChanged: _busy
                              ? null
                              : (v) => _toggle(
                                    () => ref
                                        .read(groupStoreProvider.notifier)
                                        .setAllowShareCard(widget.groupId, v),
                                    errorTip: '设置失败',
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: rpx(context, 24)),
                  ],
                ),
    );
  }
}
