import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/http/api_result.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../router/app_router.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/group/group_member_item.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_search_bar.dart';

/// 群成员列表。对齐 group-member.vue。
class GroupMemberPage extends ConsumerStatefulWidget {
  const GroupMemberPage({super.key, required this.groupId});

  final int groupId;

  @override
  ConsumerState<GroupMemberPage> createState() => _GroupMemberPageState();
}

class _GroupMemberPageState extends ConsumerState<GroupMemberPage> {
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (ref.read(groupStoreProvider.notifier).byId(widget.groupId) != null) {
      _loading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = ref.read(groupStoreProvider.notifier);
    try {
      await store.loadGroupDetail(widget.groupId);
      await store.loadMembers(widget.groupId);
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
        .where((m) => (m.showNickName ?? '').contains(_searchText))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final group = _resolveGroup();
    final members = _resolveMembers();
    final mineId = ref.watch(userStoreProvider)?.id;

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '群成员', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ImSearchBar(
                  controller: _searchCtrl,
                  placeholder: '输入昵称搜索',
                  autofocus: false,
                  onChanged: (v) => setState(() => _searchText = v),
                ),
                Expanded(
                  child: members.isEmpty
                      ? Center(
                          child: Text(
                            _searchText.isEmpty ? '暂无群成员' : '未找到匹配成员',
                            style: TextStyle(
                              fontSize: rpx(context, 28),
                              color: ImColors.textLighter,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (_, i) => Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  i < members.length - 1 ? rpx(context, 1) : 0,
                            ),
                            child: GroupMemberItem(
                              member: members[i],
                              group: group,
                              mineId: mineId,
                              onTap: () => context.push(
                                AppRoutes.friendUserPath(members[i].userId),
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
