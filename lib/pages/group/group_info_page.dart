import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/constants/ui_timing.dart';
import '../../core/enums/chat_type.dart';
import '../../core/di/app_providers.dart';
import '../../core/http/api_result.dart';
import '../../core/utils/group_leave_util.dart';
import '../../core/utils/group_permission_util.dart';
import '../../core/utils/teenager_mode_util.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../router/app_router.dart';
import '../../stores/chat_store.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/chat_picker_sheet.dart';
import '../../widgets/chat/head_image.dart';
import '../../widgets/group/group_member_selector.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_switch.dart';

/// 群聊信息。对齐 im-uniapp pages/group/group-info.vue。
class GroupInfoPage extends ConsumerStatefulWidget {
  const GroupInfoPage({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends ConsumerState<GroupInfoPage>
    with RouteAware {
  bool _loading = true;
  bool _busy = false;
  bool _hasChat = false;
  bool _isCleanMessage = GroupLeaveUtil.defaultCleanOnLeave;

  @override
  void initState() {
    super.initState();
    _syncPrefillFromStore();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeRoute();
      unawaited(_load());
    });
  }

  @override
  void dispose() {
    imRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ImFeedback.toast(context, message);
  }

  void _subscribeRoute() {
    final route = ModalRoute.of(context);
    if (route != null) imRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    unawaited(_load());
  }

  /// 对齐 uniapp computed：已加入群聊时从 store 立即展示。
  void _syncPrefillFromStore() {
    final group = ref.read(groupStoreProvider.notifier).byId(widget.groupId);
    if (group != null) {
      _loading = false;
    }
  }

  Future<void> _refreshHasChat() async {
    final chat = await ref.read(chatStoreProvider).findChat(
          ChatType.group,
          widget.groupId,
        );
    if (mounted) setState(() => _hasChat = chat != null);
  }

  Future<void> _load() async {
    final store = ref.read(groupStoreProvider.notifier);
    try {
      final group = await store.loadGroupDetail(widget.groupId);
      unawaited(ref.read(chatStoreProvider).syncChatFromGroup(group));
      unawaited(store.loadMembers(widget.groupId));
      if (mounted) {
        setState(() => _loading = false);
      }
      unawaited(_refreshHasChat());
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _toast(asApiException(e).message.isEmpty ? '加载失败' : asApiException(e).message);
      }
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

  int? get _mineId => ref.read(userStoreProvider)?.id;

  String? _ownerName(Group group, List<GroupMember> members) {
    final ownerId = group.ownerId;
    if (ownerId == null) return null;
    for (final m in members) {
      if (m.userId == ownerId) return m.showNickName;
    }
    return null;
  }

  Future<void> _onDndChange(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(groupStoreProvider.notifier).setDnd(widget.groupId, value);
    } catch (e) {
      if (mounted) {
        _toast(asApiException(e).message.isEmpty ? '设置失败' : asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onTopChange(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(groupStoreProvider.notifier).setTop(widget.groupId, value);
    } catch (e) {
      if (mounted) {
        _toast(asApiException(e).message.isEmpty ? '设置失败' : asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onSendMessage() async {
    final group = _resolveGroup();
    if (group == null) return;
    await ref.read(chatStoreProvider).openChat(
          type: ChatType.group,
          targetId: group.id,
          showName: group.showGroupName ?? group.name,
          headImage: group.headImageThumb ?? group.headImage,
          isDnd: group.isDnd,
          isTop: group.isTop,
        );
    if (!mounted) return;
    context.push(AppRoutes.chatPath(ChatType.group, group.id));
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String content,
    required String confirmText,
    bool showCleanSwitch = false,
  }) {
    var clean = _isCleanMessage;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => ImConfirmDialog(
          title: title,
          content: content,
          confirmText: confirmText,
          body: showCleanSwitch
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: rpx(context, 16)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            GroupLeaveUtil.cleanSwitchLabel,
                            style: TextStyle(fontSize: rpx(context, 28)),
                          ),
                        ),
                        ImSwitch(
                          value: clean,
                          onChanged: (v) {
                            setLocal(() => clean = v);
                            _isCleanMessage = v;
                          },
                        ),
                      ],
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _onJoinGroup() async {
    final current = _resolveGroup();
    if (current?.dissolve == true) {
      _toast('群聊已解散');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final group = await ref.read(groupApiProvider).join(widget.groupId);
      ref.read(groupStoreProvider.notifier).addGroup(group);
      await ref.read(groupStoreProvider.notifier).loadMembers(widget.groupId);
      if (!mounted) return;
      _toast("您加入了群聊'${group.name ?? ''}'");
      await _load();
    } on ApiException catch (e) {
      if (mounted && !e.silent) _toast(e.message);
      if (e.message.contains('已解散')) {
        await _refreshDissolvedGroup();
      }
    } catch (e) {
      final api = asApiException(e);
      if (mounted) {
        _toast(api.message.isEmpty ? '加入失败，请稍后再试' : api.message);
      }
      if (api.message.contains('已解散')) {
        await _refreshDissolvedGroup();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshDissolvedGroup() async {
    try {
      await ref.read(groupStoreProvider.notifier).loadGroupDetail(widget.groupId);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _onQuitGroup() async {
    final group = _resolveGroup();
    if (group == null) return;
    final confirm = GroupLeaveUtil.quitConfirm();
    final ok = await _confirmDialog(
      title: confirm.title,
      content: confirm.content,
      confirmText: confirm.confirmText,
      showCleanSwitch: confirm.showCleanSwitch,
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(groupApiProvider).quit(widget.groupId);
      await _finishLeaveGroup(GroupLeaveUtil.quitSuccessMessage(group.name ?? ''));
    } on ApiException catch (e) {
      if (mounted && !e.silent) _toast(e.message);
    } catch (e) {
      if (mounted) _toast('退出失败: ${asApiException(e).message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onDissolveGroup() async {
    final group = _resolveGroup();
    if (group == null) return;
    final confirm = GroupLeaveUtil.dissolveConfirm(group.name ?? '');
    final ok = await _confirmDialog(
      title: confirm.title,
      content: confirm.content,
      confirmText: confirm.confirmText,
      showCleanSwitch: confirm.showCleanSwitch,
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(groupApiProvider).dissolve(widget.groupId);
      await _finishLeaveGroup(
        GroupLeaveUtil.dissolveSuccessMessage(group.name ?? ''),
      );
    } on ApiException catch (e) {
      if (mounted && !e.silent) _toast(e.message);
    } catch (e) {
      if (mounted) _toast('解散失败: ${asApiException(e).message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 退群/解散成功后：Toast → 1.5s → 跳群列表 → 更新 store。对齐 group-info.vue。
  Future<void> _finishLeaveGroup(String successMessage) async {
    final groupStore = ref.read(groupStoreProvider.notifier);
    final chatStore = ref.read(chatStoreProvider);
    final groupId = widget.groupId;
    final cleanChat = _isCleanMessage;

    if (!mounted) return;
    _toast(successMessage);
    await Future<void>.delayed(UiTiming.groupLeaveRedirect);
    if (!mounted) return;

    context.go(AppRoutes.groupList);
    groupStore.removeGroup(groupId);
    if (GroupLeaveUtil.shouldRemoveLocalChat(cleanChat)) {
      await chatStore.removeGroupChat(groupId);
    }
  }

  void _onMemberTap(GroupMember member) {
    context.push(AppRoutes.friendUserPath(member.userId));
  }

  void _onShowAllMembers() {
    context.push(AppRoutes.groupMemberPath(widget.groupId));
  }

  void _onInviteMember() {
    context.push(AppRoutes.groupInvitePath(widget.groupId));
  }

  void _onEditGroup(bool isManager) {
    context.push(AppRoutes.groupEditPath(widget.groupId, isManager: isManager));
  }

  void _onShowQrcode(bool isAllowInvite) {
    context.push(
      AppRoutes.groupQrcodePath(widget.groupId, isAllowInvite: isAllowInvite),
    );
  }

  void _onSetting() {
    context.push(AppRoutes.groupSettingPath(widget.groupId));
  }

  void _onSetManager() {
    context.push(AppRoutes.groupManagerPath(widget.groupId));
  }

  void _onChatHistory() {
    context.push(
      AppRoutes.chatHistoryPath(ChatType.group, widget.groupId),
    );
  }

  Future<void> _onSendCard() async {
    final enabled = TeenagerModeUtil.isEnabled(
      userId: ref.read(userStoreProvider)?.id,
      kv: ref.read(kvStoreProvider),
    );
    if (guardTeenagerFeature(
      teenagerModeEnabled: enabled,
      feature: TeenagerBlockFeature.shareCard,
      onBlocked: (msg) => _toast(msg),
    )) {
      return;
    }
    final group = _resolveGroup();
    if (group == null) return;

    final chats = await ChatPickerSheet.show(context);
    if (chats == null || chats.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final store = ref.read(chatStoreProvider);
      String? lastError;
      for (final chat in chats) {
        final err = await store.sendGroupCard(
          chatType: chat.type,
          targetId: chat.targetId,
          groupId: group.id,
          groupName: group.name ?? '',
          headImage: group.headImageThumb ?? group.headImage,
        );
        if (err != null) lastError = err;
      }
      if (!mounted) return;
      if (lastError != null) {
        _toast(lastError);
      } else {
        _toast('发送成功');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRemoveMember(
    Group group,
    List<GroupMember> members,
  ) async {
    final mineId = _mineId;
    if (mineId == null) return;
    final hideIds = GroupPermissionUtil.removeMemberSelectorHideIds(
      group: group,
      members: members,
      mineId: mineId,
    );
    final userIds = await GroupMemberSelector.show(
      context,
      members: members,
      group: group,
      mineId: mineId,
      hideIds: hideIds,
    );
    if (userIds == null || userIds.isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(groupApiProvider).removeMembers({
        'groupId': group.id,
        'userIds': userIds,
      });
      await ref.read(groupStoreProvider.notifier).loadMembers(group.id);
      if (!mounted) return;
      _toast('您移除了${userIds.length}位成员');
    } catch (e) {
      if (mounted) {
        _toast(asApiException(e).message.isEmpty ? '移除失败' : asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onMuted(Group group, List<GroupMember> members) async {
    if (_busy) return;
    final mineId = _mineId;
    if (mineId == null) return;
    final hideIds = GroupPermissionUtil.muteSelectorHideIds(
      group: group,
      members: members,
      mineId: mineId,
    );
    final mutedIds = GroupPermissionUtil.mutedMemberLockedIds(members);
    final userIds = await GroupMemberSelector.show(
      context,
      members: members,
      group: group,
      mineId: mineId,
      lockedIds: mutedIds,
      hideIds: hideIds,
    );
    if (userIds == null || !mounted) return;
    final toMute = GroupPermissionUtil.filterNewMuteTargets(userIds, mutedIds);
    if (toMute.isEmpty) return;

    await _sendMemberMuted(group.id, toMute, true, '您对${toMute.length}位成员进行了禁言');
  }

  Future<void> _onUnmuted(Group group, List<GroupMember> members) async {
    if (_busy) return;
    final mineId = _mineId;
    if (mineId == null) return;
    final hideIds = GroupPermissionUtil.unmuteSelectorHideIds(
      group: group,
      members: members,
      mineId: mineId,
    );
    final userIds = await GroupMemberSelector.show(
      context,
      members: members,
      group: group,
      mineId: mineId,
      hideIds: hideIds,
    );
    if (userIds == null || !mounted) return;
    final toUnmute =
        GroupPermissionUtil.filterUnmuteTargets(userIds, members);
    if (toUnmute.isEmpty) return;
    await _sendMemberMuted(
      group.id,
      toUnmute,
      false,
      '您解除了${toUnmute.length}位成员的禁言',
    );
  }

  Future<void> _sendMemberMuted(
    int groupId,
    List<int> userIds,
    bool isMuted,
    String tip,
  ) async {
    setState(() => _busy = true);
    try {
      await ref.read(groupApiProvider).setMemberMuted({
        'groupId': groupId,
        'userIds': userIds,
        'isMuted': isMuted,
      });
      await ref.read(groupStoreProvider.notifier).loadMembers(groupId);
      if (!mounted) return;
      _toast(tip);
    } catch (e) {
      if (mounted) {
        _toast(asApiException(e).message.isEmpty ? '操作失败' : asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _resolveGroup();
    final members = _resolveMembers();
    final mineId = _mineId;
    final quit = group?.quit ?? false;
    final dissolved = group?.dissolve ?? false;
    final isOwner = group != null &&
        GroupPermissionUtil.isOwner(mineId: mineId, ownerId: group.ownerId);
    final isManager =
        GroupPermissionUtil.isManager(mineId: mineId, members: members);
    final allowInvite = group != null &&
        GroupPermissionUtil.canInvite(
          group: group,
          members: members,
          mineId: mineId,
        );
    final allowShareCard = group != null &&
        GroupPermissionUtil.canShareCard(
          group: group,
          members: members,
          mineId: mineId,
        );
    final showTools = group != null &&
        GroupPermissionUtil.showManagerTools(
          group: group,
          members: members,
          mineId: mineId,
        );

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '群聊信息', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : group == null
              ? const Center(child: Text('群聊不存在'))
              : ListView(
                  children: [
                    _MemberGrid(
                      members: members,
                      maxCount: GroupPermissionUtil.memberGridShowMax(
                        group: group,
                        members: members,
                        mineId: mineId,
                      ),
                      showInvite: !quit && allowInvite,
                      showRemove: showTools,
                      showMutedTools: showTools,
                      onMemberTap: _onMemberTap,
                      onInvite: _onInviteMember,
                      onRemove: () => _onRemoveMember(group, members),
                      onMuted: () => _onMuted(group, members),
                      onUnmuted: () => _onUnmuted(group, members),
                      onShowAll: _onShowAllMembers,
                    ),
                    _GroupInfoForm(
                      group: group,
                      quit: quit,
                      ownerName: _ownerName(group, members) ?? '',
                      onShowQrcode: () => _onShowQrcode(allowInvite),
                      onEditGroup: () => _onEditGroup(isManager),
                    ),
                    if (!quit) ...[
                      ImBarGroup(
                        children: [
                          ImSwitchBar(
                            title: '消息免打扰',
                            value: group.isDnd,
                            onChanged: _busy ? null : _onDndChange,
                          ),
                          ImSwitchBar(
                            title: '置顶聊天',
                            value: group.isTop,
                            onChanged: _busy ? null : _onTopChange,
                          ),
                        ],
                      ),
                      if (_hasChat)
                        ImBarGroup(
                          children: [
                            ImArrowBar(
                              title: '查找聊天记录',
                              onTap: _onChatHistory,
                            ),
                          ],
                        ),
                      if (allowShareCard)
                        ImBarGroup(
                          children: [
                            ImArrowBar(
                              title: '分享该群聊',
                              onTap: _onSendCard,
                            ),
                          ],
                        ),
                      if (showTools)
                        ImBarGroup(
                          children: [
                            ImArrowBar(
                              title: '群设置',
                              onTap: _onSetting,
                            ),
                            if (GroupPermissionUtil.canManageManagers(
                              mineId: mineId,
                              ownerId: group.ownerId,
                            ))
                              ImArrowBar(
                                title: '群管理员',
                                onTap: _onSetManager,
                              ),
                          ],
                        ),
                      _GroupBtnBarGroup(
                        children: [
                          _GroupBtnBar(
                            title: '发送消息',
                            primary: true,
                            onTap: _busy ? null : _onSendMessage,
                          ),
                          if (!isOwner)
                            _GroupBtnBar(
                              title: '退出群聊',
                              danger: true,
                              onTap: _busy ? null : _onQuitGroup,
                            ),
                          if (isOwner)
                            _GroupBtnBar(
                              title: '解散群聊',
                              danger: true,
                              onTap: _busy ? null : _onDissolveGroup,
                            ),
                        ],
                      ),
                    ] else
                      _GroupBtnBarGroup(
                        children: [
                          if (dissolved)
                            const _GroupBtnBar(title: '群聊已解散')
                          else
                            _GroupBtnBar(
                              title: '加入群聊',
                              primary: true,
                              onTap: _busy ? null : _onJoinGroup,
                            ),
                        ],
                      ),
                    SizedBox(height: rpx(context, 24)),
                  ],
                ),
    );
  }
}

/// 群资料表单区。对齐 group-info.vue `.form`（全宽白底行 + 3rpx 间隙）。
class _GroupInfoForm extends StatelessWidget {
  const _GroupInfoForm({
    required this.group,
    required this.quit,
    required this.ownerName,
    required this.onShowQrcode,
    required this.onEditGroup,
  });

  final Group group;
  final bool quit;
  final String ownerName;
  final VoidCallback onShowQrcode;
  final VoidCallback onEditGroup;

  @override
  Widget build(BuildContext context) {
    final notice = group.notice ?? '';
    final rows = <Widget>[
      _FlatFormRow(label: '群聊名称', value: group.name ?? ''),
      if (!quit) _FlatQrcodeRow(onTap: onShowQrcode),
      _FlatFormRow(label: '群主', value: ownerName),
      if (!quit && (group.remarkGroupName ?? '').isNotEmpty)
        _FlatFormRow(label: '群名备注', value: group.remarkGroupName!),
      if (!quit)
        _FlatFormRow(label: '我在本群的昵称', value: group.showNickName ?? ''),
    ];
    if (notice.isNotEmpty) {
      final noticeBlock = <Widget>[
        const _FlatNoticeLabelRow(),
        _FlatNoticeText(notice: notice),
      ];
      // 对齐 vue：notice-text 与 group-edit 同白底、无间隙
      if (!quit) noticeBlock.add(_FlatEditLink(onTap: onEditGroup));
      rows.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: noticeBlock,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1) SizedBox(height: rpx(context, 3)),
        ],
        if (!quit && notice.isEmpty) ...[
          SizedBox(height: rpx(context, 3)),
          _FlatEditLink(onTap: onEditGroup),
        ],
        SizedBox(height: rpx(context, 20)),
      ],
    );
  }
}

/// 群公告标题行。对齐 `.form-item.notice-item`（仅 label、无底间距）。
class _FlatNoticeLabelRow extends StatelessWidget {
  const _FlatNoticeLabelRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 40)),
      height: rpx(context, 100),
      alignment: Alignment.centerLeft,
      child: Text(
        '群公告',
        style: TextStyle(
          fontSize: rpx(context, 32),
          color: ImColors.text,
        ),
      ),
    );
  }
}

class _FlatFormRow extends StatelessWidget {
  const _FlatFormRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 40)),
      height: rpx(context, 100),
      alignment: Alignment.center,
      child: Row(
        children: [
          SizedBox(
            width: rpx(context, 220),
            child: Text(
              label,
              style: TextStyle(
                fontSize: rpx(context, 32),
                color: ImColors.text,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: rpx(context, 30),
                color: ImColors.textLighter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatQrcodeRow extends StatelessWidget {
  const _FlatQrcodeRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: rpx(context, 104),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: rpx(context, 24)),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
                    child: Text(
                      '群二维码',
                      style: TextStyle(
                        fontSize: rpx(context, 32),
                        color: ImColors.text,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.qr_code_2_outlined,
                  size: rpx(context, 36),
                  color: ImColors.textLighter,
                ),
                SizedBox(width: rpx(context, 6)),
                Icon(
                  Icons.chevron_right,
                  size: rpx(context, 30),
                  color: const Color(0xFFC4C4D0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlatNoticeText extends StatelessWidget {
  const _FlatNoticeText({required this.notice});

  final String notice;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 40)),
      child: Text(
        notice,
        style: TextStyle(
          fontSize: rpx(context, 32),
          color: ImColors.textLighter,
          height: 50 / 32,
        ),
      ),
    );
  }
}

class _FlatEditLink extends StatelessWidget {
  const _FlatEditLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: rpx(context, 20)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '修改群聊资料',
                style: TextStyle(
                  fontSize: rpx(context, 30),
                  color: ImColors.textLighter,
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: rpx(context, 28),
                color: ImColors.textLighter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 群成员横向网格。对齐 group-info.vue `.group-members`。
class _MemberGrid extends StatelessWidget {
  const _MemberGrid({
    required this.members,
    required this.maxCount,
    required this.showInvite,
    required this.showRemove,
    required this.showMutedTools,
    required this.onMemberTap,
    required this.onInvite,
    required this.onRemove,
    required this.onMuted,
    required this.onUnmuted,
    required this.onShowAll,
  });

  final List<GroupMember> members;
  final int maxCount;
  final bool showInvite;
  final bool showRemove;
  final bool showMutedTools;
  final void Function(GroupMember member) onMemberTap;
  final VoidCallback onInvite;
  final VoidCallback onRemove;
  final VoidCallback onMuted;
  final VoidCallback onUnmuted;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    final visible = members.take(maxCount).toList();

    return Container(
      margin: EdgeInsets.only(bottom: rpx(context, 20)),
      padding: EdgeInsets.all(rpx(context, 30)),
      color: Colors.white,
      child: Column(
        children: [
          Wrap(
            spacing: rpx(context, 4),
            runSpacing: 0,
            children: [
              for (final m in visible)
                _MemberTile(
                  member: m,
                  onTap: () => onMemberTap(m),
                ),
              if (showInvite)
                _ToolTile(
                  icon: Icons.add,
                  label: '邀请',
                  onTap: onInvite,
                ),
              if (showRemove)
                _ToolTile(
                  icon: Icons.remove,
                  label: '移除',
                  onTap: onRemove,
                ),
              if (showMutedTools) ...[
                _ToolTile(
                  icon: Icons.volume_off_outlined,
                  label: '禁言',
                  onTap: onMuted,
                ),
                _ToolTile(
                  icon: Icons.volume_up_outlined,
                  label: '取消禁言',
                  onTap: onUnmuted,
                ),
              ],
            ],
          ),
          Material(
            color: Colors.white,
            child: InkWell(
              onTap: onShowAll,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  rpx(context, 10),
                  rpx(context, 10),
                  rpx(context, 10),
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '查看全部群成员${members.length}人',
                      style: TextStyle(
                        fontSize: rpx(context, 30),
                        color: ImColors.textLighter,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: rpx(context, 28),
                      color: ImColors.textLighter,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.onTap,
  });

  final GroupMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemWidth = rpx(context, 120);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          rpx(context, 2),
          rpx(context, 8),
          rpx(context, 2),
          rpx(context, 8),
        ),
        child: SizedBox(
          width: itemWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HeadImage(
                url: member.headImage,
                name: member.showNickName,
                size: 84,
                online: member.online,
              ),
              Padding(
                padding: EdgeInsets.all(rpx(context, 8)),
                child: Text(
                  member.showNickName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rpx(context, 26),
                    color: ImColors.textLight,
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

/// 工具按钮。对齐 `.tools-btn`（85rpx 圆、边框、bgActive）。
class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemWidth = rpx(context, 120);
    final btnSize = rpx(context, 85);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          rpx(context, 2),
          rpx(context, 8),
          rpx(context, 2),
          rpx(context, 8),
        ),
        child: SizedBox(
          width: itemWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: btnSize,
                height: btnSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ImColors.bgActive,
                  border: Border.all(color: ImColors.border, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: rpx(context, 40),
                  color: ImColors.textLight,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(rpx(context, 8)),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rpx(context, 26),
                    color: ImColors.textLight,
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

/// 操作按钮组。对齐 bar-group.vue 内 btn-bar（无行间分隔线、100rpx 高）。
class _GroupBtnBarGroup extends StatelessWidget {
  const _GroupBtnBarGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        rpx(context, 24),
        0,
        rpx(context, 24),
        rpx(context, 24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rpx(context, 24)),
        boxShadow: [
          BoxShadow(
            color: ImColors.accent.withValues(alpha: 0.06),
            blurRadius: rpx(context, 24),
            offset: Offset(0, rpx(context, 6)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// 全宽操作按钮。对齐 btn-bar.vue（primary / danger、100rpx、font-large w600）。
class _GroupBtnBar extends StatelessWidget {
  const _GroupBtnBar({
    required this.title,
    this.primary = false,
    this.danger = false,
    this.onTap,
  });

  final String title;
  final bool primary;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? ImColors.textLighter
        : danger
            ? ImColors.danger
            : primary
                ? ImColors.accent
                : ImColors.text;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: rpx(context, 100),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: rpx(context, 34),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
