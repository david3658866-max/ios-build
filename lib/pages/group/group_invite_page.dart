import 'dart:async';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/constants/ui_timing.dart';
import '../../core/http/api_result.dart';
import '../../core/utils/group_permission_util.dart';
import '../../models/friend.dart';
import '../../stores/friend_store.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/friend/friend_item.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_form.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_search_bar.dart';

/// 邀请好友入群。对齐 group-invite.vue。
class GroupInvitePage extends ConsumerStatefulWidget {
  const GroupInvitePage({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<GroupInvitePage> createState() => _GroupInvitePageState();
}

class _InviteFriend {
  _InviteFriend({
    required this.friend,
    required this.disabled,
    required this.checked,
  });

  final Friend friend;
  final bool disabled;
  bool checked;
}

class _GroupInvitePageState extends ConsumerState<GroupInvitePage> {
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  List<_InviteFriend> _items = const [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tryPrefillFromStore();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  /// 对齐 uniapp onLoad：从 store 取群成员并初始化好友勾选。
  void _tryPrefillFromStore() {
    final store = ref.read(groupStoreProvider.notifier);
    if (store.byId(widget.groupId) == null) return;
    if (ref.read(friendStoreProvider).friends.isEmpty) return;
    _initItems();
    _loading = false;
  }

  Future<void> _load() async {
    if (widget.groupId <= 0) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      if (ref.read(friendStoreProvider).friends.isEmpty) {
        await ref.read(friendStoreProvider.notifier).loadFriends();
      }
      final store = ref.read(groupStoreProvider.notifier);
      var group = store.byId(widget.groupId);
      if (group == null) {
        group = await store.loadGroupDetail(widget.groupId);
      } else {
        unawaited(store.loadGroupDetail(widget.groupId));
      }
      if (!mounted) return;
      if (group == null || !GroupPermissionUtil.isActiveGroup(group)) {
        ImFeedback.toast(
          context,
          group?.dissolve == true ? '群聊已解散' : '您不在群聊中',
        );
        context.pop();
        return;
      }
      final members = store
          .membersOf(widget.groupId)
          .where((m) => !m.quit)
          .toList();
      final mineId = ref.read(userStoreProvider)?.id;
      if (!GroupPermissionUtil.canInviteMembers(
        group: group,
        members: members,
        mineId: mineId,
      )) {
        ImFeedback.toast(context, '本群禁止邀请好友');
        context.pop();
        return;
      }
      await store.loadMembers(widget.groupId);
      if (!mounted) return;
      setState(_initItems);
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, '加载失败: ${asApiException(e).message}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _initItems() {
    final memberIds = ref
        .read(groupStoreProvider.notifier)
        .membersOf(widget.groupId)
        .where((m) => !m.quit)
        .map((m) => m.userId)
        .toSet();
    final friends = ref.read(friendStoreProvider).friends;
    _items = friends
        .where((f) => !f.deleted)
        .map((f) {
          final disabled = memberIds.contains(f.id);
          return _InviteFriend(
            friend: f,
            disabled: disabled,
            checked: disabled,
          );
        })
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int get _inviteSize =>
      _items.where((f) => !f.disabled && f.checked).length;

  List<_InviteFriend> get _visibleItems {
    if (_searchText.isEmpty) return _items;
    return _items
        .where((f) => (f.friend.showNickName ?? '').contains(_searchText))
        .toList();
  }

  void _toggle(_InviteFriend item) {
    if (item.disabled) return;
    setState(() => item.checked = !item.checked);
  }

  Future<void> _invite() async {
    if (_busy || _inviteSize == 0) return;
    final friendIds = _items
        .where((f) => !f.disabled && f.checked)
        .map((f) => f.friend.id)
        .toList();
    setState(() => _busy = true);
    try {
      await ref.read(groupApiProvider).invite({
        'groupId': widget.groupId,
        'friendIds': friendIds,
      });
      await ref.read(groupStoreProvider.notifier).loadMembers(widget.groupId);
      if (!mounted) return;
      ImFeedback.toast(context, '邀请成功');
      await Future<void>.delayed(UiTiming.toastThenNavigate);
      if (!mounted) return;
      context.pop();
    } on ApiException catch (e) {
      if (mounted && !e.silent) {
        ImFeedback.toast(context, e.message);
      }
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
    if (widget.groupId <= 0) {
      return Scaffold(
        backgroundColor: ImColors.pageBg,
        appBar: const ImNavBar(title: '邀请', showBack: true),
        body: const Center(child: Text('群聊不存在')),
      );
    }

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '邀请', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ImSearchBar(
                  controller: _searchCtrl,
                  placeholder: '输入好友昵称搜索',
                  autofocus: false,
                  onChanged: (v) => setState(() => _searchText = v),
                ),
                Expanded(
                  child: _visibleItems.isEmpty
                      ? Center(
                          child: Text(
                            '暂无可邀请的好友',
                            style: TextStyle(
                              fontSize: rpx(context, 28),
                              color: ImColors.textLighter,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _visibleItems.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 0.5,
                            thickness: 0.5,
                            color: ImColors.formDivider,
                          ),
                          itemBuilder: (_, i) {
                            final item = _visibleItems[i];
                            return FriendItem(
                              friend: item.friend,
                              onTap: () => _toggle(item),
                              trailing: Padding(
                                padding:
                                    EdgeInsets.only(right: rpx(context, 20)),
                                child: ImRadioOption(
                                  label: '',
                                  value: 1,
                                  groupValue: item.checked ? 1 : 0,
                                  onChanged: item.disabled
                                      ? (_) {}
                                      : (_) => _toggle(item),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  width: double.infinity,
                  color: ImColors.pageBg,
                  padding: EdgeInsets.all(rpx(context, 30)),
                  child: GestureDetector(
                    onTap: _inviteSize == 0 || _busy ? null : _invite,
                    child: Container(
                      height: rpx(context, 88),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _inviteSize == 0 || _busy
                            ? ImColors.accent.withValues(alpha: 0.5)
                            : ImColors.accent,
                        borderRadius: BorderRadius.circular(rpx(context, 8)),
                      ),
                      child: _busy
                          ? SizedBox(
                              width: rpx(context, 36),
                              height: rpx(context, 36),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              '邀请($_inviteSize)',
                              style: TextStyle(
                                fontSize: rpx(context, 32),
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
