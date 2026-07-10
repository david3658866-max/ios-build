import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/app_providers.dart';
import '../../../core/utils/friend_list_util.dart';
import '../../../core/utils/teenager_mode_util.dart';
import '../../../models/friend.dart';
import '../../../router/app_router.dart';
import '../../../services/badge_service.dart';
import '../../../stores/config_store.dart';
import '../../../stores/friend_store.dart';
import '../../../stores/user_store.dart';
import '../../../theme/im_colors.dart';
import '../../../theme/rpx.dart';
import '../../../widgets/friend/friend_empty_tip.dart';
import '../../../widgets/friend/friend_index_anchor.dart';
import '../../../widgets/friend/friend_item.dart';
import '../../../widgets/friend/friend_top_item.dart';
import '../../../theme/im_icons.dart';
import '../../../widgets/im_icon.dart';
import '../../../widgets/im_action_sheet.dart';
import '../../../widgets/im_nav_bar.dart';
import '../../../widgets/im_search_bar.dart';
import '../../../widgets/im_feedback.dart';

/// 通讯录 Tab。UI 骨架对齐 pages/friend/friend.vue（M3 填充好友列表）。
class ContactsTab extends ConsumerStatefulWidget {
  const ContactsTab({super.key});

  @override
  ConsumerState<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends ConsumerState<ContactsTab> {
  bool _showSearch = false;
  bool _autoRefreshed = false;
  bool _wasVisible = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  final _anchorKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  /// 对齐 friend.vue onShow：刷新角标，首次进入补拉好友列表。
  void _onTabShow() {
    if (!mounted) return;
    refreshFriendBadge(ref);
    refreshChatBadge(ref);
    _tryLoadFriends();
  }

  /// IndexedStack 非选中 Tab 包在 Offstage 中；对齐 friend.vue onShow。
  void _checkTabVisible() {
    if (!mounted) return;
    final offstage = context.findAncestorWidgetOfExactType<Offstage>();
    final visible = offstage == null || !offstage.offstage;
    if (visible && !_wasVisible) {
      _wasVisible = true;
      _onTabShow();
    } else if (!visible) {
      _wasVisible = false;
    }
  }

  void _tryLoadFriends() {
    if (!mounted || _autoRefreshed) return;
    if (!ref.read(configStoreProvider).appInit) return;
    _autoRefreshed = true;
    ref.read(friendStoreProvider.notifier).loadFriends();
  }

  void _toast(String msg) => ImFeedback.toast(context, msg);

  void _goAddFriend() {
    final enabled = TeenagerModeUtil.isEnabled(
      userId: ref.read(userStoreProvider)?.id,
      kv: ref.read(kvStoreProvider),
    );
    if (guardTeenagerFeature(
      teenagerModeEnabled: enabled,
      feature: TeenagerBlockFeature.addFriend,
      onBlocked: _toast,
    )) {
      return;
    }
    context.push(AppRoutes.friendAdd);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
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

  List<FriendGroup> _groupFriends(List<Friend> friends, String searchText) =>
      groupFriendsByPinyin(friends, searchText);

  void _scrollToAnchor(String indexKey) {
    final key = _anchorKeys[indexKey];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTabVisible());

    ref.listen(configStoreProvider, (prev, next) {
      if (next.appInit && !(prev?.appInit ?? false)) {
        _onTabShow();
      }
    });

    final friendState = ref.watch(friendStoreProvider);
    final friends = friendState.friends;
    final mineId = ref.watch(userStoreProvider)?.id;
    final recvCount = mineId == null
        ? 0
        : friendState.requests.where((r) => r.recvId == mineId).length;
    final hasFriends = hasVisibleFriends(friends);
    final groups = _groupFriends(friends, _searchCtrl.text.trim());
    _anchorKeys.removeWhere((k, _) => groups.every((g) => g.indexKey != k));

    ref.listen(friendStoreProvider, (prev, next) {
      refreshFriendBadge(ref);
    });

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: ImNavBar(
        title: '好友',
        titleAlign: TextAlign.left,
        showSearch: true,
        onSearch: _toggleSearch,
        actions: [
          IconButton(
            icon: ImIcon(ImIcons.add, size: rpx(context, 48)),
            onPressed: _goAddFriend,
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz),
            iconSize: rpx(context, 48),
            onPressed: _onMore,
          ),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: Size.fromHeight(rpx(context, 100)),
                child: ImSearchBar(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  placeholder: '点击搜索好友',
                  autofocus: true,
                ),
              )
            : null,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ListView(
            controller: _scrollCtrl,
            padding: EdgeInsets.only(
              right: hasFriends && groups.isNotEmpty && !_showSearch
                  ? rpx(context, 36)
                  : 0,
            ),
            children: [
              ColoredBox(
                color: ImColors.navBarBg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FriendTopItem.newFriend(
                      badgeCount: recvCount,
                      onTap: () => context.push(AppRoutes.friendRequests),
                    ),
                    FriendTopItem.myGroups(
                      onTap: () => context.push(AppRoutes.groupList),
                    ),
                  ],
                ),
              ),
              for (final group in groups) ...[
                FriendIndexAnchor(
                  key: _anchorKeys.putIfAbsent(
                    group.indexKey,
                    () => GlobalKey(),
                  ),
                  text: group.anchor,
                ),
                ColoredBox(
                  color: ImColors.navBarBg,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      rpx(context, 20),
                      0,
                      rpx(context, 20),
                      rpx(context, 8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final friend in group.friends)
                          FriendItem(
                            friend: friend,
                            onTap: () => context.push(
                              AppRoutes.friendUserPath(friend.id),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!hasFriends)
            Center(
              child: FriendEmptyTip(
                onAdd: _goAddFriend,
              ),
            ),
          if (hasFriends && groups.isNotEmpty && !_showSearch)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: rpx(context, 6)),
                  child: _FriendIndexBar(
                    groups: groups,
                    onTap: _scrollToAnchor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onMore() async {
    final index = await ImActionSheet.show(
      context,
      itemList: const ['手机通讯录'],
    );
    if (!mounted || index != 0) return;
    context.push(AppRoutes.friendContact);
  }
}

/// 右侧字母索引条。对齐 uview u-index-list__letter。
class _FriendIndexBar extends StatelessWidget {
  const _FriendIndexBar({
    required this.groups,
    required this.onTap,
  });

  final List<FriendGroup> groups;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final g in groups)
          GestureDetector(
            onTap: () => onTap(g.indexKey),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: rpx(context, 32),
              height: rpx(context, 32),
              margin: EdgeInsets.symmetric(vertical: rpx(context, 2)),
              alignment: Alignment.center,
              child: Text(
                g.indexKey == '*' ? '★' : g.indexKey,
                style: TextStyle(
                  fontSize: rpx(context, 24),
                  height: 1,
                  color: ImColors.text,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
