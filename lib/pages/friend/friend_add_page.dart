import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/http/api_result.dart';
import '../../models/user.dart';
import '../../router/app_router.dart';
import '../../stores/friend_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../widgets/friend/friend_add_user_row.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_no_data_tip.dart';
import '../../widgets/im_search_bar.dart';

/// 添加好友。对齐 friend-add.vue。
class FriendAddPage extends ConsumerStatefulWidget {
  const FriendAddPage({super.key, this.keyword});

  final String? keyword;

  @override
  ConsumerState<FriendAddPage> createState() => _FriendAddPageState();
}

class _FriendAddPageState extends ConsumerState<FriendAddPage> {
  final _searchCtrl = TextEditingController();
  List<User> _users = [];
  bool _searched = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchTextChanged);
    if (widget.keyword != null && widget.keyword!.isNotEmpty) {
      _searchCtrl.text = widget.keyword!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _onSearch());
    }
  }

  void _onSearchTextChanged() {
    if (_searched) {
      setState(() {
        _searched = false;
        _users = [];
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchTextChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch() async {
    final phone = _searchCtrl.text.trim();
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      ImFeedback.toast(context, '请输入正确的11位手机号');
      return;
    }
    setState(() => _loading = true);
    try {
      final users = await ref.read(userApiProvider).search(phone);
      if (!mounted) return;
      setState(() {
        _users = users;
        _searched = true;
      });
    } catch (e) {
      ImFeedback.toast(context, asApiException(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onAddFriend(User user) {
    if (user.id <= 0) {
      ImFeedback.toast(context, '用户信息无效');
      return;
    }
    final store = ref.read(friendStoreProvider.notifier);
    if (store.isFriend(user.id)) {
      ImFeedback.toast(context, '对方已是您的好友');
      return;
    }
    context.push(AppRoutes.friendApplyPath(user.id));
  }

  @override
  Widget build(BuildContext context) {
    final selfId = ref.watch(userStoreProvider)?.id;
    final friendState = ref.watch(friendStoreProvider);
    final friendStore = ref.read(friendStoreProvider.notifier);
    final query = _searchCtrl.text.trim();

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: ImNavBar(
        title: '添加好友',
        showBack: true,
      ),
      body: Column(
        children: [
          ImSearchBar(
            controller: _searchCtrl,
            placeholder: '请输入完整手机号搜索',
            onConfirm: _onSearch,
            onCancel: () => context.pop(),
            loading: _loading,
            autofocus: true,
          ),
          Expanded(
            child: _searched && _users.isEmpty
                ? ImNoDataTip(tip: "未搜索到与'$query'相关的用户")
                : ColoredBox(
                    color: ImColors.pageBg,
                    child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final user = _users[i];
                      if (user.id == selfId) return const SizedBox.shrink();
                      final isFriend = friendState.friends.any(
                        (f) => f.id == user.id && !f.deleted,
                      );
                      final pending = friendStore.isPendingRequest(user.id);
                      return FriendAddUserRow(
                        user: user,
                        searchText: query,
                        isFriend: isFriend,
                        pending: pending,
                        onTap: () =>
                            context.push(AppRoutes.friendUserPath(user.id)),
                        onAdd: () => _onAddFriend(user),
                      );
                    },
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
