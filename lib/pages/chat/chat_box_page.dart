import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_providers.dart';
import '../../core/di/app_providers.dart';
import '../../core/enums/chat_type.dart';
import '../../core/enums/message_status.dart';
import '../../core/enums/message_type.dart';
import '../../core/http/api_result.dart';
import '../../core/storage/app_database.dart' hide Group, Friend;
import '../../core/utils/chat_file_picker_util.dart';
import '../../core/utils/chat_image_picker_util.dart';
import '../../core/utils/chat_media_util.dart';
import '../../core/utils/chat_message_window_util.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/chat_nav_util.dart';
import '../../core/utils/group_sender_util.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/emotion_util.dart';
import '../../core/utils/file_download_util.dart';
import '../../core/utils/media_permission_util.dart';
import '../../core/utils/message_long_press_util.dart';
import '../../core/utils/quote_message_util.dart';
import '../../core/utils/rtc_call_util.dart';
import '../../core/utils/teenager_mode_util.dart';
import '../../router/app_router.dart';
import '../../services/rtc_service.dart';
import '../../stores/friend_store.dart';
import '../../services/offline_sync.dart';
import '../../stores/chat_store.dart';
import '../../models/group.dart';
import '../../models/friend.dart';
import '../../models/user.dart';
import '../../stores/config_store.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/im_icons.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/act_rt_message_bubble.dart';
import '../../widgets/chat/audio_message_bubble.dart';
import '../../widgets/chat/bubbles/text_bubble.dart';
import '../../widgets/chat/card_message_bubble.dart';
import '../../widgets/chat/financial_card_bubble.dart';
import '../../widgets/chat/chat_group_receipt_sheet.dart';
import '../../widgets/chat/chat_receipt_badge.dart';
import '../../widgets/chat/chat_top_message_bar.dart';
import '../../widgets/chat/chat_emotion_panel.dart';
import '../../widgets/chat/emotion_text_editing_controller.dart';
import '../../widgets/chat/chat_tools_panel.dart';
import '../../widgets/chat/chat_picker_sheet.dart';
import '../../widgets/chat/chat_message_menu.dart';
import '../../widgets/chat/chat_record_bar.dart';
import '../../widgets/chat/file_message_bubble.dart';
import '../../widgets/chat/image_message_bubble.dart';
import '../../widgets/chat/video_message_bubble.dart';
import '../../widgets/chat/chat_message_row.dart';
import '../../widgets/chat/group_rtc_join_sheet.dart';
import '../../widgets/chat/head_image.dart';
import '../../widgets/im_icon.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_bottom_action_sheet.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/group/group_member_selector.dart';
import '../../widgets/im_nav_bar.dart';

/// 底部面板 tab。对齐 uniapp `chatTabBox`。
enum _ChatPanelTab { none, tools, emo }

/// 自动滚底模式：首屏 / 跟滚 / 阅读历史 / 定位中。
enum _AutoScrollMode { initial, follow, reading, locating }

/// 私聊/群聊页。M2-4：文字收发 + 时间分隔 + 上拉加载历史。
class ChatBoxPage extends ConsumerStatefulWidget {
  const ChatBoxPage({
    super.key,
    required this.chatType,
    required this.targetId,
    this.locateMessageId,
  });

  final String chatType;
  final int targetId;
  final int? locateMessageId;

  @override
  ConsumerState<ChatBoxPage> createState() => _ChatBoxPageState();
}

class _ChatBoxPageState extends ConsumerState<ChatBoxPage> {
  static final Map<String, int> _recentOfflinePullAtMs = <String, int>{};
  static const Duration _offlinePullThrottleWindow = Duration(seconds: 8);
  static const Duration _topLoadDebounceDuration = Duration(milliseconds: 120);
  static const int _topLoadCooldownMs = 260;
  static const Duration _newMessageBadgeThrottle = Duration(milliseconds: 220);
  static const double _scrollTopLoadTriggerPx =
      ChatMessageWindowConfig.scrollTopThreshold + 12;

  final _inputCtrl = EmotionTextEditingController();
  final _inputFocus = FocusNode();
  // 首次进入时预设较大偏移，避免先渲染顶部再滚到底部的视觉滑动。
  final _scrollCtrl = ScrollController(initialScrollOffset: 1000000);
  int _messageLimit = ChatMessageWindowConfig.pageSize;
  ChatMessageWindowState _window = const ChatMessageWindowState();
  bool _loadingHistory = false;
  _ChatPanelTab _toolsOpen = _ChatPanelTab.none;
  double _prevMaxExtent = 0;
  List<int> _atUserIds = const [];
  Message? _quoteMessage;
  int? _pendingLocateId;
  bool _didLocate = false;
  bool _showRecord = false;
  bool _isReceipt = false;
  bool _isInBottom = true;
  int _newMessageSize = 0;
  int _prevMessageCount = 0;

  /// 用于区分「底部新消息」与「顶部历史扩读」（后者 last id 不变）。
  int? _prevLastMessageKey;
  List<Message>? _seedMessages;
  List<Message> _lastRecentMessages = const [];
  List<Message> _historyPrefixMessages = const [];
  bool _historyReachedStart = false;
  int? _activeMessageId;
  Timer? _highlightTimer;
  Timer? _lockScrollTimer;
  bool _lockScrollEvent = false;

  /// 首屏滚底完成前禁止触顶预加载，避免列表停在顶部并出现「回到底部」。
  bool _pendingInitialScroll = true;
  bool _didInitialBottom = false;
  _AutoScrollMode _autoScrollMode = _AutoScrollMode.initial;

  /// 滚底请求世代号：只让最后一次 `_scrollToBottom` 收尾，避免并发互相打断。
  int _scrollToBottomGen = 0;

  /// 定位进行中，避免 bootstrap / 离线完成并发扩读互相覆盖。
  Future<void>? _locateInFlight;
  int? _lastLocatedId;
  bool _locatePreferJump = false;
  final Map<int, GlobalKey> _messageItemKeys = <int, GlobalKey>{};
  int? _prependAnchorMessageKey;
  double? _prependAnchorDy;
  final Map<int, int> _fileDownloadProgress = {};
  final Set<String> _precacheImageKeys = <String>{};
  User? _targetUser;
  bool _seedBootstrapped = false;
  final int _viewEnterAtMs = DateTime.now().millisecondsSinceEpoch;
  bool _loggedFirstInteractive = false;
  Timer? _topLoadDebounceTimer;
  int _lastTopLoadAtMs = 0;
  Timer? _newMessageBadgeTimer;
  int _pendingNewMessageDelta = 0;

