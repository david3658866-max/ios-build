import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_providers.dart';
import '../../core/utils/teenager_mode_util.dart';
import '../../models/group.dart';
import '../../router/app_router.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/group/group_empty_tip.dart';
import '../../widgets/group/group_item.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_search_bar.dart';

/// 我的群聊。对齐 im-uniapp pages/group/group.vue。
class GroupListPage extends ConsumerStatefulWidget {
  const GroupListPage({super.key});

  @override
  ConsumerState<GroupListPage> createState() => _GroupListPageState();
}

class _GroupListPageState extends ConsumerState<GroupListPage> with RouteAware {
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeRoute();
      _loadGroups();
    });
  }

  @override
  void dispose() {
    imRouteObserver.unsubscribe(this);
    _searchCtrl.dispose();
    _searchFocus.dispose();
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
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      await ref.read(groupStoreProvider.notifier).loadGroups();
    } catch (e) {
      if (mounted) _snack('加载群聊失败');
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      _searchCtrl.clear();
    });
    if (_showSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  bool _isAdvancedUser() {
    return ref.read(userStoreProvider)?.userIdentity == 1;
  }

  void _onCreateNewGroup() {
    final enabled = TeenagerModeUtil.isEnabled(
      userId: ref.read(userStoreProvider)?.id,
      kv: ref.read(kvStoreProvider),
    );
    if (guardTeenagerFeature(
      teenagerModeEnabled: enabled,
      feature: TeenagerBlockFeature.createGroup,
      onBlocked: _snack,
    )) {
      return;
    }
    if (!_isAdvancedUser()) {
      _snack('普通用户暂不能创建群聊');
      return;
    }
    context.push(AppRoutes.groupCreate);
  }

  bool _hasGroups(List<Group> groups) {
    return groups.any((g) => !g.quit);
  }

  List<Group> _showGroups(List<Group> groups, String searchText) {
    return groups.where((g) {
      if (g.quit) return false;
      return (g.showGroupName ?? '').contains(searchText);
    }).toList();
  }

  void _snack(String msg) {
    ImFeedback.toast(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupStoreProvider);
    final isAdvancedUser = ref.watch(userStoreProvider)?.userIdentity == 1;
    final hasGroups = _hasGroups(groups);
    final showGroups = _showGroups(groups, _searchCtrl.text.trim());

    return Scaffold(
      backgroundColor: ImColors.navBarBg,
      appBar: ImNavBar(
        title: '我的群聊',
        showBack: true,
        showSearch: true,
        onSearch: _toggleSearch,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            iconSize: rpx(context, 48),
            onPressed: _onCreateNewGroup,
          ),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: Size.fromHeight(rpx(context, 100)),
                child: ImSearchBar(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  placeholder: '点击搜索群聊',
                  onChanged: (_) => setState(() {}),
                ),
              )
            : null,
      ),
      body: hasGroups
          ? ColoredBox(
              color: Colors.white,
              child: ListView.builder(
                itemCount: showGroups.length,
                itemBuilder: (context, index) {
                  final group = showGroups[index];
                  return GroupItem(
                    group: group,
                    onTap: () => context.push(AppRoutes.groupInfoPath(group.id)),
                  );
                },
              ),
            )
          : GroupEmptyTip(
              showCreateButton: isAdvancedUser,
              onCreate: _onCreateNewGroup,
            ),
    );
  }
}
