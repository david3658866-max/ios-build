import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/http/api_result.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../router/app_router.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../core/utils/group_permission_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/head_image.dart';
import '../../widgets/group/group_member_selector.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';

/// 群管理员。对齐 group-manager.vue。
class GroupManagerPage extends ConsumerStatefulWidget {
  const GroupManagerPage({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<GroupManagerPage> createState() => _GroupManagerPageState();
}

class _GroupManagerPageState extends ConsumerState<GroupManagerPage> {
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
      if (group != null &&
          !GroupPermissionUtil.canAccessGroupManager(
            group: group,
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

  List<GroupMember> _resolveMembers() {
    ref.watch(groupStoreProvider);
    return ref
        .read(groupStoreProvider.notifier)
        .membersOf(widget.groupId)
        .where((m) => !m.quit)
        .toList();
  }

  GroupMember? _ownerMember(Group group, List<GroupMember> members) {
    final ownerId = group.ownerId;
    if (ownerId == null) return null;
    for (final m in members) {
      if (m.userId == ownerId) return m;
    }
    return null;
  }

  List<GroupMember> _managerMembers(List<GroupMember> members) =>
      members.where((m) => m.isManager).toList();

  Future<void> _onRemoveManager(GroupMember member) async {
    final ok = await showImConfirmDialog(
      context,
      title: '移除群管理员',
      content: "确定将'${member.showNickName}'从管理员列表中移除吗",
    );
    if (ok != true || !mounted || _busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(groupApiProvider).removeManager({
        'groupId': widget.groupId,
        'userIds': [member.userId],
      });
      await ref.read(groupStoreProvider.notifier).loadMembers(widget.groupId);
      if (!mounted) return;
      ImFeedback.toast(context, "您移除了'${member.showNickName}'的管理员身份");
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onAddManager(Group group, List<GroupMember> members) async {
    if (_busy) return;
    final hideIds = [group.ownerId ?? -1];
    final managerIds =
        members.where((m) => m.isManager).map((m) => m.userId).toList();
    final userIds = await GroupMemberSelector.show(
      context,
      members: members,
      group: group,
      lockedIds: managerIds,
      hideIds: hideIds,
    );
    if (userIds == null || !mounted) return;
    final toAdd =
        userIds.where((id) => !managerIds.contains(id)).toList();
    if (toAdd.isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(groupApiProvider).addManager({
        'groupId': group.id,
        'userIds': toAdd,
      });
      await ref.read(groupStoreProvider.notifier).loadMembers(group.id);
      if (!mounted) return;
      ImFeedback.toast(context, '您添加了${toAdd.length}名管理员');
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
    final members = _resolveMembers();
    final owner = group == null ? null : _ownerMember(group, members);
    final managers = _managerMembers(members);

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '群管理员', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : group == null
              ? const Center(child: Text('群聊不存在'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          _TitleBar(title: '群主'),
                          if (owner != null)
                            _ManagerRow(
                              member: owner,
                              onTap: () => context.push(
                                AppRoutes.friendUserPath(owner.userId),
                              ),
                            ),
                          _TitleBar(title: '管理员(${managers.length})'),
                          for (final m in managers)
                            _ManagerRow(
                              member: m,
                              showRemove: !_busy,
                              onTap: () => context.push(
                                AppRoutes.friendUserPath(m.userId),
                              ),
                              onRemove: _busy ? null : () => _onRemoveManager(m),
                            ),
                        ],
                      ),
                    ),
                    _AddManagerBar(
                      onTap: _busy
                          ? null
                          : () => _onAddManager(group, members),
                    ),
                  ],
                ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        rpx(context, 30),
        rpx(context, 20),
        rpx(context, 30),
        rpx(context, 5),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: rpx(context, 32),
          color: ImColors.textLight,
        ),
      ),
    );
  }
}

class _ManagerRow extends StatelessWidget {
  const _ManagerRow({
    required this.member,
    required this.onTap,
    this.showRemove = false,
    this.onRemove,
  });

  final GroupMember member;
  final VoidCallback onTap;
  final bool showRemove;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Container(
        height: rpx(context, 120),
        margin: EdgeInsets.only(bottom: rpx(context, 3)),
        padding: EdgeInsets.symmetric(horizontal: rpx(context, 30)),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Row(
                  children: [
                    HeadImage(
                      url: member.headImage,
                      name: member.showNickName,
                      size: 84,
                      online: member.online,
                    ),
                    SizedBox(width: rpx(context, 20)),
                    Expanded(
                      child: Text(
                        member.showNickName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: rpx(context, 32),
                          color: ImColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showRemove && onRemove != null)
              InkWell(
                onTap: onRemove,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: rpx(context, 8),
                    vertical: rpx(context, 20),
                  ),
                  child: Text(
                    '移除',
                    style: TextStyle(
                      fontSize: rpx(context, 32),
                      color: ImColors.accent,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 添加管理员行。对齐 `.tools-bar`。
class _AddManagerBar extends StatelessWidget {
  const _AddManagerBar({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: rpx(context, 120),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: rpx(context, 30)),
            child: Row(
              children: [
                Container(
                  width: rpx(context, 86),
                  height: rpx(context, 86),
                  alignment: Alignment.center,
                  child: Container(
                    width: rpx(context, 50),
                    height: rpx(context, 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ImColors.textLight,
                        width: rpx(context, 3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add,
                      size: rpx(context, 35),
                      color: ImColors.textLight,
                    ),
                  ),
                ),
                SizedBox(width: rpx(context, 20)),
                Text(
                  '添加管理员',
                  style: TextStyle(
                    fontSize: rpx(context, 32),
                    color: ImColors.text,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