  @override
  void initState() {
    super.initState();
    _logViewMilestone('enter_init');
    // 不在此处设置 _pendingLocateId：否则 build 里 whenData(_tryLocateMessage)
    // 会在 forLocate 窗口就绪前用 bottomPage 误定位。
    _pendingInitialScroll = widget.locateMessageId == null;
    _autoScrollMode = widget.locateMessageId == null
        ? _AutoScrollMode.initial
        : _AutoScrollMode.locating;
    _inputCtrl.addListener(() => setState(() {}));
    _inputFocus.addListener(_onInputFocusChange);
    _scrollCtrl.addListener(_onScroll);
    _resetShowMessagesFromLocal();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onEnter());
  }

  /// 对齐 uniapp onLoad `resetShowMessages`：基于本地已有消息初始化窗口，不清空。
  void _resetShowMessagesFromLocal() {
    unawaited(_bootstrapLocalMessages());
  }

  Future<void> _bootstrapLocalMessages() async {
    try {
      final messages = await ref
          .read(chatStoreProvider)
          .readMessages(widget.chatType, widget.targetId, limit: _messageLimit);
      if (!mounted) return;
      setState(() {
        _seedMessages = messages;
        _lastRecentMessages = messages;
        _historyPrefixMessages = const [];
        _historyReachedStart = false;
        if (messages.isNotEmpty) {
          _window = ChatMessageWindowState.bottomPage(messages.length);
          _prevMessageCount = messages.length;
          _prevLastMessageKey = _messageKey(messages.last);
          _isInBottom = true;
          _newMessageSize = 0;
        }
      });
      log.i(
        '[ChatBox] bootstrap ${widget.chatType}/${widget.targetId} '
        'local=${messages.length} limit=$_messageLimit '
        'visible=${_window.windowSize(messages.length)}',
      );
      final locateId = widget.locateMessageId;
      if (locateId != null) {
        // 进页定位：必须扩读本地，不能只靠初始 80 条窗口。
        unawaited(_locateMessageById(locateId, quiet: true));
      } else if (messages.isNotEmpty) {
        _requestInitialScrollToBottom(messages.length);
      }
    } catch (e) {
      log.w(
        '[ChatBox] bootstrap local failed ${widget.chatType}/${widget.targetId}: $e',
      );
    } finally {
      if (mounted && !_seedBootstrapped) {
        setState(() => _seedBootstrapped = true);
      }
      _logViewMilestone('seed_ready', messageCount: _seedMessages?.length ?? 0);
      if (!_loggedFirstInteractive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _loggedFirstInteractive) return;
          _loggedFirstInteractive = true;
          _logViewMilestone(
            'first_interactive',
            messageCount: _currentMessagesSnapshot()?.length ?? 0,
          );
        });
      }
    }
  }

  String get _chatSyncKey => '${widget.chatType}:${widget.targetId}';

  bool _shouldThrottleOfflinePull() {
    if (widget.locateMessageId != null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _recentOfflinePullAtMs[_chatSyncKey];
    if (last != null &&
        now - last < _offlinePullThrottleWindow.inMilliseconds) {
      return true;
    }
    _recentOfflinePullAtMs[_chatSyncKey] = now;
    return false;
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _lockScrollTimer?.cancel();
    _topLoadDebounceTimer?.cancel();
    _newMessageBadgeTimer?.cancel();
    _inputFocus.dispose();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ImFeedback.toast(context, message);
  }

  void _logViewMilestone(String stage, {int? messageCount}) {
    final elapsed = DateTime.now().millisecondsSinceEpoch - _viewEnterAtMs;
    final msgCount = messageCount != null ? ' msgCount=$messageCount' : '';
    log.i(
      '[ChatBox][Perf] $stage ${widget.chatType}/${widget.targetId} '
      'elapsed=${elapsed}ms$msgCount',
    );
  }

  Future<void> _onEnter() async {
    try {
      unawaited(ref.read(lineProvider.notifier).checkCurrentLineStatus());

      if (!await _ensureChatSession()) {
        _toast('会话不存在或尚未加载');
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
        return;
      }

      final store = ref.read(chatStoreProvider);
      if (widget.chatType == ChatType.private) {
        unawaited(store.activePrivateChat(widget.targetId));
        unawaited(store.syncPrivateReadStatus(widget.targetId));
        unawaited(_loadPrivateFriendProfile());
      } else if (widget.chatType == ChatType.group) {
        unawaited(store.activeGroupChat(widget.targetId));
        unawaited(_loadGroupInfo());
      } else {
        await store.resetUnread(widget.chatType, widget.targetId);
      }

      if (_shouldThrottleOfflinePull()) {
        log.i(
          '[ChatBox] skip offline pull(throttled) '
          '${widget.chatType}/${widget.targetId}',
        );
      } else {
        unawaited(_pullOfflineAndFinish());
      }
    } catch (_) {
      // 离线拉取失败仍允许浏览本地消息
    } finally {
      if (mounted && _prevMessageCount > 0 && widget.locateMessageId == null) {
        _requestInitialScrollToBottom(_prevMessageCount);
      }
    }
  }

  Future<void> _loadPrivateFriendProfile() async {
    try {
      final user = await ref.read(userApiProvider).find(widget.targetId);
      if (!mounted) return;
      setState(() => _targetUser = user);
      await _syncPrivateContactFromUser(user);
    } catch (_) {}
  }

  Future<void> _loadGroupInfo() async {
    try {
      await ref.read(groupStoreProvider.notifier).loadMembers(widget.targetId);
      await ref
          .read(groupStoreProvider.notifier)
          .loadGroupDetail(widget.targetId);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  /// 对齐 uniapp `loadChatOfflineMessages().then(...)`：后台拉取，不阻塞首屏。
  Future<void> _pullOfflineAndFinish() async {
    _logViewMilestone('offline_pull_start');
    try {
      await ref
          .read(offlineSyncProvider)
          .pullChatOffline(
            chatType: widget.chatType,
            targetId: widget.targetId,
          );
      if (!mounted) return;

      final store = ref.read(chatStoreProvider);
      if (widget.chatType == ChatType.private) {
        await store.activePrivateChat(widget.targetId);
        await store.syncPrivateReadStatus(widget.targetId);
      } else if (widget.chatType == ChatType.group) {
        await store.activeGroupChat(widget.targetId);
      }

      final locateId = widget.locateMessageId;
      if (locateId != null) {
        // 离线补齐后再定位：目标消息可能刚入库。
        if (!_didLocate) {
          unawaited(_locateMessageById(locateId, quiet: true));
        }
        return;
      }
      // provider 尚在 loading 时回退 seed，避免误清首屏锁导致永不滚底。
      final messages = _currentMessagesSnapshot();
      if (messages != null && messages.isNotEmpty && mounted) {
        _prevMessageCount = messages.length;
        _prevLastMessageKey = _messageKey(messages.last);
        _requestInitialScrollToBottom(messages.length);
      } else if (mounted && _pendingInitialScroll) {
        // 本地暂无消息也要解除首屏锁，避免永远禁止触顶。
        setState(() => _pendingInitialScroll = false);
      }
      _logViewMilestone(
        'offline_pull_done',
        messageCount: messages?.length ?? 0,
      );
    } catch (_) {
      _logViewMilestone('offline_pull_failed');
      if (mounted && _pendingInitialScroll) {
        setState(() => _pendingInitialScroll = false);
      }
    }
  }

  /// 进入聊天前确保本地会话存在。对齐 uniapp onLoad chatIdx 守卫（Flutter 路由为 type/id）。
  Future<bool> _ensureChatSession() async {
    if (widget.targetId <= 0) return false;

    final store = ref.read(chatStoreProvider);
    final existing = await store.findChat(widget.chatType, widget.targetId);
    if (existing != null) return true;

    if (widget.chatType == ChatType.private) {
      final friendStore = ref.read(friendStoreProvider.notifier);
      final friend = friendStore.byId(widget.targetId);
      if (friend != null && !friend.deleted) {
        await store.openChat(
          type: ChatType.private,
          targetId: widget.targetId,
          showName: friend.showNickName,
          headImage: friend.headImage,
          companyName: friend.companyName,
          isDnd: friend.isDnd,
          isTop: friend.isTop,
        );
        return true;
      }
      return false;
    }

    if (widget.chatType == ChatType.group) {
      final group = ref.read(groupStoreProvider.notifier).byId(widget.targetId);
      if (group == null) return false;
      await store.openChat(
        type: ChatType.group,
        targetId: widget.targetId,
        showName: group.showGroupName ?? group.name,
        headImage: group.headImageThumb ?? group.headImage,
        isDnd: group.isDnd,
        isTop: group.isTop,
      );
      return true;
    }

    return false;
  }

  /// 对齐 uniapp loadFriend → updateFriendInfo（thumb 优先）。
  Future<void> _syncPrivateContactFromUser(User user) async {
    final store = ref.read(chatStoreProvider);
    final friendStore = ref.read(friendStoreProvider.notifier);
    final avatar = user.headImageThumb ?? user.headImage;
    if (friendStore.isFriend(widget.targetId)) {
      final friend = friendStore.byId(widget.targetId);
      if (friend == null) return;
      await store.updateContactProfile(
        type: ChatType.private,
        targetId: widget.targetId,
        showName: friend.showNickName,
        headImage: avatar ?? friend.headImage,
        companyName: friend.companyName,
      );
    } else {
      await store.syncChatFromUser(user);
    }
  }

  /// WS 重连后增量补拉当前会话（对齐断网期间在聊天页内的消息缺口）。
  Future<void> _onWsReconnected() async {
    await ref
        .read(offlineSyncProvider)
        .pullChatOffline(
          chatType: widget.chatType,
          targetId: widget.targetId,
          force: true,
        );
    if (!mounted) return;
    if (widget.chatType == ChatType.private) {
      await ref.read(chatStoreProvider).syncPrivateReadStatus(widget.targetId);
    }
    final messages = _currentMessagesSnapshot();
    if (messages != null && messages.isNotEmpty && _isInBottom && mounted) {
      setState(
        () => _window = ChatMessageWindowState.bottomPage(messages.length),
      );
      _requestScrollToBottom(reason: 'ws_reconnected', shrinkLimit: false);
    }
  }

  bool _canLoadMoreHistory(int total) {
    if (_window.showMinIdx > 0) return true;
    if (total <= 0) return false;
    return !_historyReachedStart;
  }

  void _beginHistoryLoading() {
    if (_loadingHistory) return;
    _prevMaxExtent = _scrollCtrl.hasClients
        ? _scrollCtrl.position.maxScrollExtent
        : 0;
    _capturePrependAnchor();
    setState(() => _loadingHistory = true);
  }

  void _endHistoryLoading() {
    if (!_loadingHistory) return;
    if (mounted) setState(() => _loadingHistory = false);
  }

  Future<void> _adjustScrollAfterPrepend() async {
    _setLockScrollEvent();
    await Future<void>.delayed(Duration.zero);
    if (!mounted || !_scrollCtrl.hasClients) return;
    if (!_restorePrependAnchor()) {
      final delta = _scrollCtrl.position.maxScrollExtent - _prevMaxExtent;
      if (delta > 0) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.pixels + delta);
      }
    }
    _prependAnchorMessageKey = null;
    _prependAnchorDy = null;
    _refreshAtMessage();
  }

  void _capturePrependAnchor() {
    _prependAnchorMessageKey = null;
    _prependAnchorDy = null;
    if (!_scrollCtrl.hasClients) return;
    final messages = _currentMessagesSnapshot();
    if (messages == null || messages.isEmpty) return;
    final visible = sliceMessages(messages: messages, window: _window);
    if (visible.isEmpty) return;
    for (final msg in visible) {
      final key = _messageKey(msg);
      if (key == null) continue;
      final ctx = _messageItemKeys[key]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      _prependAnchorMessageKey = key;
      _prependAnchorDy = dy;
      return;
    }
  }

  bool _restorePrependAnchor() {
    final key = _prependAnchorMessageKey;
    final oldDy = _prependAnchorDy;
    if (key == null || oldDy == null || !_scrollCtrl.hasClients) return false;
    final ctx = _messageItemKeys[key]?.currentContext;
    if (ctx == null) return false;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return false;
    final newDy = box.localToGlobal(Offset.zero).dy;
    final adjust = newDy - oldDy;
    if (adjust.abs() < 1) return true;
    final pos = _scrollCtrl.position;
    final next = (pos.pixels + adjust).clamp(0.0, pos.maxScrollExtent);
    _scrollCtrl.jumpTo(next);
    return true;
  }

  /// 下拉刷新 / 贴顶：加载更早历史。
  Future<void> _pullRefreshHistory() async {
    if (_lockScrollEvent || _pendingInitialScroll) return;
    if (_loadingHistory) return;

    final total = _currentMessagesSnapshot()?.length ?? 0;
    if (!_canLoadMoreHistory(total)) {
      return;
    }

    _beginHistoryLoading();
    try {
      if (_window.showMinIdx > 0) {
        setState(() {
          _window = _window.expandHistory(totalSize: total);
        });
        await _adjustScrollAfterPrepend();
        return;
      }
      await _loadOlderAtTop(prevTotal: total);
    } finally {
      _endHistoryLoading();
    }
  }

  void _scheduleTopLoad(int total) {
    if (_loadingHistory || _lockScrollEvent || _pendingInitialScroll) return;
    if (!_canLoadMoreHistory(total)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTopLoadAtMs < _topLoadCooldownMs) return;
    _topLoadDebounceTimer?.cancel();
    _topLoadDebounceTimer = Timer(_topLoadDebounceDuration, () {
      _topLoadDebounceTimer = null;
      if (!mounted || !_scrollCtrl.hasClients || _loadingHistory) return;
      if (_scrollCtrl.position.pixels > _scrollTopLoadTriggerPx) return;
      final latestTotal = _currentMessagesSnapshot()?.length ?? total;
      if (!_canLoadMoreHistory(latestTotal)) return;
      _lastTopLoadAtMs = DateTime.now().millisecondsSinceEpoch;
      _beginHistoryLoading();
      if (_window.showMinIdx > 0) {
        setState(() {
          _window = _window.expandHistory(totalSize: latestTotal);
        });
        unawaited(_adjustScrollAfterPrepend().whenComplete(_endHistoryLoading));
        return;
      }
      unawaited(
        _loadOlderAtTop(
          prevTotal: latestTotal,
        ).whenComplete(_endHistoryLoading),
      );
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    _checkScrollBottom();
    _refreshAtMessage();
    if (_loadingHistory || _lockScrollEvent || _pendingInitialScroll) return;
    if (_scrollCtrl.position.pixels > _scrollTopLoadTriggerPx) return;
    final total = _currentMessagesSnapshot()?.length ?? 0;
    _scheduleTopLoad(total);
  }

  /// 贴顶：优先按时间游标读本地更早一页，不足时再向服务端补拉并回填本地。
  Future<void> _loadOlderAtTop({required int prevTotal}) async {
    try {
      final messages = _currentMessagesSnapshot();
      final oldest = messages?.firstOrNull;
      if (oldest == null) return;
      final added = await _loadOlderCursorPage(anchor: oldest);
      if (!mounted) return;
      final newTotal = _currentMessagesSnapshot()?.length ?? prevTotal;
      if (added <= 0) {
        log.i(
          '[ChatBox] loadOlder ${widget.chatType}/${widget.targetId} '
          'no_more total=$newTotal reachedStart=$_historyReachedStart',
        );
        return;
      }
      setState(() {
        _window = _window.expandFromTop(totalSize: newTotal);
      });
      log.i(
        '[ChatBox] loadOlder ${widget.chatType}/${widget.targetId} '
        'added=$added total=$newTotal prefix=${_historyPrefixMessages.length} '
        'visible=${_window.windowSize(newTotal)}',
      );
      await _adjustScrollAfterPrepend();
    } catch (_) {
      rethrow;
    }
  }

  void _checkScrollBottom() {
    if (!_scrollCtrl.hasClients || _pendingInitialScroll) return;
    const threshold = 80.0;
    final pos = _scrollCtrl.position;
    final atBottom = pos.maxScrollExtent - pos.pixels <= threshold;
    if (atBottom != _isInBottom) {
      setState(() {
        _isInBottom = atBottom;
        if (atBottom) {
          _pendingNewMessageDelta = 0;
          _newMessageBadgeTimer?.cancel();
          _newMessageBadgeTimer = null;
          _newMessageSize = 0;
        }
        if (_autoScrollMode != _AutoScrollMode.locating) {
          _autoScrollMode = atBottom
              ? _AutoScrollMode.follow
              : _AutoScrollMode.reading;
        }
      });
    }
  }

  /// 对齐 uniapp `refreshAtMessage`：@ 消息进入当前可视区域时清除 @ 标记。
  void _refreshAtMessage() {
    if (!_isAlive) return;
    final chat = _findChat(ref.read(chatListStreamProvider).value);
    if (chat == null || (!chat.atMe && !chat.atAll)) return;
    final id = chat.lastAtMessageId;
    if (id <= 0) return;

    final messages = _currentMessagesSnapshot();
    if (messages == null || messages.isEmpty) return;
    final visible = sliceMessages(messages: messages, window: _window);
    if (!_isAtMessageInViewport(visible, id)) return;

    ref.read(chatStoreProvider).resetAt(widget.chatType, widget.targetId);
  }

  int? _listIndexForMessageId(List<Message> messages, int messageId) {
    final items = _withTimeDividers(messages);
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (!item.isDivider && item.message?.id == messageId) {
        return i;
      }
    }
    return null;
  }

  /// 估算列表项是否在滚动视口内（与 `_tryLocateMessage` 使用相同行高估算）。
  bool _isAtMessageInViewport(List<Message> messages, int messageId) {
    if (!_scrollCtrl.hasClients || !mounted) return false;
    final listIndex = _listIndexForMessageId(messages, messageId);
    if (listIndex == null) return false;

    final itemHeight = rpx(context, 120);
    final itemTop = listIndex * itemHeight;
    final itemBottom = itemTop + itemHeight;
    final pos = _scrollCtrl.position;
    final viewTop = pos.pixels;
    final viewBottom = viewTop + pos.viewportDimension;
    return itemBottom > viewTop && itemTop < viewBottom;
  }

  void _onClickToBottom() {
    _lockScrollTimer?.cancel();
    _lockScrollEvent = false;
    // 取消进行中的定位，避免随后 forLocate 把窗口从底部抢走。
    _pendingLocateId = null;
    _didLocate = true;
    _requestScrollToBottom(reason: 'manual_to_bottom', force: true);
  }

  void _requestInitialScrollToBottom(int messageCount) {
    if (messageCount <= 0) return;
    if (widget.locateMessageId != null) return;
    if (_didInitialBottom) return;
    _didInitialBottom = true;
    _requestScrollToBottom(reason: 'initial', shrinkLimit: false);
  }

  void _requestScrollToBottom({
    required String reason,
    bool shrinkLimit = true,
    bool force = false,
  }) {
    if (force) {
      _autoScrollMode = _AutoScrollMode.follow;
      _scrollToBottom(shrinkLimit: shrinkLimit);
      return;
    }
    if (_autoScrollMode == _AutoScrollMode.locating ||
        _autoScrollMode == _AutoScrollMode.reading) {
      return;
    }
    _scrollToBottom(shrinkLimit: shrinkLimit);
  }

  int? _messageKey(Message msg) => msg.id ?? msg.rowId;

  void _setLockScrollEvent([
    Duration duration = const Duration(milliseconds: 10),
  ]) {
    _lockScrollTimer?.cancel();
    _lockScrollEvent = true;
    _lockScrollTimer = Timer(duration, () {
      if (mounted) setState(() => _lockScrollEvent = false);
      _lockScrollTimer = null;
    });
  }

  int _fileDownloadKey(Message msg) => msg.id ?? msg.rowId;

  /// 文件消息实为图片（扩展名判断）。
  bool _isImageFileMessage(Message msg) {
    try {
      final decoded = jsonDecode(msg.content ?? '');
      if (decoded is! Map) return false;
      final map = Map<String, dynamic>.from(decoded);
      final name = map['name']?.toString() ?? '';
      final url = map['url']?.toString() ?? '';
      if (url.isEmpty) return false;
      return ChatMediaUtil.isImageFileName(name) ||
          ChatMediaUtil.isImageFileName(url);
    } catch (_) {
      return false;
    }
  }

  bool get _isAlive => mounted;

  String _messageIdentity(Message msg) =>
      msg.id != null ? 'id:${msg.id}' : 'row:${msg.rowId}';

  List<Message> _composeMessages(List<Message>? recentMessages) {
    final recent = recentMessages ?? const <Message>[];
    if (_historyPrefixMessages.isEmpty) return recent;
    final out = <Message>[];
    final seen = <String>{};
    for (final msg in [..._historyPrefixMessages, ...recent]) {
      final key = _messageIdentity(msg);
      if (seen.add(key)) out.add(msg);
    }
    return out;
  }

  List<Message>? _currentMessagesSnapshot({List<Message>? recent}) {
    final live = recent ?? ref.read(chatMessagesProvider(_msgQuery)).value;
    final base =
        live ??
        (_lastRecentMessages.isNotEmpty
            ? _lastRecentMessages
            : (_seedMessages ?? const <Message>[]));
    return _composeMessages(base);
  }

  void _captureRecentOverflow(List<Message> recentMessages) {
    if (_historyPrefixMessages.isEmpty || _lastRecentMessages.isEmpty) return;
    final nextKeys = recentMessages.map(_messageIdentity).toSet();
    final overflow = <Message>[];
    for (final msg in _lastRecentMessages) {
      if (nextKeys.contains(_messageIdentity(msg))) break;
      overflow.add(msg);
    }
    if (overflow.isEmpty) return;
    final prefixKeys = _historyPrefixMessages.map(_messageIdentity).toSet();
    final uniqueOverflow = overflow
        .where((msg) => prefixKeys.add(_messageIdentity(msg)))
        .toList();
    if (uniqueOverflow.isEmpty) return;
    setState(() {
      _historyPrefixMessages = [..._historyPrefixMessages, ...uniqueOverflow];
    });
  }

  int _prependHistoryMessages(List<Message> olderMessages) {
    if (olderMessages.isEmpty) return 0;
    final existing = (_currentMessagesSnapshot() ?? const <Message>[])
        .map(_messageIdentity)
        .toSet();
    final unique = olderMessages
        .where((msg) => existing.add(_messageIdentity(msg)))
        .toList();
    if (unique.isEmpty) return 0;
    setState(() {
      _historyPrefixMessages = [...unique, ..._historyPrefixMessages];
    });
    return unique.length;
  }

  Future<List<Message>> _readOlderLocalMessages({
    required int beforeSendTime,
    required int limit,
  }) {
    return ref
        .read(chatStoreProvider)
        .readMessages(
          widget.chatType,
          widget.targetId,
          limit: limit,
          beforeSendTime: beforeSendTime,
        );
  }

  Future<int> _loadOlderCursorPage({
    required Message anchor,
    int targetCount = ChatMessageWindowConfig.preloadStep,
  }) async {
    final beforeSendTime = anchor.sendTime;
    if (beforeSendTime == null || beforeSendTime <= 0) {
      if (mounted) {
        setState(() => _historyReachedStart = true);
      }
      return 0;
    }

    var added = 0;
    final local = await _readOlderLocalMessages(
      beforeSendTime: beforeSendTime,
      limit: targetCount,
    );
    added += _prependHistoryMessages(local);
    if (local.length >= targetCount) return added;

    final oldestId = anchor.id;
    if (_historyReachedStart || oldestId == null || oldestId <= 0) {
      if (local.isEmpty && mounted) {
        setState(() => _historyReachedStart = true);
      }
      return added;
    }

    final serverLoaded = await ref
        .read(offlineSyncProvider)
        .pullOlderChatHistory(
          chatType: widget.chatType,
          targetId: widget.targetId,
          maxId: oldestId,
          limit: targetCount,
        );
    if (serverLoaded <= 0) {
      if (mounted) {
        setState(() => _historyReachedStart = true);
      }
      return added;
    }

    final refreshed = await _readOlderLocalMessages(
      beforeSendTime: beforeSendTime,
      limit: targetCount + local.length + serverLoaded,
    );
    added += _prependHistoryMessages(refreshed);
    return added;
  }

  GlobalKey _keyForMessage(Message msg) {
    final key = _messageKey(msg);
    if (key == null) return GlobalKey();
    return _messageItemKeys.putIfAbsent(key, GlobalKey.new);
  }

  Future<void> _scrollToAtMessage(Chat? chat) async {
    if (chat == null) return;
    final id = chat.lastAtMessageId;
    if (id <= 0) {
      await ref
          .read(chatStoreProvider)
          .resetAt(widget.chatType, widget.targetId);
      return;
    }
    await _locateMessageById(id);
    await ref.read(chatStoreProvider).resetAt(widget.chatType, widget.targetId);
  }

  /// 为定位扩读本地消息，上限 [locateMaxLimit]，避免一次拉入数千条。
  Future<List<Message>> _expandLimitUntilMessage(int id) async {
    var messages = _currentMessagesSnapshot() ?? const <Message>[];
    var index = messages.indexWhere((m) => m.id == id);
    final maxLimit = locateHistoryMaxLimit();
    while (index < 0 && mounted && messages.length < maxLimit) {
      final oldest = messages.firstOrNull;
      if (oldest == null) break;
      final step = (maxLimit - messages.length).clamp(
        1,
        locateHistoryFetchStep(),
      );
      final added = await _loadOlderCursorPage(
        anchor: oldest,
        targetCount: step,
      );
      messages = _currentMessagesSnapshot() ?? const <Message>[];
      index = messages.indexWhere((m) => m.id == id);
      if (added <= 0) break;
    }
    return messages;
  }

  void _jumpToBottomIfPossible() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.maxScrollExtent > 0) {
      _scrollCtrl.jumpTo(pos.maxScrollExtent);
    }
  }

  /// 对齐 uniapp `scrollToBottom`：先 `resetShowMessages`，再多帧滚到底部。
  ///
  /// [shrinkLimit]：回底时把 `_messageLimit` 收回 `pageSize`，避免定位扩读后长期占用大缓冲。
  void _scrollToBottom({bool shrinkLimit = true}) {
    // 定位扩读/滚到目标完成前，禁止贴底把窗口打回 bottomPage。
    if (_pendingLocateId != null && !_didLocate) return;

    final gen = ++_scrollToBottomGen;
    _lockScrollTimer?.cancel();
    _lockScrollEvent = true;

    // 先复位窗口（对齐 uniapp resetShowMessages），再滚；finish 里不再 setState 改窗口，
    // 避免 rebuild 把 scroll offset 打回顶部。
    if (mounted) {
      setState(() {
        if (shrinkLimit &&
            _pendingLocateId == null &&
            _messageLimit > ChatMessageWindowConfig.pageSize) {
          _messageLimit = ChatMessageWindowConfig.pageSize;
        }
        if (shrinkLimit && _historyPrefixMessages.isNotEmpty) {
          _historyPrefixMessages = const [];
          _historyReachedStart = false;
        }
        final messages = _currentMessagesSnapshot();
        final count = messages?.length ?? 0;
        // limit 已收回 pageSize 时，按一页计算窗口，避免读到旧 provider 的大 count。
        if (_messageLimit <= ChatMessageWindowConfig.pageSize) {
          final total = count > 0
              ? count.clamp(1, ChatMessageWindowConfig.pageSize)
              : ChatMessageWindowConfig.pageSize;
          _window = ChatMessageWindowState.bottomPage(total);
        } else if (count > 0) {
          _window = ChatMessageWindowState.bottomPage(count);
        } else {
          _window = ChatMessageWindowState.bottomPage(
            ChatMessageWindowConfig.pageSize,
          );
        }
        _isInBottom = true;
        _newMessageSize = 0;
      });
    }

    void finishScroll() {
      if (!mounted || gen != _scrollToBottomGen) return;
      if (_pendingInitialScroll) {
        setState(() {
          _pendingInitialScroll = false;
          _autoScrollMode = _AutoScrollMode.follow;
        });
      } else {
        _pendingInitialScroll = false;
        if (_autoScrollMode != _AutoScrollMode.locating) {
          _autoScrollMode = _AutoScrollMode.follow;
        }
      }
      _setLockScrollEvent(const Duration(milliseconds: 100));
      _refreshAtMessage();
      // 仅在 follow 模式做底部补偿，避免 reading/locating 模式抢滚动。
      final baseline = _scrollCtrl.hasClients
          ? _scrollCtrl.position.maxScrollExtent
          : 0.0;
      _scheduleBottomCompensation(gen: gen, baseline: baseline);
    }

    void attemptScroll(int attempt) {
      if (!mounted || gen != _scrollToBottomGen) return;
      if (!_scrollCtrl.hasClients) {
        if (attempt < 15) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => attemptScroll(attempt + 1),
          );
        } else {
          finishScroll();
        }
        return;
      }
      final pos = _scrollCtrl.position;
      // viewport 尚未布局完成时再等，避免短列表 maxScrollExtent==0 被误判为未就绪。
      if (pos.viewportDimension <= 0) {
        if (attempt < 15) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => attemptScroll(attempt + 1),
          );
        } else {
          finishScroll();
        }
        return;
      }
      if (pos.maxScrollExtent > 0) {
        _scrollCtrl.jumpTo(pos.maxScrollExtent);
      }
      if (!_scrollCtrl.hasClients) {
        finishScroll();
        return;
      }
      final after = _scrollCtrl.position;
      // 内容不足一屏（maxScrollExtent==0）视为已在底部，无需重试。
      final needRetry =
          after.maxScrollExtent > 0 &&
          after.maxScrollExtent - after.pixels > 80;
      if (needRetry && attempt < 15) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => attemptScroll(attempt + 1),
        );
        if (attempt == 2 || attempt == 5 || attempt == 8) {
          Future<void>.delayed(
            Duration(milliseconds: attempt == 2 ? 50 : 120),
            () {
              if (mounted && gen == _scrollToBottomGen) {
                attemptScroll(attempt + 1);
              }
            },
          );
        }
        return;
      }
      finishScroll();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attemptScroll(0));
  }

  void _scheduleBottomCompensation({
    required int gen,
    required double baseline,
  }) {
    var lastExtent = baseline;
    for (final delayMs in const [100, 300]) {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted || gen != _scrollToBottomGen) return;
        if (_autoScrollMode != _AutoScrollMode.follow || !_isInBottom) return;
        if (!_scrollCtrl.hasClients) return;
        final current = _scrollCtrl.position.maxScrollExtent;
        if (current - lastExtent > 1) {
          _jumpToBottomIfPossible();
          lastExtent = current;
        }
      });
    }
  }

  void _onLongPressHead(Message msg, bool selfSend) {
    final sendId = msg.sendId;
    if (sendId == null || selfSend || widget.chatType != ChatType.group) return;
    if (_atUserIds.contains(sendId)) return;
    setState(() => _atUserIds = [..._atUserIds, sendId]);
  }

  void _onTapHead(Message msg, bool selfSend) {
    final sendId = msg.sendId;
    if (sendId == null || selfSend) return;
    context.push(AppRoutes.friendUserPath(sendId));
  }

  String _navTitle(Chat? chat, bool isGroup) {
    if (chat == null) return '聊天';
    if (!isGroup) return chat.showName ?? '聊天';
    final members = ref
        .read(groupStoreProvider.notifier)
        .membersOf(widget.targetId);
    return groupChatNavTitle(chat.showName, members);
  }

  bool _isGroupOwner(Group? group) {
    if (group == null) return false;
    final selfId = ref.read(userStoreProvider)?.id;
    return selfId != null && group.ownerId == selfId;
  }

  bool _guardTeenager(TeenagerBlockFeature feature) {
    final enabled = TeenagerModeUtil.isEnabled(
      userId: ref.read(userStoreProvider)?.id,
      kv: ref.read(kvStoreProvider),
    );
    return guardTeenagerFeature(
      teenagerModeEnabled: enabled,
      feature: feature,
      onBlocked: (msg) => _toast(msg),
    );
  }

  /// 对齐 uniapp `notAllowInputTip`。
  String? _notAllowInputTip(Group? group, bool isGroup, bool isPrivate) {
    if (isGroup && group != null) {
      if (group.dissolve) return '群聊已解散';
      if (group.quit) return '您已不在群聊中';
      if (group.isBanned) {
        return '群聊已被封禁,原因:${group.reason ?? ''}';
      }
      if (group.isAllMuted && !_isGroupOwner(group) && !_isGroupManager()) {
        return '全员禁言中,只有群主和管理员发言';
      }
      if (group.isMuted) return '您已被群管理员禁言';
    } else if (isPrivate && _targetUser?.isBanned == true) {
      return '对方账号已被封禁,原因:${_targetUser?.reason ?? ''}';
    }
    return null;
  }

  void _onInputFocusChange() {
    if (!_inputFocus.hasFocus || !mounted) return;
    setState(() {
      _toolsOpen = _ChatPanelTab.none;
      _showRecord = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestScrollToBottom(reason: 'input_focus', force: true);
      }
    });
  }

  void _dismissPanels() {
    if (_toolsOpen == _ChatPanelTab.none && !_showRecord) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _toolsOpen = _ChatPanelTab.none;
      _showRecord = false;
    });
  }

  /// 长按消息菜单前收起键盘与底部面板。对齐 uniapp 弹出菜单时不抢编辑器焦点。
  void _dismissInputForMenu() {
    FocusScope.of(context).unfocus();
    if (_toolsOpen != _ChatPanelTab.none || _showRecord) {
      setState(() {
        _toolsOpen = _ChatPanelTab.none;
        _showRecord = false;
      });
    }
  }

  /// 菜单操作后保持输入区不弹键盘（引用除外）。
  void _keepInputDismissed() {
    FocusManager.instance.primaryFocus?.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).unfocus();
    });
  }

  /// 引用消息后聚焦输入框。对齐 uniapp onQuoteMessage → onKeyboardInput。
  void _focusInputForQuote() {
    setState(() {
      _showRecord = false;
      _toolsOpen = _ChatPanelTab.none;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
  }

  void _focusInputForEditResend(String text) {
    setState(() {
      _showRecord = false;
      _toolsOpen = _ChatPanelTab.none;
    });
    _inputCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
  }

  String _wireTextToInputText(String text) {
    return text.replaceAllMapped(EmotionUtil.pattern, (match) {
      final word = match.group(1) ?? match.group(2);
      if (word == null || EmotionUtil.indexOfWord(word) == null) {
        return match.group(0)!;
      }
      return EmotionUtil.inputTokenForWord(word);
    });
  }

  int _visibleToolCount({
    required bool isGroup,
    required bool isPrivate,
    required bool enableRtcCall,
  }) {
    var count = 5;
    if (isGroup) count += 1;
    if (enableRtcCall && isPrivate) count += 2;
    if (enableRtcCall && isGroup) count += 1;
    return count;
  }

  double _chatToolsHeight(BuildContext context, int toolCount) {
    final rows = (toolCount / 4).ceil().clamp(1, 99);
    final h = rpx(context, rows * 178 + 40);
    return h > kChatPanelHeight ? kChatPanelHeight : h;
  }

  ChatMsgQuery get _msgQuery => ChatMsgQuery(
    type: widget.chatType,
    targetId: widget.targetId,
    limit: _messageLimit,
  );

  Widget _messageListView({
    required BuildContext context,
    required List<Message> messages,
    required int selfId,
    required bool isGroup,
    required Chat? chat,
    required Group? group,
  }) {
    if (messages.isEmpty) {
      if (!_seedBootstrapped) {
        return Center(
          child: Text(
            '消息加载中…',
            style: TextStyle(
              fontSize: rpx(context, 28),
              color: ImColors.textLighter,
            ),
          ),
        );
      }
      return Center(
        child: Text(
          '暂无消息',
          style: TextStyle(
            fontSize: rpx(context, 28),
            color: ImColors.textLighter,
          ),
        ),
      );
    }
    final visible = sliceMessages(messages: messages, window: _window);
    _precacheVisibleImageMessages(context, visible);
    final items = _withTimeDividers(visible);
    final showHistoryHeader = _loadingHistory || _historyReachedStart;
    final headerCount = showHistoryHeader ? 1 : 0;
    return RefreshIndicator(
      color: ImColors.accent,
      displacement: rpx(context, 36),
      onRefresh: _pullRefreshHistory,
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        padding: EdgeInsets.only(
          top: rpx(context, 8),
          bottom: rpx(context, 16),
        ),
        itemCount: items.length + headerCount,
        itemBuilder: (context, index) {
          if (showHistoryHeader && index == 0) {
            return _HistoryLoadingHeader(
              loading: _loadingHistory,
              reachedStart: _historyReachedStart,
            );
          }
          final item = items[index - headerCount];
          if (item.isDivider) {
            return _TimeTipRow(time: item.time!);
          }
          final msg = item.message!;
          final selfSend = msg.selfSend || msg.sendId == selfId;
          final senderName = isGroup && !selfSend
              ? _showNameForMessage(msg, chatShowName: chat?.showName)
              : null;
          final senderRoles = isGroup && !selfSend
              ? groupSenderRoles(
                  ownerId: group?.ownerId,
                  sendId: msg.sendId ?? 0,
                  members: ref
                      .read(groupStoreProvider.notifier)
                      .membersOf(widget.targetId),
                )
              : const <GroupSenderRole>{};
          final onResend = msg.status == MessageStatus.failed
              ? () => _resend(msg)
              : null;
          final bubble = _buildBubble(
            msg: msg,
            selfSend: selfSend,
            senderName: senderName,
            senderRoles: senderRoles,
            chatShowName: chat?.showName,
            onResend: onResend,
            onLongPress: (pos) => _onMessageLongPress(msg, pos),
            onQuoteTap: () => _locateQuotedMessage(msg),
            onQuoteLongPress: (pos) => _onQuoteLongPress(msg, pos),
          );
          if (MessageType.isTip(msg.type) ||
              msg.status == MessageStatus.recall) {
            return ChatMessageTipRow(child: bubble);
          }
          final avatar = _avatarForMessage(msg, selfSend, chat);
          return KeyedSubtree(
            key: _keyForMessage(msg),
            child: Column(
              crossAxisAlignment: selfSend
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                ChatMessageRow(
                  selfSend: selfSend,
                  headUrl: avatar.url,
                  headName: avatar.name,
                  // 仅在主动定位时高亮；勿用 `== msg.id`（双方均为 null 时
                  // 发送中/失败等本地消息会被误判为高亮，出现整行淡紫底）。
                  highlighted:
                      _activeMessageId != null && _activeMessageId == msg.id,
                  onHeadTap: () => _onTapHead(msg, selfSend),
                  onHeadLongPress: () => _onLongPressHead(msg, selfSend),
                  child: bubble,
                ),
                if (isGroup && selfSend && msg.receipt)
                  Padding(
                    padding: EdgeInsets.only(
                      right: rpx(context, 105) + rpx(context, 20),
                    ),
                    child: ChatReceiptBadge(
                      message: msg,
                      onTap: () => _onShowReceipt(msg),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _send() async {
    if (_notAllowInputTip(
          ref.read(groupStoreProvider.notifier).byId(widget.targetId),
          widget.chatType == ChatType.group,
          widget.chatType == ChatType.private,
        ) !=
        null) {
      return;
    }
    final text = EmotionUtil.encodeForWire(_inputCtrl.text.trim());
    if (text.isEmpty && _atUserIds.isEmpty) {
      _toast('不能发送空白信息');
      return;
    }
    final atUserIds = List<int>.from(_atUserIds);
    final quote = _quoteMessage;
    final quotePayload = quote != null
        ? QuoteMessageUtil.fromMessage(quote)
        : null;
    final receipt = _isReceipt;
    _inputCtrl.clear();
    setState(() {
      _atUserIds = const [];
      _quoteMessage = null;
      _isReceipt = false;
    });
    final store = ref.read(chatStoreProvider);
    String? err;
    if (widget.chatType == ChatType.private) {
      err = await store.sendPrivateText(
        friendId: widget.targetId,
        content: text,
        quoteMessageId: quote?.id,
        quoteMessage: quotePayload,
      );
    } else if (widget.chatType == ChatType.group) {
      err = await store.sendGroupText(
        groupId: widget.targetId,
        content: text,
        atUserIds: atUserIds,
        quoteMessageId: quote?.id,
        quoteMessage: quotePayload,
        receipt: receipt,
      );
    }
    if (err != null && mounted) {
      _toast(err);
    }
    _requestScrollToBottom(reason: 'send_text', force: true);
  }

  Future<void> _openAtBox() async {
    final groupStore = ref.read(groupStoreProvider.notifier);
    var group = groupStore.byId(widget.targetId);
    if (group == null) {
      try {
        group = await groupStore.loadGroupDetail(widget.targetId);
      } catch (_) {
        return;
      }
    }
    await groupStore.loadMembers(widget.targetId);
    if (!mounted) return;

    final members = groupStore.membersOf(widget.targetId);
    final selfId = ref.read(userStoreProvider)?.id;
    final prevIds = Set<int>.from(_atUserIds);
    final selected = await GroupMemberSelector.show(
      context,
      members: members,
      group: group,
      mineId: selfId,
      checkedIds: _atUserIds,
      hideIds: selfId != null ? [selfId] : const [],
      maxSize: 20,
      includeAtAll: selfId != null && group.ownerId == selfId,
    );
    if (selected == null || !mounted) return;

    final memberMap = {for (final m in members) m.userId: m};
    final buffer = StringBuffer();
    for (final id in selected) {
      if (prevIds.contains(id)) continue;
      if (id == -1) {
        buffer.write('@全体成员 ');
        continue;
      }
      final name = memberMap[id]?.showNickName;
      if (name != null && name.isNotEmpty) {
        buffer.write('@$name ');
      }
    }
    if (buffer.isNotEmpty) {
      final next = '${_inputCtrl.text}${buffer.toString()}';
      _inputCtrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
    setState(() => _atUserIds = selected);
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (source == ImageSource.gallery) {
      if (!mounted) return;
      final picks = await ChatImagePickerUtil.pickAlbumImages(
        context,
        maxCount: ChatMediaUtil.maxAlbumImageCount,
        onToast: (msg) {
          if (mounted) _toast(msg);
        },
      );
      if (picks.isEmpty || !mounted) return;
      for (final pick in picks) {
        unawaited(
          _sendImageFromPath(pick.path, width: pick.width, height: pick.height),
        );
      }
      return;
    }

    if (!mounted) return;
    if (!await MediaPermissionUtil.ensureScenario(
      context,
      MediaPermissionScenario.chatCameraPhoto,
    )) {
      return;
    }

    // 对齐 uniapp sizeType: ['original']，不设 maxWidth/maxHeight。
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 100,
    );
    if (picked == null || !mounted) return;
    await _sendImageFromPath(picked.path);
  }

  Future<void> _sendImageFromPath(
    String path, {
    int? width,
    int? height,
  }) async {
    final file = File(path);
    final bytes = await file.length();
    if (bytes > ChatMediaUtil.maxImageBytes) {
      if (mounted) {
        _toast('图片大小不得大于10M');
      }
      return;
    }

    await _sendMedia(({bool receipt = false}) async {
      final store = ref.read(chatStoreProvider);
      if (widget.chatType == ChatType.private) {
        return store.sendPrivateImage(
          friendId: widget.targetId,
          localPath: path,
          width: width,
          height: height,
        );
      }
      if (widget.chatType == ChatType.group) {
        return store.sendGroupImage(
          groupId: widget.targetId,
          localPath: path,
          width: width,
          height: height,
          receipt: receipt,
        );
      }
      return null;
    });
  }

  Future<void> _pickAndSendVideo() async {
    final source = await showImBottomActionSheet<ImageSource>(
      context,
      items: const [
        ImBottomActionItem(label: '从本机选取', value: ImageSource.gallery),
        ImBottomActionItem(label: '使用相机拍摄', value: ImageSource.camera),
      ],
    );
    if (source == null || !mounted) return;

    if (source == ImageSource.camera) {
      if (!mounted) return;
      if (!await MediaPermissionUtil.ensureScenario(
        context,
        MediaPermissionScenario.chatCameraVideo,
      )) {
        return;
      }
    } else {
      if (!mounted) return;
      if (!await MediaPermissionUtil.ensureScenario(
        context,
        MediaPermissionScenario.chatAlbumVideo,
      )) {
        return;
      }
    }

    if (!mounted) return;
    // 对齐 uniapp chooseVideo compressed:false，不设压缩参数。
    final picked = await ImagePicker().pickVideo(source: source);
    if (picked == null || !mounted) return;
    await _sendVideoFromPath(picked.path);
  }

  Future<void> _sendVideoFromPath(String path) async {
    final file = File(path);
    final bytes = await file.length();
    if (bytes > ChatMediaUtil.maxVideoBytes) {
      if (mounted) {
        _toast('视频文件不得大于50M');
      }
      return;
    }

    await _sendMedia(({bool receipt = false}) async {
      final store = ref.read(chatStoreProvider);
      if (widget.chatType == ChatType.private) {
        return store.sendPrivateVideo(
          friendId: widget.targetId,
          localPath: path,
        );
      }
      if (widget.chatType == ChatType.group) {
        return store.sendGroupVideo(
          groupId: widget.targetId,
          localPath: path,
          receipt: receipt,
        );
      }
      return null;
    });
  }

  Future<void> _pickAndSendFile() async {
    if (!mounted) return;
    if (!await MediaPermissionUtil.ensure(
      context,
      MediaPermissionKind.storage,
    )) {
      return;
    }
    if (!mounted) return;
    final files = await ChatFilePickerUtil.pickChatFiles(
      onToast: (msg) {
        if (mounted) _toast(msg);
      },
    );
    if (files.isEmpty || !mounted) return;

    for (final file in files) {
      unawaited(
        _sendFileFromPath(path: file.path, name: file.name, size: file.size),
      );
    }
  }

  Future<void> _sendFileFromPath({
    required String path,
    required String name,
    required int size,
  }) async {
    // 文件通道选到图片时按图片发送，避免对方看到「文件卡片」
    if (ChatMediaUtil.isImageFileName(name) ||
        ChatMediaUtil.isImageFileName(path)) {
      await _sendImageFromPath(path);
      return;
    }
    await _sendMedia(({bool receipt = false}) async {
      final store = ref.read(chatStoreProvider);
      if (widget.chatType == ChatType.private) {
        return store.sendPrivateFile(
          friendId: widget.targetId,
          localPath: path,
          name: name,
          size: size,
        );
      }
      if (widget.chatType == ChatType.group) {
        return store.sendGroupFile(
          groupId: widget.targetId,
          localPath: path,
          name: name,
          size: size,
          receipt: receipt,
        );
      }
      return null;
    });
  }

  Future<void> _sendMedia(Future<String?> Function({bool receipt}) send) async {
    final receipt = widget.chatType == ChatType.group && _isReceipt;
    if (receipt) setState(() => _isReceipt = false);
    // 对齐 uniapp：选完相册/文件/视频后工具面板保持展开。
    final err = await send(receipt: receipt);
    if (err != null && mounted) {
      _toast(err);
    }
    _requestScrollToBottom(reason: 'send_media', force: true);
  }

  void _resend(Message msg) {
    if (msg.type != MessageType.text) {
      _toast('该消息不支持自动重新发送，建议手动重新发送');
      return;
    }
    final store = ref.read(chatStoreProvider);
    if (widget.chatType == ChatType.private) {
      store.resendPrivate(msg);
    } else {
      store.resendGroup(msg);
    }
  }

  void _onShowMore() {
    if (widget.chatType == ChatType.group) {
      context.push(AppRoutes.groupInfoPath(widget.targetId));
    } else {
      context.push(AppRoutes.friendUserPath(widget.targetId));
    }
  }

  String _showNameForSendId(
    int? sendId, {
    required bool selfSend,
    String? chatShowName,
    String? sendNickName,
  }) {
    final mine = ref.read(userStoreProvider);
    if (widget.chatType == ChatType.group) {
      if (sendNickName != null && sendNickName.isNotEmpty) {
        return sendNickName;
      }
      final members = ref
          .read(groupStoreProvider.notifier)
          .membersOf(widget.targetId);
      for (final m in members) {
        if (m.userId == sendId) return m.showNickName ?? '';
      }
      return '';
    }
    if (selfSend) return mine?.nickName ?? '';
    return chatShowName ?? '';
  }

  String _showNameForMessage(Message msg, {String? chatShowName}) {
    return _showNameForSendId(
      msg.sendId,
      selfSend: msg.selfSend || msg.sendId == ref.read(userStoreProvider)?.id,
      chatShowName: chatShowName,
      sendNickName: msg.sendNickName,
    );
  }

  ({String? url, String? name}) _avatarForMessage(
    Message msg,
    bool selfSend,
    Chat? chat,
  ) {
    if (selfSend) {
      final u = ref.read(userStoreProvider);
      return (url: u?.headImageThumb ?? u?.headImage, name: u?.nickName);
    }
    if (widget.chatType == ChatType.group) {
      final members = ref
          .read(groupStoreProvider.notifier)
          .membersOf(widget.targetId);
      for (final m in members) {
        if (m.userId == msg.sendId) {
          return (url: m.headImage, name: m.showNickName);
        }
      }
      return (url: null, name: msg.sendNickName);
    }
    return (url: chat?.headImage, name: chat?.showName);
  }

  String _quotePreviewText(Message msg, {String? chatShowName}) {
    return QuoteMessageUtil.previewOfMessage(
      msg,
      _showNameForMessage(msg, chatShowName: chatShowName),
    );
  }

  Future<void> _onMessageLongPress(Message msg, Offset anchor) async {
    final items = ChatMessageMenuBuilder.forMessage(
      msg: msg,
      canRecall: _canRecallMessage(msg),
      canTop: _canTopMessage(msg),
    );
    if (items.isEmpty) return;

    _dismissInputForMenu();

    final key = await ChatMessageMenu.show(
      context,
      items: items,
      anchor: anchor,
    );
    if (!mounted || key == null) return;
    await _handleMessageMenuKey(key, msg);
  }

  Future<void> _onQuoteLongPress(Message msg, Offset anchor) async {
    final items = ChatMessageMenuBuilder.forQuote(msg);
    if (items.isEmpty) return;

    _dismissInputForMenu();

    final key = await ChatMessageMenu.show(
      context,
      items: items,
      anchor: anchor,
    );
    if (!mounted || key == null) return;
    if (key == 'LOCATE_QUOTE') {
      _locateQuotedMessage(msg);
      _keepInputDismissed();
    }
  }

  Future<void> _handleMessageMenuKey(String key, Message msg) async {
    switch (key) {
      case 'COPY':
        await Clipboard.setData(ClipboardData(text: msg.content ?? ''));
        if (mounted) {
          _toast('复制成功');
        }
        _keepInputDismissed();
        return;
      case 'QUOTE':
        setState(() => _quoteMessage = msg);
        _focusInputForQuote();
        return;
      case 'RESEND':
        _keepInputDismissed();
        _resend(msg);
        return;
      case 'EDIT_RESEND':
        _focusInputForEditResend(_wireTextToInputText(msg.content ?? ''));
        if (mounted) {
          _toast('已填入输入框，可编辑后发送');
        }
        return;
      case 'RECALL':
        _keepInputDismissed();
        final recallOk = await showImConfirmDialog(
          context,
          title: '撤回消息',
          content: '确认撤回消息?',
        );
        _keepInputDismissed();
        if (recallOk == true && mounted) {
          final err = await ref.read(chatStoreProvider).requestRecall(msg);
          if (err != null && mounted) {
            _toast(err);
          }
        }
        return;
      case 'TOP':
        _keepInputDismissed();
        final err = await ref
            .read(chatStoreProvider)
            .setGroupTopMessage(widget.targetId, msg.id!);
        if (mounted) {
          _toast(err ?? '置顶成功');
        }
        return;
      case 'LOCATE_QUOTE':
        _locateQuotedMessage(msg);
        _keepInputDismissed();
        return;
      case 'DOWNLOAD':
        _keepInputDismissed();
        await _downloadFile(msg);
        _keepInputDismissed();
        return;
      case 'FORWARD':
        _keepInputDismissed();
        final chats = await ChatPickerSheet.show(context, title: '选择转发联系人');
        _keepInputDismissed();
        if (chats != null && chats.isNotEmpty && mounted) {
          final forwardErr = await ref
              .read(chatStoreProvider)
              .forwardMessage(msg, chats);
          if (mounted) {
            _toast(forwardErr ?? '转发成功');
          }
        }
        return;
      case 'DELETE':
        _keepInputDismissed();
        final deleteOk = await showImConfirmDialog(
          context,
          title: '删除消息',
          content: '确认删除消息?',
        );
        _keepInputDismissed();
        if (deleteOk == true && mounted) {
          await ref.read(chatStoreProvider).deleteMessage(msg);
          if (mounted) {
            _toast('删除成功');
          }
        }
        return;
    }
  }

  bool _canTopMessage(Message msg) {
    if (msg.id == null) return false;
    if (widget.chatType != ChatType.group) return false;
    if (!QuoteMessageUtil.isNormalType(msg.type)) return false;
    return _isGroupManager();
  }

  bool _isGroupManager() {
    final selfId = ref.read(userStoreProvider)?.id;
    if (selfId == null) return false;
    final group = ref.read(groupStoreProvider.notifier).byId(widget.targetId);
    if (group?.ownerId == selfId) return true;
    for (final m
        in ref.read(groupStoreProvider.notifier).membersOf(widget.targetId)) {
      if (m.userId == selfId && m.isManager) return true;
    }
    return false;
  }

  Future<void> _downloadFile(Message msg) async {
    final key = _fileDownloadKey(msg);
    if (_fileDownloadProgress.containsKey(key)) return;

    try {
      final map = jsonDecode(msg.content ?? '{}') as Map<String, dynamic>;
      final fileUrl = map['url']?.toString();
      final fileId = map['fileId']?.toString();
      final name = map['name']?.toString();
      final apiBase = ref.read(lineProvider).baseUrl;
      final token = ref.read(kvStoreProvider).accessToken;

      setState(() => _fileDownloadProgress[key] = 0);
      final err = await FileDownloadUtil.downloadAndOpen(
        apiBaseUrl: apiBase,
        fileId: fileId,
        fileUrl: fileUrl,
        fileName: name,
        accessToken: token,
        onProgress: (p) {
          if (mounted) setState(() => _fileDownloadProgress[key] = p);
        },
      );
      if (mounted) {
        _toast(err ?? '打开成功');
      }
    } catch (_) {
      if (mounted) {
        _toast('文件下载失败');
      }
    } finally {
      if (mounted) {
        setState(() => _fileDownloadProgress.remove(key));
      }
    }
  }

  Future<void> _onShowReceipt(Message msg) async {
    final members = ref
        .read(groupStoreProvider.notifier)
        .membersOf(widget.targetId);
    await ChatGroupReceiptSheet.show(
      context,
      ref,
      message: msg,
      members: members,
    );
  }

  bool _canRecallMessage(Message msg) {
    if (msg.id == null) return false;
    if (msg.selfSend) return true;
    if (widget.chatType != ChatType.group) return false;
    final selfId = ref.read(userStoreProvider)?.id;
    if (selfId == null) return false;
    final group = ref.read(groupStoreProvider.notifier).byId(widget.targetId);
    if (group?.ownerId == selfId) return true;
    for (final m
        in ref.read(groupStoreProvider.notifier).membersOf(widget.targetId)) {
      if (m.userId == selfId && m.isManager) return true;
    }
    return false;
  }

  Future<void> _toggleRecordMode() async {
    if (!_showRecord) {
      if (!mounted) return;
      if (!await MediaPermissionUtil.ensureScenario(
        context,
        MediaPermissionScenario.chatVoiceMessage,
      )) {
        return;
      }
    }
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _showRecord = !_showRecord;
      if (_showRecord) _toolsOpen = _ChatPanelTab.none;
    });
  }

  Future<void> _onSendRecord(Map<String, dynamic> data) async {
    final path = data['url']?.toString();
    final duration = (data['duration'] as num?)?.toInt() ?? 0;
    if (path == null || path.isEmpty) return;

    await _sendMedia(({bool receipt = false}) async {
      final store = ref.read(chatStoreProvider);
      if (widget.chatType == ChatType.private) {
        return store.sendPrivateAudio(
          friendId: widget.targetId,
          localPath: path,
          duration: duration,
        );
      }
      if (widget.chatType == ChatType.group) {
        return store.sendGroupAudio(
          groupId: widget.targetId,
          localPath: path,
          duration: duration,
          receipt: receipt,
        );
      }
      return null;
    });
  }

  void _flashMessageHighlight(int id) {
    _highlightTimer?.cancel();
    _lockScrollTimer?.cancel();
    setState(() {
      _activeMessageId = id;
      _lockScrollEvent = true;
    });
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _activeMessageId = null;
          _lockScrollEvent = false;
        });
      }
    });
  }

  void _tryLocateMessage(List<Message> messages) {
    final id = _pendingLocateId;
    if (id == null || _didLocate) return;
    final visible = sliceMessages(messages: messages, window: _window);
    final visibleIndex = visible.indexWhere((m) => m.id == id);
    if (visibleIndex < 0) return;
    _didLocate = true;
    _pendingLocateId = null;
    _flashMessageHighlight(id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final targetMsg = visible[visibleIndex];
      final targetKey = _messageKey(targetMsg);
      final targetCtx = targetKey == null
          ? null
          : _messageItemKeys[targetKey]?.currentContext;
      if (targetCtx != null) {
        if (_locatePreferJump) {
          Scrollable.ensureVisible(
            targetCtx,
            alignment: 0.2,
            duration: Duration.zero,
          );
        } else {
          unawaited(
            Scrollable.ensureVisible(
              targetCtx,
              alignment: 0.2,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          );
        }
      } else {
        final offset = (visibleIndex * rpx(context, 120)).clamp(
          0.0,
          _scrollCtrl.position.maxScrollExtent,
        );
        if (_locatePreferJump) {
          _scrollCtrl.jumpTo(offset);
        } else {
          unawaited(
            _scrollCtrl.animateTo(
              offset,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
            ),
          );
        }
      }
      _locatePreferJump = false;
    });
  }

  void _locateQuotedMessage(Message msg) {
    final quote = QuoteMessageUtil.parse(msg.quoteMessage);
    if (quote?.id == null) return;
    _locateMessageById(quote!.id);
  }

  Future<void> _locateMessageById(int id, {bool quiet = false}) async {
    // 串行化定位：后一次等前一次结束。
    // quiet 且同 id 已成功：跳过进页 bootstrap+离线双触发；用户主动定位不跳过。
    final prev = _locateInFlight;
    final gate = Completer<void>();
    _locateInFlight = gate.future;
    try {
      if (prev != null) await prev;
      if (!mounted) return;
      if (quiet && _lastLocatedId == id && _didLocate) return;

      // 先占住 pending，避免扩读期间贴底逻辑把 limit shrink 回去。
      _pendingLocateId = id;
      _didLocate = false;
      _autoScrollMode = _AutoScrollMode.locating;
      _locatePreferJump = quiet;
      final messages = await _expandLimitUntilMessage(id);
      if (!mounted) return;
      // 用户点了「回到底部」等会清空 pending，视为取消本次定位。
      if (_pendingLocateId != id) return;
      final index = messages.indexWhere((m) => m.id == id);
      if (index < 0) {
        _pendingLocateId = null;
        _locatePreferJump = false;
        // 扩读失败时收回缓冲并回到最新，避免 limit 停在大值且窗口未裁剪。
        _requestScrollToBottom(reason: 'locate_failed', force: true);
        if (!quiet) _toast('无法定位原消息');
        return;
      }
      setState(() {
        _window = ChatMessageWindowState.forLocate(
          index: index,
          totalSize: messages.length,
        );
        _isInBottom = false;
      });
      _tryLocateMessage(messages);
      if (_didLocate) {
        _lastLocatedId = id;
        _autoScrollMode = _AutoScrollMode.reading;
      }
    } finally {
      if (!gate.isCompleted) gate.complete();
      if (identical(_locateInFlight, gate.future)) {
        _locateInFlight = null;
      }
    }
  }

  void _onCardTap(Message msg) {
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(msg.content ?? '{}');
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}

    if (msg.type == MessageType.userCard) {
      final userId = data['userId'];
      if (userId is int) {
        context.push(AppRoutes.friendUserPath(userId));
      } else if (userId != null) {
        final id = int.tryParse(userId.toString());
        if (id != null) context.push(AppRoutes.friendUserPath(id));
      }
      return;
    }

    if (msg.type == MessageType.groupCard) {
      if (CardMessageBubble.isGroupCardExpired(msg.sendTime)) {
        _toast('该名片已过期');
        return;
      }
      final groupId = data['groupId'];
      if (groupId is int) {
        context.push(AppRoutes.groupInfoPath(groupId));
      } else if (groupId != null) {
        final id = int.tryParse(groupId.toString());
        if (id != null) context.push(AppRoutes.groupInfoPath(id));
      }
    }
  }

  void _onFinancialCardTap(Message msg) {
    _toast('功能开发中');
  }

  Future<void> _onCloseTopMessage(Group group) async {
    final store = ref.read(chatStoreProvider);
    if (_isGroupManager()) {
      final ok = await showImConfirmDialog(
        context,
        title: '移除置顶',
        content: '将在当前群聊的所有成员中移除此置顶消息,确认移除?',
        confirmText: '移除',
      );
      if (ok == true && mounted) {
        final err = await store.removeGroupTopMessage(group.id);
        if (err != null && mounted) {
          _toast(err);
        }
      }
    } else {
      final err = await store.hideGroupTopMessage(group.id);
      if (err != null && mounted) {
        _toast(err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(chatListStreamProvider, (previous, next) {
      final chat = _findChat(next.value);
      if (chat == null || chat.unreadCount <= 0) return;
      final store = ref.read(chatStoreProvider);
      if (widget.chatType == ChatType.private) {
        store.activePrivateChat(widget.targetId);
      } else if (widget.chatType == ChatType.group) {
        store.activeGroupChat(widget.targetId);
      }
    });

    // 对齐 uniapp loading watcher：断线重连后更新已读状态
    ref.listen(
      chatOfflineSyncingProvider((
        chatType: widget.chatType,
        targetId: widget.targetId,
      )),
      (previous, next) {
        if (previous == true &&
            next == false &&
            widget.chatType == ChatType.private) {
          ref.read(chatStoreProvider).syncPrivateReadStatus(widget.targetId);
        }
      },
    );

    // WS 重连完成（appInit false→true）后补拉当前会话消息
    ref.listen(configStoreProvider.select((c) => c.appInit), (previous, next) {
      if (previous == false && next == true) {
        unawaited(_onWsReconnected());
      }
    });

    ref.listen(chatMessagesProvider(_msgQuery), (previous, next) {
      next.whenData((recentMessages) {
        _captureRecentOverflow(recentMessages);
        _lastRecentMessages = recentMessages;
        final messages =
            _currentMessagesSnapshot(recent: recentMessages) ??
            const <Message>[];
        final count = messages.length;
        final lastKey = messages.isEmpty ? null : _messageKey(messages.last);
        // 不依赖 _pendingInitialScroll：离线入库可能晚于首屏锁解除。
        if (_prevMessageCount == 0 &&
            count > 0 &&
            widget.locateMessageId == null) {
          _requestInitialScrollToBottom(count);
        }
        // 仅当末尾消息变化时才是「底部新消息」；上拉历史只增加头部，lastKey 不变。
        final appendedAtEnd =
            count > _prevMessageCount &&
            lastKey != null &&
            lastKey != _prevLastMessageKey;
        if (appendedAtEnd) {
          final last = messages.last;
          final selfId = ref.read(userStoreProvider)?.id ?? 0;
          final selfSend = last.selfSend || last.sendId == selfId;
          final visible =
              MessageType.isNormal(last.type) ||
              MessageType.isAction(last.type);
          if (visible) {
            if (_isInBottom || selfSend) {
              // 自己发送或贴底跟滚：收回扩读缓冲，只保留最新一页。
              // 定位扩读中不 shrink，避免把 limit 打回 pageSize。
              _requestScrollToBottom(
                reason: selfSend ? 'append_self' : 'append_follow',
                shrinkLimit:
                    _pendingLocateId == null && (selfSend || _isInBottom),
                force: selfSend,
              );
            } else if (mounted) {
              _pendingNewMessageDelta += count - _prevMessageCount;
              _newMessageBadgeTimer ??= Timer(_newMessageBadgeThrottle, () {
                final delta = _pendingNewMessageDelta;
                _pendingNewMessageDelta = 0;
                _newMessageBadgeTimer = null;
                if (!mounted || delta <= 0) return;
                setState(() => _newMessageSize += delta);
              });
            }
          }
        }
        _prevMessageCount = count;
        _prevLastMessageKey = lastKey;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _refreshAtMessage(),
        );
      });
    });

    final rawChatAsync = ref.watch(chatMessagesProvider(_msgQuery));
    final chatAsync = rawChatAsync.whenData(
      (recentMessages) =>
          _currentMessagesSnapshot(recent: recentMessages) ?? const <Message>[],
    );
    final chat = _findChat(ref.watch(chatListStreamProvider).value);
    final selfId = ref.watch(userStoreProvider)?.id ?? 0;
    final isGroup = widget.chatType == ChatType.group;
    final isPrivate = widget.chatType == ChatType.private;
    final enableRtcCall = RtcCallUtil.isRtcEnabled(
      ref.watch(configStoreProvider).systemConfig,
    );
    Group? group;
    if (isGroup) {
      ref.watch(groupStoreProvider);
      group = ref.read(groupStoreProvider.notifier).byId(widget.targetId);
    }
    final showNavMore = !isGroup || group?.quit != true;
    final inputMaskTip = _notAllowInputTip(group, isGroup, isPrivate);
    final toolCount = _visibleToolCount(
      isGroup: isGroup,
      isPrivate: isPrivate,
      enableRtcCall: enableRtcCall,
    );
    final toolsPanelHeight = _chatToolsHeight(context, toolCount);

    final topMessage = isGroup ? group?.topMessage : null;
    final showAtTip = chat != null && (chat.atMe || chat.atAll);
    final showBottomTip =
        _autoScrollMode == _AutoScrollMode.reading && !_isInBottom;

    chatAsync.whenData(_tryLocateMessage);

    return Scaffold(
      backgroundColor: ImColors.msgAreaBg,
      appBar: ImNavBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: rpx(context, 36)),
          color: ImColors.text,
          onPressed: () => context.pop(),
        ),
        title: _navTitle(chat, isGroup),
        subTitle: isGroup ? chat?.companyName : null,
        actions: showNavMore
            ? [
                IconButton(
                  icon: Icon(Icons.more_horiz, size: rpx(context, 44)),
                  color: ImColors.text,
                  onPressed: _onShowMore,
                ),
              ]
            : const [],
      ),
      body: Column(
        children: [
          if (group != null && topMessage != null)
            ChatTopMessageBar(
              group: group,
              topMessage: topMessage,
              showName: _showNameForSendId(
                topMessage.sendId,
                selfSend: topMessage.sendId == selfId,
                chatShowName: chat?.showName,
              ),
              canManage: _isGroupManager(),
              onLocate: () => _locateMessageById(topMessage.id ?? 0),
              onClose: () => _onCloseTopMessage(group!),
            ),
          Expanded(
            child: GestureDetector(
              onTap: _dismissPanels,
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  chatAsync.when(
                    loading: () => _messageListView(
                      context: context,
                      messages:
                          chatAsync.value ??
                          _currentMessagesSnapshot() ??
                          const [],
                      selfId: selfId,
                      isGroup: isGroup,
                      chat: chat,
                      group: group,
                    ),
                    error: (e, _) {
                      final cached =
                          chatAsync.value ?? _currentMessagesSnapshot();
                      if (cached != null && cached.isNotEmpty) {
                        return _messageListView(
                          context: context,
                          messages: cached,
                          selfId: selfId,
                          isGroup: isGroup,
                          chat: chat,
                          group: group,
                        );
                      }
                      return Center(child: Text(asApiException(e).message));
                    },
                    data: (messages) => _messageListView(
                      context: context,
                      messages: messages,
                      selfId: selfId,
                      isGroup: isGroup,
                      chat: chat,
                      group: group,
                    ),
                  ),
                  if (showAtTip || showBottomTip)
                    Positioned(
                      right: rpx(context, 30),
                      bottom: rpx(context, 30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showAtTip)
                            _LocateTip(
                              label: chat.atAll ? '@全体成员' : '有人@我',
                              onTap: () => _scrollToAtMessage(chat),
                            ),
                          if (showAtTip && showBottomTip)
                            SizedBox(height: rpx(context, 12)),
                          if (showBottomTip)
                            _LocateTip(
                              label: _newMessageSize > 0
                                  ? '$_newMessageSize条新消息'
                                  : '回到底部',
                              onTap: _onClickToBottom,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_atUserIds.isNotEmpty && isGroup && inputMaskTip == null)
            _ChatAtBar(
              atUserIds: _atUserIds,
              groupId: widget.targetId,
              onTap: _openAtBox,
            ),
          _SendBar(
            controller: _inputCtrl,
            focusNode: _inputFocus,
            canSend: _inputCtrl.text.trim().isNotEmpty || _atUserIds.isNotEmpty,
            isGroup: isGroup,
            isReceipt: _isReceipt,
            showRecord: inputMaskTip == null && _showRecord,
            inputMaskTip: inputMaskTip,
            quotePreview: _quoteMessage == null
                ? null
                : _quotePreviewText(
                    _quoteMessage!,
                    chatShowName: chat?.showName,
                  ),
            onClearQuote: () => setState(() => _quoteMessage = null),
            onToggleRecord: _toggleRecordMode,
            onSendRecord: _onSendRecord,
            onRecordToast: _toast,
            onSend: _send,
            onAtTap: _openAtBox,
            onToggleTools: _toggleToolsTab,
            onToggleEmo: _toggleEmoTab,
          ),
          if (inputMaskTip == null && _toolsOpen == _ChatPanelTab.tools)
            ChatToolsPanel(
              height: toolsPanelHeight,
              isGroup: isGroup,
              isReceipt: _isReceipt,
              onToggleReceipt: () => setState(() => _isReceipt = !_isReceipt),
              onPickFile: _pickAndSendFile,
              onPickAlbum: () => _pickAndSendImage(ImageSource.gallery),
              onPickCamera: () => _pickAndSendImage(ImageSource.camera),
              onPickVideo: _pickAndSendVideo,
              onPickVoice: _toggleRecordMode,
              showRtcTools: isPrivate && enableRtcCall,
              onPrivateVideo: () => unawaited(_onPrivateRtcCall('video')),
              onPrivateVoice: () => unawaited(_onPrivateRtcCall('voice')),
              showGroupRtcTools: isGroup && enableRtcCall,
              onGroupVideo: () => unawaited(_onGroupVideo()),
            ),
          if (inputMaskTip == null && _toolsOpen == _ChatPanelTab.emo)
            ChatEmotionPanel(onSelect: _insertEmotion),
        ],
      ),
    );
  }

  void _blurInputForPanel() {
    FocusScope.of(context).unfocus();
  }

  void _toggleToolsTab() {
    _blurInputForPanel();
    setState(() {
      _showRecord = false;
      _toolsOpen = _toolsOpen == _ChatPanelTab.tools
          ? _ChatPanelTab.none
          : _ChatPanelTab.tools;
    });
    if (_toolsOpen == _ChatPanelTab.tools) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestScrollToBottom(reason: 'toggle_tools', force: true);
        }
      });
    }
  }

  void _toggleEmoTab() {
    _blurInputForPanel();
    setState(() {
      _showRecord = false;
      _toolsOpen = _toolsOpen == _ChatPanelTab.emo
          ? _ChatPanelTab.none
          : _ChatPanelTab.emo;
    });
    if (_toolsOpen == _ChatPanelTab.emo) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestScrollToBottom(reason: 'toggle_emo', force: true);
        }
      });
    }
  }

  void _onRtCall(Message msg) {
    if (widget.chatType != ChatType.private) return;
    if (msg.type == MessageType.actRtVoice) {
      unawaited(_onPrivateRtcCall('voice'));
    } else if (msg.type == MessageType.actRtVideo) {
      unawaited(_onPrivateRtcCall('video'));
    }
  }

  Future<void> _onPrivateRtcCall(String mode) async {
    if (_guardTeenager(TeenagerBlockFeature.rtcCall)) return;
    if (widget.chatType != ChatType.private) return;

    final systemConfig = ref.read(configStoreProvider).systemConfig;
    if (!RtcCallUtil.isRtcEnabled(systemConfig)) {
      _toast('音视频通话未开启');
      return;
    }

    final friendStore = ref.read(friendStoreProvider.notifier);
    if (!friendStore.isFriend(widget.targetId)) {
      _toast('对方已不是您的好友，无法呼叫');
      return;
    }

    Friend? friend = friendStore.byId(widget.targetId);
    if (friend == null) {
      try {
        friend = await friendStore.refreshFriend(widget.targetId);
      } catch (_) {}
    }
    if (friend == null) {
      _toast('好友信息加载失败');
      return;
    }

    if (_targetUser == null) {
      try {
        _targetUser = await ref.read(userApiProvider).find(widget.targetId);
        if (mounted) setState(() {});
      } catch (_) {}
    }

    final rtcFriend = RtcCallUtil.friendForCall(
      base: friend,
      user: _targetUser,
    );
    final opened = ref
        .read(rtcServiceProvider)
        .openOutgoingCall(mode: mode, friend: rtcFriend);
    if (!opened && mounted) {
      _toast('当前已在通话中');
    }
  }

  Future<void> _onGroupVideo() async {
    if (_guardTeenager(TeenagerBlockFeature.rtcCall)) return;
    if (widget.chatType != ChatType.group) return;

    final systemConfig = ref.read(configStoreProvider).systemConfig;
    if (!RtcCallUtil.isRtcEnabled(systemConfig)) {
      _toast('音视频通话未开启');
      return;
    }

    try {
      final rtcInfo = await ref
          .read(systemApiProvider)
          .webrtcGroupInfo(widget.targetId);
      if (!mounted) return;
      if (rtcInfo['isChating'] == true) {
        await GroupRtcJoinSheet.show(
          context,
          ref,
          groupId: widget.targetId,
          rtcInfo: rtcInfo,
        );
        return;
      }

      final groupStore = ref.read(groupStoreProvider.notifier);
      var group = groupStore.byId(widget.targetId);
      group ??= await groupStore.loadGroupDetail(widget.targetId);
      await groupStore.loadMembers(widget.targetId);
      if (!mounted) return;

      final members = groupStore.membersOf(widget.targetId);
      final selfId = ref.read(userStoreProvider)?.id;
      if (selfId == null) return;

      final maxChannel = RtcCallUtil.webrtcMaxChannel(systemConfig);
      final selected = await GroupMemberSelector.show(
        context,
        members: members,
        group: group,
        mineId: selfId,
        checkedIds: [selfId],
        lockedIds: [selfId],
        maxSize: maxChannel,
      );
      if (selected == null || selected.length < 2 || !mounted) return;

      final memberMap = {for (final m in members) m.userId: m};
      final users = selected.map((id) {
        final m = memberMap[id];
        return {
          'id': id,
          'nickName': m?.showNickName ?? '',
          'headImage': m?.headImage ?? '',
          'isCamera': false,
          'isMicroPhone': true,
          'isShareScreen': false,
        };
      }).toList();

      ref
          .read(rtcServiceProvider)
          .openOutgoingGroupCall(
            groupId: widget.targetId,
            inviterId: selfId,
            userInfos: users,
          );
    } catch (e) {
      if (mounted) {
        _toast('获取通话信息失败');
      }
    }
  }

  void _insertEmotion(String code) {
    final token = EmotionUtil.inputTokenForWord(code);
    final value = _inputCtrl.value;
    final sel = value.selection;
    final start = sel.start >= 0 ? sel.start : value.text.length;
    final end = sel.end >= 0 ? sel.end : value.text.length;
    final newText = value.text.replaceRange(start, end, token);
    _inputCtrl.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + token.length),
    );
  }

  Chat? _findChat(List<Chat>? chats) {
    if (chats == null) return null;
    for (final c in chats) {
      if (c.type == widget.chatType && c.targetId == widget.targetId) {
        return c;
      }
    }
    return null;
  }

  List<_MsgItem> _withTimeDividers(List<Message> messages) {
    final out = <_MsgItem>[];
    int? prev;
    for (final m in messages) {
      if (m.type != MessageType.tipTime &&
          DateUtil.needTimeDivider(prev, m.sendTime)) {
        if (m.sendTime != null) {
          out.add(_MsgItem.divider(m.sendTime!));
        }
      }
      out.add(_MsgItem.message(m));
      prev = m.sendTime;
    }
    return out;
  }

  void _precacheVisibleImageMessages(
    BuildContext context,
    List<Message> visible,
  ) {
    final targets = <({String url, String? cacheKey})>[];
    for (final msg in visible) {
      final target = _imagePrecacheTarget(msg);
      if (target == null) continue;
      final dedupeKey = target.cacheKey ?? target.url;
      if (_precacheImageKeys.contains(dedupeKey)) continue;
      targets.add(target);
      if (targets.length >= 12) break;
    }
    if (targets.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isAlive) return;
      for (final target in targets) {
        final dedupeKey = target.cacheKey ?? target.url;
        if (_precacheImageKeys.contains(dedupeKey)) continue;
        if (NetworkImageFailCache.isTemporarilyBlocked(target.url)) continue;
        _precacheImageKeys.add(dedupeKey);
        unawaited(
          precacheImage(
                CachedNetworkImageProvider(
                  target.url,
                  cacheKey: target.cacheKey,
                ),
                context,
                onError: (error, stackTrace) {
                  NetworkImageFailCache.markFailed(target.url);
                },
              )
              .then((_) {
                NetworkImageFailCache.markSucceeded(target.url);
              })
              .catchError((_) {}),
        );
      }
    });
  }

  ({String url, String? cacheKey})? _imagePrecacheTarget(Message msg) {
    if (msg.type != MessageType.image) return null;
    final raw = msg.content;
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final thumbLoad = map['thumbLoad'] == true;
      final candidates = <String>[];
      void addCandidate(Object? raw) {
        if (raw == null) return;
        final value = raw.toString().trim();
        if (value.isEmpty || candidates.contains(value)) return;
        candidates.add(value);
      }

      if (thumbLoad) {
        addCandidate(map['previewUrl']);
        addCandidate(map['originUrl']);
        addCandidate(map['thumbUrl']);
      } else {
        addCandidate(map['thumbUrl']);
        addCandidate(map['previewUrl']);
        addCandidate(map['originUrl']);
      }
      if (candidates.isEmpty) return null;
      final url = candidates.first;
      if (url.startsWith('http://') || url.startsWith('https://')) {
        final fileId = map['fileId']?.toString().trim();
        String? role;
        final thumb = map['thumbUrl']?.toString().trim();
        final preview = map['previewUrl']?.toString().trim();
        final origin = map['originUrl']?.toString().trim();
        if (thumb != null && thumb.isNotEmpty && thumb == url) {
          role = 'thumb';
        } else if (preview != null && preview.isNotEmpty && preview == url) {
          role = 'preview';
        } else if (origin != null && origin.isNotEmpty && origin == url) {
          role = 'origin';
        } else {
          role = 'extra';
        }
        return (
          url: url,
          cacheKey: (fileId == null || fileId.isEmpty)
              ? null
              : 'img_${fileId}_$role',
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Widget _buildBubble({
    required Message msg,
    required bool selfSend,
    String? senderName,
    Set<GroupSenderRole> senderRoles = const {},
    String? chatShowName,
    VoidCallback? onResend,
    MessageLongPressCallback? onLongPress,
    VoidCallback? onQuoteTap,
    MessageLongPressCallback? onQuoteLongPress,
  }) {
    final quote = QuoteMessageUtil.parse(msg.quoteMessage);
    final quoteShowName = quote?.sendId == null
        ? null
        : _showNameForSendId(
            quote!.sendId,
            selfSend: quote.sendId == ref.read(userStoreProvider)?.id,
            chatShowName: chatShowName,
          );
    if (msg.type == MessageType.image) {
      return wrapMessageLongPress(
        ImageMessageBubble(
          message: msg,
          selfSend: selfSend,
          senderName: senderName,
          senderRoles: senderRoles,
          onResend: onResend,
          onContentChanged: (content) {
            ref
                .read(chatStoreProvider)
                .patchMessageContent(
                  chatType: widget.chatType,
                  chatTargetId: widget.targetId,
                  msg: msg,
                  content: content,
                );
          },
        ),
        onLongPress,
      );
    }
    if (msg.type == MessageType.video) {
      return wrapMessageLongPress(
        VideoMessageBubble(
          message: msg,
          selfSend: selfSend,
          senderName: senderName,
          senderRoles: senderRoles,
          onResend: onResend,
        ),
        onLongPress,
      );
    }
    if (msg.type == MessageType.file) {
      if (_isImageFileMessage(msg)) {
        return wrapMessageLongPress(
          ImageMessageBubble(
            message: msg,
            selfSend: selfSend,
            senderName: senderName,
            senderRoles: senderRoles,
            onResend: onResend,
          ),
          onLongPress,
        );
      }
      final dlKey = _fileDownloadKey(msg);
      return wrapMessageLongPress(
        FileMessageBubble(
          message: msg,
          selfSend: selfSend,
          senderName: senderName,
          senderRoles: senderRoles,
          onResend: onResend,
          onTap: () => _downloadFile(msg),
          downloadProgress: _fileDownloadProgress[dlKey],
        ),
        onLongPress,
      );
    }
    if (msg.type == MessageType.audio) {
      return wrapMessageLongPress(
        AudioMessageBubble(
          message: msg,
          selfSend: selfSend,
          senderName: senderName,
          senderRoles: senderRoles,
          onResend: onResend,
        ),
        onLongPress,
      );
    }
    if (msg.type == MessageType.actRtVoice ||
        msg.type == MessageType.actRtVideo) {
      return wrapMessageLongPress(
        ActRtMessageBubble(
          message: msg,
          selfSend: selfSend,
          senderName: senderName,
          senderRoles: senderRoles,
          onTap: () => _onRtCall(msg),
        ),
        onLongPress,
      );
    }
    if (msg.type == MessageType.userCard || msg.type == MessageType.groupCard) {
      return wrapMessageLongPress(
        CardMessageBubble(
          message: msg,
          selfSend: selfSend,
          senderName: senderName,
          senderRoles: senderRoles,
          onResend: onResend,
          onTap: () => _onCardTap(msg),
        ),
        onLongPress,
      );
    }
    if (msg.type == MessageType.contractCard ||
        msg.type == MessageType.loanCard ||
        msg.type == MessageType.productCard) {
      return wrapMessageLongPress(
        FinancialCardBubble(
          message: msg,
          selfSend: selfSend,
          variant: FinancialCardBubble.variantOf(msg.type),
          senderName: senderName,
          senderRoles: senderRoles,
          onTap: () => _onFinancialCardTap(msg),
        ),
        onLongPress,
      );
    }
    return TextBubble(
      message: msg,
      selfSend: selfSend,
      senderName: senderName,
      senderRoles: senderRoles,
      quoteShowName: quoteShowName,
      onResend: onResend,
      onLongPress: onLongPress,
      onQuoteTap: onQuoteTap,
      onQuoteLongPress: onQuoteLongPress,
    );
  }
}

class _MsgItem {
  _MsgItem.message(this.message) : isDivider = false, time = null;
  _MsgItem.divider(this.time) : isDivider = true, message = null;

  final Message? message;
  final int? time;
  final bool isDivider;
}

class _TimeTipRow extends StatelessWidget {
  const _TimeTipRow({required this.time});

  final int time;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: rpx(context, 60),
      child: Center(
        child: Text(
          DateUtil.formatBubbleTime(time),
          style: TextStyle(
            fontSize: rpx(context, 26),
            color: ImColors.textLighter,
          ),
        ),
      ),
    );
  }
}

