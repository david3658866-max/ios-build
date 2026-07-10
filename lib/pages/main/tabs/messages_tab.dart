import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/chat_list_util.dart';
import '../../../core/utils/teenager_mode_util.dart';
import '../../../core/utils/chat_item_util.dart';
import '../../../core/di/app_providers.dart';
import '../../../services/badge_service.dart';
import '../../../core/enums/chat_type.dart';
import '../../../core/storage/app_database.dart' hide Friend;
import '../../../core/utils/app_logger.dart';
import '../../../services/auth_controller.dart';
import '../../../models/friend.dart';
import '../../../stores/chat_store.dart';
import '../../../stores/config_store.dart';
import '../../../stores/friend_store.dart';
import '../../../stores/group_store.dart';
import '../../../stores/user_store.dart';
import '../../../router/app_router.dart';
import '../../../theme/im_colors.dart';
import '../../../theme/im_icons.dart';
import '../../../theme/rpx.dart';
import '../../../widgets/chat/chat_item.dart';
import '../../../widgets/im_confirm_dialog.dart';
import '../../../widgets/im_drop_down_menu.dart';
import '../../../widgets/im_long_press_menu.dart';
import '../../../widgets/im_search_bar.dart';
import '../../../widgets/line_switcher.dart';
import '../../../widgets/im_nav_bar.dart';
import '../../../widgets/im_icon.dart';
import '../../../widgets/im_no_data_tip.dart';
import '../../../widgets/im_feedback.dart';
import '../../../core/http/api_result.dart';

/// 消息 Tab。对齐 pages/chat/chat.vue + chat-item。
class MessagesTab extends ConsumerStatefulWidget {
  const MessagesTab({super.key});

  @override
  ConsumerState<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends ConsumerState<MessagesTab> {
  static const int _baseWindowSize = 30;
  static const int _minWindowStep = 20;
  static const int _maxWindowStep = 60;
  static const double _estimatedItemExtentPx = 72;
  static const double _loadTriggerViewportRatio = 0.25;
  static const double _minLoadTriggerPx = 160;
  static const double _maxLoadTriggerPx = 320;
  static const int _searchCountProbeLimit = 500;

  bool _showSearch = false;
  bool _wasVisible = false;
  bool _loggedInitDiag = false;
  final _searchCtrl = TextEditingController();
  final _listCtrl = ScrollController();
  int _showMaxIdx = _baseWindowSize;
  String _lastSearchText = '';
  bool _touchMoved = false;
  bool _expandingWindow = false;
  Timer? _searchDebounce;
  String _appliedSearchText = '';

  static const _dropMenuItems = [
    ImDropDownMenuItem(
      key: 'ADD_FRIEND',
      name: '添加好友',
      icon: ImIcons.addFriend,
    ),
    ImDropDownMenuItem(
      key: 'CREATE_GROUP',
      name: '创建群聊',
      icon: ImIcons.createGroup,
    ),
    ImDropDownMenuItem(key: 'SCAN', name: '扫 一 扫', icon: ImIcons.scan),
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_handleSearchChanged);
    _listCtrl.addListener(_onListScroll);
  }