class _SendBar extends StatelessWidget {
  const _SendBar({
    required this.controller,
    required this.focusNode,
    required this.canSend,
    required this.isGroup,
    required this.isReceipt,
    required this.showRecord,
    this.inputMaskTip,
    this.quotePreview,
    this.onClearQuote,
    required this.onToggleRecord,
    required this.onSendRecord,
    required this.onRecordToast,
    required this.onSend,
    required this.onAtTap,
    required this.onToggleTools,
    required this.onToggleEmo,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final bool isGroup;
  final bool isReceipt;
  final bool showRecord;
  final String? inputMaskTip;
  final String? quotePreview;
  final VoidCallback? onClearQuote;
  final VoidCallback onToggleRecord;
  final ValueChanged<Map<String, dynamic>> onSendRecord;
  final ValueChanged<String> onRecordToast;
  final VoidCallback onSend;
  final VoidCallback onAtTap;
  final VoidCallback onToggleTools;
  final VoidCallback onToggleEmo;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final iconSize = rpx(context, 60);

    final masked = inputMaskTip != null;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ImColors.navBarBg,
        border: Border(top: BorderSide(color: ImColors.formDivider)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: rpx(context, 80)),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            rpx(context, 10),
            rpx(context, 10),
            rpx(context, 10),
            rpx(context, 10) + bottomInset,
          ),
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _SendBarIcon(
                    icon: showRecord ? ImIcons.keyboard : ImIcons.voiceCircle,
                    size: iconSize,
                    onTap: masked ? () {} : onToggleRecord,
                  ),
                  Expanded(
                    child: showRecord
                        ? ChatRecordBar(
                            onSend: onSendRecord,
                            onToast: onRecordToast,
                          )
                        : Container(
                            margin: EdgeInsets.all(rpx(context, 5)),
                            constraints: BoxConstraints(
                              minHeight: rpx(context, 72),
                            ),
                            decoration: BoxDecoration(
                              color: ImColors.pageBg,
                              borderRadius: BorderRadius.circular(
                                rpx(context, 20),
                              ),
                              border: Border.all(color: ImColors.inputBorder),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(rpx(context, 20)),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: rpx(context, 40),
                                      maxHeight: rpx(context, 200),
                                    ),
                                    child: Semantics(
                                      label: 'chat_input',
                                      textField: true,
                                      // 避免 TextField 自带语义吞掉 label，便于 adb/UIAutomator 定位。
                                      child: ExcludeSemantics(
                                        child: TextField(
                                          key: const Key('chat_input_field'),
                                          controller: controller,
                                          focusNode: focusNode,
                                          readOnly: masked,
                                          enabled: !masked,
                                          minLines: 1,
                                          maxLines: 6,
                                          style: TextStyle(
                                            fontSize: rpx(context, 30),
                                            color: ImColors.text,
                                            height: 1.4,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            hintText: isReceipt
                                                ? '[回执消息]'
                                                : null,
                                            hintStyle: TextStyle(
                                              fontSize: rpx(context, 30),
                                              color: ImColors.textLighter,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (quotePreview != null) ...[
                                    SizedBox(height: rpx(context, 8)),
                                    Container(
                                      padding: EdgeInsets.all(rpx(context, 5)),
                                      decoration: BoxDecoration(
                                        color: ImColors.quotePreviewBg,
                                        borderRadius: BorderRadius.circular(
                                          rpx(context, 10),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              quotePreview!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: rpx(context, 28),
                                                color: ImColors.textLighter,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: onClearQuote,
                                            child: Icon(
                                              Icons.cancel,
                                              size: rpx(context, 40),
                                              color: ImColors.quoteRemoveIcon,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),
                  if (isGroup)
                    _SendBarIcon(
                      icon: ImIcons.at,
                      size: iconSize,
                      onTap: masked ? () {} : onAtTap,
                    ),
                  _SendBarIcon(
                    icon: ImIcons.emoji,
                    size: iconSize,
                    onTap: masked ? () {} : onToggleEmo,
                  ),
                  if (!masked && !showRecord && !canSend)
                    _SendBarIcon(
                      icon: ImIcons.add,
                      size: iconSize,
                      onTap: onToggleTools,
                    )
                  else if (!masked && !showRecord)
                    Padding(
                      padding: EdgeInsets.all(rpx(context, 5)),
                      child: _SendButton(onTap: onSend),
                    ),
                ],
              ),
              if (masked)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ImColors.pageBg,
                      borderRadius: BorderRadius.circular(rpx(context, 10)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: rpx(context, 15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ImIcon(
                            ImIcons.warningCircleEmpty,
                            size: rpx(context, 32),
                            color: ImColors.textLight,
                          ),
                          SizedBox(width: rpx(context, 6)),
                          Flexible(
                            child: Text(
                              inputMaskTip!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: rpx(context, 30),
                                color: ImColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _SendBarIcon extends StatelessWidget {
  const _SendBarIcon({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 10)),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ImIcon(icon, size: size, color: ImColors.sendBarIcon),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '发送',
      button: true,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: ImColors.mineHeaderGradient,
            borderRadius: BorderRadius.circular(rpx(context, 40)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('chat_send_button'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(rpx(context, 40)),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: rpx(context, 24),
                  vertical: rpx(context, 10),
                ),
                child: Text(
                  '发送',
                  style: TextStyle(
                    fontSize: rpx(context, 28),
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 「回到底部 / 有人@我」浮层。对齐 uniapp `.locate-tip`。
class _HistoryLoadingHeader extends StatelessWidget {
  const _HistoryLoadingHeader({
    required this.loading,
    required this.reachedStart,
  });

  final bool loading;
  final bool reachedStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: rpx(context, 20)),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              SizedBox(
                width: rpx(context, 28),
                height: rpx(context, 28),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ImColors.accent,
                ),
              ),
              SizedBox(width: rpx(context, 12)),
            ],
            Text(
              loading ? '正在加载历史消息…' : (reachedStart ? '已显示全部历史消息' : '下拉加载更多'),
              style: TextStyle(
                fontSize: rpx(context, 24),
                color: ImColors.textLighter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocateTip extends StatelessWidget {
  const _LocateTip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rpx(context, 25)),
        child: Opacity(
          opacity: 0.85,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: rpx(context, 30),
              vertical: rpx(context, 10),
            ),
            decoration: BoxDecoration(
              color: ImColors.locateTipBg,
              borderRadius: BorderRadius.circular(rpx(context, 25)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA5A4A4).withValues(alpha: 0.5),
                  blurRadius: rpx(context, 6),
                  spreadRadius: rpx(context, 2),
                  offset: Offset(0, rpx(context, 1)),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: rpx(context, 28),
                fontWeight: FontWeight.w600,
                color: ImColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// @ 成员预览条。对齐 uniapp `.chat-at-bar`。
class _ChatAtBar extends ConsumerWidget {
  const _ChatAtBar({
    required this.atUserIds,
    required this.groupId,
    required this.onTap,
  });

  final List<int> atUserIds;
  final int groupId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.read(groupStoreProvider.notifier).membersOf(groupId);
    final memberMap = {for (final m in members) m.userId: m};

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ImColors.navBarBg,
        border: Border(top: BorderSide(color: ImColors.formDivider)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: rpx(context, 10)),
          child: Row(
            children: [
              ImIcon(
                ImIcons.at,
                size: rpx(context, 36),
                color: ImColors.accent,
              ),
              Expanded(
                child: SizedBox(
                  height: rpx(context, 70),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: atUserIds.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(width: rpx(context, 6)),
                    itemBuilder: (context, index) {
                      final id = atUserIds[index];
                      if (id == -1) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: rpx(context, 3),
                          ),
                          child: HeadImage(name: '全体成员', size: 48),
                        );
                      }
                      final m = memberMap[id];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: rpx(context, 3),
                        ),
                        child: HeadImage(
                          url: m?.headImage,
                          name: m?.showNickName,
                          size: 48,
                        ),
                      );
                    },
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

/// 会话消息 watch 参数。
class ChatMsgQuery {
  const ChatMsgQuery({
    required this.type,
    required this.targetId,
    this.beforeSendTime,
    this.limit = 50,
  });

  final String type;
  final int targetId;
  final int? beforeSendTime;
  final int limit;

  @override
  bool operator ==(Object other) =>
      other is ChatMsgQuery &&
      other.type == type &&
      other.targetId == targetId &&
      other.beforeSendTime == beforeSendTime &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(type, targetId, beforeSendTime, limit);
}

final chatMessagesProvider = StreamProvider.family<List<Message>, ChatMsgQuery>(
  (ref, q) {
    return ref
        .read(chatStoreProvider)
        .watchMessages(
          q.type,
          q.targetId,
          limit: q.limit,
          beforeSendTime: q.beforeSendTime,
        );
  },
);