  /// 对齐 chat.vue onShow：切回消息 Tab 时刷新角标与线路状态。
  void _onTabShow() {
    if (!mounted) return;
    ref
        .read(lineProvider.notifier)
        .checkCurrentLineStatus(allowFallback: false);
    refreshFriendBadge(ref);
    refreshChatBadge(ref);
  }

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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _listCtrl.removeListener(_onListScroll);
    _listCtrl.dispose();
    _searchCtrl.removeListener(_handleSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  int _windowStep() {
    if (!_listCtrl.hasClients) return _baseWindowSize;
    final viewport = _listCtrl.position.viewportDimension;
    final estimatedVisible = (viewport / _estimatedItemExtentPx).ceil();
    final step = estimatedVisible * 3;
    return step.clamp(_minWindowStep, _maxWindowStep);
  }

  double _loadTriggerExtent() {
    if (!_listCtrl.hasClients) return _minLoadTriggerPx;
    final viewport = _listCtrl.position.viewportDimension;
    final dynamicThreshold = viewport * _loadTriggerViewportRatio;
    return dynamicThreshold.clamp(_minLoadTriggerPx, _maxLoadTriggerPx);
  }

  void _handleSearchChanged() {
    final current = _searchCtrl.text.trim();
    if (current == _lastSearchText) return;
    _lastSearchText = current;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _applySearchText(current, fromDebounce: true);
    });
  }

  void _applySearchText(String next, {bool fromDebounce = false}) {
    if (!mounted || next == _appliedSearchText) return;
    final shouldJumpTop = _appliedSearchText.isEmpty != next.isEmpty;
    setState(() {
      _appliedSearchText = next;
      _showMaxIdx = _baseWindowSize;
    });
    if (shouldJumpTop && _listCtrl.hasClients) {
      if (fromDebounce) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _listCtrl.hasClients) _listCtrl.jumpTo(0);
        });
      } else {
        _listCtrl.jumpTo(0);
      }
    }
  }

  void _onListScroll() {
    if (!_listCtrl.hasClients || _expandingWindow) return;
    if (_listCtrl.position.extentAfter >= _loadTriggerExtent()) return;
    final searchText = _appliedSearchText;
    int total;
    if (searchText.isEmpty) {
      total = ref.read(chatCountStreamProvider).value ?? 0;
    } else {
      final chats = ref
          .read(
            chatListSearchProvider(
              ChatListSearchQuery(
                keyword: searchText,
                limit: _searchCountProbeLimit,
              ),
            ),
          )
          .value;
      if (chats == null) return;
      total = chats.length;
    }
    if (_showMaxIdx >= total) return;
    _expandingWindow = true;
    try {
      if (!mounted) return;
      setState(() {
        final next = _showMaxIdx + _windowStep();
        _showMaxIdx = next > total ? total : next;
      });
    } finally {
      _expandingWindow = false;
    }
  }

  String? _statusMessage(ConfigState cfg) {
    final auth = ref.watch(authControllerProvider);
    final msg = messagesTabStatusMessage(
      appInit: cfg.appInit,
      chatSyncLoading: cfg.chatSyncLoading,
      wsStatus: cfg.wsStatus,
      lineStatus: cfg.lineStatus,
      isAuthenticated: auth == AuthStatus.authenticated,
    );
    if (msg != null) {
      log.i(
        '[MsgTab] status="$msg" auth=$auth appInit=${cfg.appInit} '
        'syncLoading=${cfg.chatSyncLoading} line=${cfg.lineStatus} ws=${cfg.wsStatus}',
      );
    }
    return msg;
  }

  void _toast(String msg) => ImFeedback.toast(context, msg);

  bool _guardTeenager(TeenagerBlockFeature feature) {
    final enabled = TeenagerModeUtil.isEnabled(
      userId: ref.read(userStoreProvider)?.id,
      kv: ref.read(kvStoreProvider),
    );
    return guardTeenagerFeature(
      teenagerModeEnabled: enabled,
      feature: feature,
      onBlocked: _toast,
    );
  }

  Future<void> _showDropDownMenu() async {
    final key = await ImDropDownMenu.show(context, items: _dropMenuItems);
    if (!mounted || key == null) return;
    switch (key) {
      case 'ADD_FRIEND':
        if (_guardTeenager(TeenagerBlockFeature.addFriend)) return;
        context.push(AppRoutes.friendAdd);
      case 'CREATE_GROUP':
        _createNewGroup();
      case 'SCAN':
        if (_guardTeenager(TeenagerBlockFeature.scan)) return;
        context.push(AppRoutes.scan);
    }
  }

  void _createNewGroup() {
    if (_guardTeenager(TeenagerBlockFeature.createGroup)) return;
    // 对齐 chat.vue createNewGroup：消息页入口不做 userIdentity 前端拦截。
    context.push(AppRoutes.groupCreate);
  }

  Future<void> _onChatLongPress(Chat chat, Offset anchor) async {
    if (!shouldOpenChatLongPressMenu(touchMoved: _touchMoved)) return;
    final action = await ImLongPressMenu.show(
      context,
      anchor: anchor,
      items: [
        ImLongPressMenuItem(key: 'DELETE', name: '删除该聊天', danger: true),
        ImLongPressMenuItem(key: 'TOP', name: chat.isTop ? '取消置顶' : '置顶该聊天'),
        ImLongPressMenuItem(key: 'DND', name: chat.isDnd ? '新消息提醒' : '消息免打扰'),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'DELETE':
        await _removeChat(chat);
      case 'TOP':
        await _toggleTop(chat);
      case 'DND':
        await _toggleDnd(chat);
    }
  }

  Future<void> _removeChat(Chat chat) async {
    final ok = await showImConfirmDialog(
      context,
      title: '确认删除',
      content: "确认删除'${chat.showName ?? ''}'的聊天记录?",
      confirmText: '确认',
    );
    if (ok != true) return;
    await ref.read(chatStoreProvider).removeChat(chat.type, chat.targetId);
  }

  Future<void> _toggleDnd(Chat chat) async {
    final next = !chat.isDnd;
    try {
      if (chat.type == ChatType.private) {
        await ref
            .read(friendStoreProvider.notifier)
            .setDnd(chat.targetId, next);
      } else if (chat.type == ChatType.group) {
        await ref.read(groupStoreProvider.notifier).setDnd(chat.targetId, next);
      } else {
        await ref
            .read(chatStoreProvider)
            .setDnd(chat.type, chat.targetId, next);
      }
    } catch (e) {
      if (mounted) _toast('操作失败，请稍后重试');
    }
  }

  Future<void> _toggleTop(Chat chat) async {
    final next = !chat.isTop;
    try {
      if (chat.type == ChatType.private) {
        await ref
            .read(friendStoreProvider.notifier)
            .setTop(chat.targetId, next);
      } else if (chat.type == ChatType.group) {
        await ref.read(groupStoreProvider.notifier).setTop(chat.targetId, next);
      } else {
        await ref
            .read(chatStoreProvider)
            .setTop(chat.type, chat.targetId, next);
      }
    } catch (e) {
      if (mounted) _toast('操作失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTabVisible());

    final cfg = ref.watch(configStoreProvider);
    final status = _statusMessage(cfg);
    final auth = ref.watch(authControllerProvider);
    if (!_loggedInitDiag && !cfg.appInit) {
      _loggedInitDiag = true;
      log.i(
        '[MsgTab] diag appInit=false auth=$auth sync=${cfg.chatSyncLoading} '
        'line=${cfg.lineStatus} ws=${cfg.wsStatus} status=$status',
      );
    }
    final searchText = _appliedSearchText;
    final searchQuery = searchText.isEmpty
        ? null
        : ChatListSearchQuery(keyword: searchText, limit: _showMaxIdx);
    final chatAsync = searchQuery == null
        ? ref.watch(chatListWindowProvider(_showMaxIdx))
        : ref.watch(chatListSearchProvider(searchQuery));
    final friends = ref.watch(friendStoreProvider).friends;
    final friendById = <int, Friend>{for (final f in friends) f.id: f};

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: ImNavBar(
        title: '消息',
        titleAlign: TextAlign.left,
        titleExtra: const LineSwitcher(),
        showSearch: true,
        onSearch: () {
          setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) {
              _searchCtrl.clear();
              _searchDebounce?.cancel();
              _applySearchText('');
            }
          });
        },
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: rpx(context, 8)),
            child: IconButton(
              icon: ImIcon(ImIcons.add, color: ImColors.text),
              iconSize: rpx(context, 48),
              onPressed: _showDropDownMenu,
            ),
          ),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: Size.fromHeight(rpx(context, 100)),
                child: ImSearchBar(
                  controller: _searchCtrl,
                  placeholder: '搜索',
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                ),
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status != null) _StatusTip(message: status),
          Expanded(
            child: chatAsync.when(
              loading: () {
                if (searchQuery != null) {
                  final cached = ref
                      .read(chatListSearchProvider(searchQuery))
                      .value;
                  if (cached != null) {
                    return _buildChatList(
                      context: context,
                      chats: cached,
                      friendById: friendById,
                    );
                  }
                }
                return const _ListLoading();
              },
              error: (e, _) => _ListError(message: asApiException(e).message),
              data: (filtered) {
                if (status == null && searchText.isEmpty && filtered.isEmpty) {
                  return const ColoredBox(
                    color: ImColors.navBarBg,
                    child: _EmptyChatTip(),
                  );
                }
                if (filtered.isEmpty) {
                  return ColoredBox(
                    color: ImColors.navBarBg,
                    child: searchText.isNotEmpty
                        ? ImNoDataTip(tip: "未搜索到与'$searchText'相关的会话")
                        : const _ListLoading(),
                  );
                }
                return _buildChatList(
                  context: context,
                  chats: filtered,
                  friendById: friendById,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(Chat chat) {
    if (chat.type == ChatType.system) {
      context.push(AppRoutes.chatSystem);
      return;
    }
    context.push(AppRoutes.chatPath(chat.type, chat.targetId));
  }

  Widget _buildChatList({
    required BuildContext context,
    required List<Chat> chats,
    required Map<int, Friend> friendById,
  }) {
    return Listener(
      onPointerUp: (_) => _touchMoved = false,
      onPointerCancel: (_) => _touchMoved = false,
      onPointerMove: (_) => _touchMoved = true,
      child: ColoredBox(
        color: ImColors.navBarBg,
        child: ListView.builder(
          controller: _listCtrl,
          itemExtent: rpx(context, 120),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final online = chat.type == ChatType.private
                ? (friendById[chat.targetId]?.online ?? false)
                : false;
            return ChatItem(
              key: ValueKey('chat_${chat.type}_${chat.targetId}'),
              chat: chat,
              searchKeyword: _appliedSearchText,
              online: online,
              onTap: () => _openChat(chat),
              onLongPress: (pos) => _onChatLongPress(chat, pos),
            );
          },
        ),
      ),
    );
  }
}

class _StatusTip extends StatelessWidget {
  const _StatusTip({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, 24),
        vertical: rpx(context, 12),
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: rpx(context, 40),
            height: rpx(context, 40),
            child: CircularProgressIndicator(
              strokeWidth: rpx(context, 3),
              color: ImColors.accent,
            ),
          ),
          SizedBox(width: rpx(context, 14)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: rpx(context, 28),
              color: ImColors.textLighter,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListLoading extends StatelessWidget {
  const _ListLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '会话列表加载中…',
        style: TextStyle(
          fontSize: rpx(context, 28),
          color: ImColors.textLighter,
        ),
      ),
    );
  }
}

class _ListError extends StatelessWidget {
  const _ListError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(rpx(context, 32)),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: rpx(context, 28),
            color: ImColors.textLight,
          ),
        ),
      ),
    );
  }
}

class _EmptyChatTip extends StatelessWidget {
  const _EmptyChatTip();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(rpx(context, 40)),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: rpx(context, 120),
                height: rpx(context, 120),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ImColors.emptyIconGradient,
                  border: Border.all(
                    color: ImColors.bgActive,
                    width: 1 / MediaQuery.devicePixelRatioOf(context),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: rpx(context, 12),
                      offset: Offset(0, rpx(context, 4)),
                    ),
                  ],
                ),
                child: ImIcon(
                  ImIcons.chat,
                  size: rpx(context, 60),
                  color: ImColors.textLighter,
                ),
              ),
              SizedBox(height: rpx(context, 40)),
              Text(
                '还没有聊天',
                style: TextStyle(
                  fontSize: rpx(context, 34),
                  fontWeight: FontWeight.w500,
                  color: ImColors.text,
                ),
              ),
              SizedBox(height: rpx(context, 20)),
              Text(
                '添加好友或创建群聊，开始精彩的对话吧',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rpx(context, 28),
                  color: ImColors.textLighter,
                  height: 1.6,
                ),
              ),
              SizedBox(height: rpx(context, 50)),
            ],
          ),
        ),
      ),
    );
  }
}
