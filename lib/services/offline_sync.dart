import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../core/di/app_providers.dart';
import '../core/enums/chat_type.dart';
import '../core/enums/cmd_type.dart';
import '../core/http/api_result.dart';
import '../core/storage/sync_cursor_keys.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/chat_message_window_util.dart';
import '../core/utils/message_storage_util.dart';
import '../models/group_message.dart';
import '../models/private_message.dart';
import '../router/app_router.dart';
import '../services/auth_controller.dart';
import '../services/badge_service.dart';
import '../stores/chat_store.dart';
import '../stores/config_store.dart';
import '../stores/friend_store.dart';
import '../stores/group_store.dart';
import '../stores/user_store.dart';
import '../widgets/im_feedback.dart';
import 'message_dispatcher.dart';

void _offlineToast(Ref ref, String message) {
  final ctx =
      ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;
  if (ctx != null && ctx.mounted) {
    ImFeedback.toast(ctx, message);
  }
}

bool _isAuthInitError(Object error) {
  final api = asApiException(error);
  if (api.code == 401 || api.code == 400) return true;
  return api.message.toLowerCase().contains('token');
}

Future<void> _handleOfflineInitError(Ref ref, Object error) async {
  if (_isAuthInitError(error)) {
    await ref
        .read(authControllerProvider.notifier)
        .forceExit('初始化失败,请重新登陆');
    return;
  }
  _offlineToast(ref, '部分数据加载失败，请稍后重试');
}

/// 离线同步。对应 im-uniapp App.vue pullOfflineChatSummary / pullSystemOfflineMessage。
class OfflineSync {
  OfflineSync(this.ref);

  final Ref ref;

  String _chatSyncKey(String chatType, int targetId) => '$chatType:$targetId';

  void _setChatSyncing(String chatType, int targetId, bool syncing) {
    final key = _chatSyncKey(chatType, targetId);
    final notifier = ref.read(activeChatOfflineSyncKeysProvider.notifier);
    notifier.setSyncing(key, syncing);
  }

  /// WS 登录成功（cmd0）后调用：拉会话摘要 + 未读补洞 + 系统离线。
  Future<void> pullAfterWsLogin() async {
    await pullSessionSummary();
    await pullUnreadPrivateGaps();
    await pullSystemOffline();
  }

  /// GET /message/offline/sessionSummary → 合并本地会话列表。
  /// 失败时降级全量拉取（对齐 App.vue pullOfflineChatSummary catch）。
  Future<void> pullSessionSummary() async {
    try {
      final list = await ref.read(messageApiProvider).sessionSummary();
      if (list.isNotEmpty) {
        await ref.read(chatStoreProvider).applySessionSummaries(list);
      }
      log.i('[Offline] sessionSummary ok, count=${list.length}');
    } catch (e, st) {
      log.w('[Offline] sessionSummary failed, fallback full pull: $e\n$st');
      await _pullFullOfflineMessages();
    }
  }

  /// 对有未读的私聊补拉 PENDING/DELIVERED，避免 minId 增量跳过空洞。
  Future<void> pullUnreadPrivateGaps() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final chats = await db.chatDao.listPrivateChatsWithUnread();
      if (chats.isEmpty) return;
      for (final chat in chats) {
        await _pullUnreadPrivateByChat(chat.targetId);
      }
      log.i('[Offline] unread gaps pulled, chats=${chats.length}');
    } catch (e, st) {
      log.w('[Offline] pullUnreadPrivateGaps failed: $e\n$st');
    }
  }

  Future<int> _pullUnreadPrivateByChat(int friendId) async {
    try {
      final msgs =
          await ref.read(messageApiProvider).loadUnreadPrivateByChat(friendId);
      if (msgs.isEmpty) return 0;
      // 未读数已由 sessionSummary 写入，补洞入库不得再 incrementUnread，也不走 tip。
      final chatStore = ref.read(chatStoreProvider);
      for (final m in msgs) {
        await chatStore.insertPrivate(m, incrementUnread: false);
      }
      final db = ref.read(appDatabaseProvider);
      final maxId =
          await db.messageDao.maxMessageId(ChatType.private, friendId);
      if (maxId > 0) {
        await db.chatDao.bumpLastMsgId(ChatType.private, friendId, maxId);
      }
      log.i(
        '[Offline] unread byChat friend=$friendId count=${msgs.length} maxId=$maxId',
      );
      return msgs.length;
    } catch (e, st) {
      log.w('[Offline] unread byChat friend=$friendId failed: $e\n$st');
      return 0;
    }
  }

  /// 全量离线降级：私聊 + 群聊 + 系统。
  Future<void> _pullFullOfflineMessages() async {
    final config = ref.read(configStoreProvider.notifier);
    final dispatcher = ref.read(messageDispatcherProvider);
    config.setChatSyncLoading(true);
    try {
      final api = ref.read(messageApiProvider);
      final privates = await api.loadOfflinePrivate(0);
      for (final m in privates) {
        await dispatcher.dispatch(CmdType.privateMessage, m.toJson());
      }
      final groups = await api.loadOfflineGroup(0);
      for (final m in groups) {
        await dispatcher.dispatch(CmdType.groupMessage, m.toJson());
      }
      await pullSystemOffline();
      log.i(
        '[Offline] full pull ok private=${privates.length} group=${groups.length}',
      );
    } catch (e) {
      log.w('[Offline] full pull failed: $e');
      _offlineToast(ref, '拉取离线消息失败，可稍后手动刷新');
    } finally {
      config.setChatSyncLoading(false);
      await dispatcher.flushBufferedMessages();
      await MessageStorageUtil.pruneMessages(
        ref.read(appDatabaseProvider).messageDao,
      );
    }
  }

  /// 拉系统离线消息并走 MessageDispatcher 入库。
  Future<void> pullSystemOffline() async {
    try {
      final dao = ref.read(appDatabaseProvider).syncCursorDao;
      final minSeq = await dao.getCursor(SyncCursorKeys.systemMsgMaxSeqNo);
      final msgs = await ref.read(messageApiProvider).loadOfflineSystem(minSeq);
      if (msgs.isEmpty) return;

      final dispatcher = ref.read(messageDispatcherProvider);
      var maxSeq = minSeq;
      for (final m in msgs) {
        await dispatcher.dispatch(CmdType.systemMessage, m.toJson());
        if (m.seqNo > maxSeq) maxSeq = m.seqNo;
      }
      if (maxSeq > minSeq) {
        await dao.setCursor(SyncCursorKeys.systemMsgMaxSeqNo, maxSeq);
      }
      log.i('[Offline] system offline count=${msgs.length} maxSeq=$maxSeq');
    } catch (e) {
      log.w('[Offline] system offline failed: $e');
    }
  }

  /// 按会话补离线。对齐 chat-box.vue loadChatOfflineMessages。
  ///
  /// [force] 为 true 时忽略 messagesLoaded 跳过（WS 重连后当前会话增量补拉）。
  Future<void> pullChatOffline({
    required String chatType,
    required int targetId,
    bool force = false,
  }) async {
    final chatStore = ref.read(chatStoreProvider);
    final db = ref.read(appDatabaseProvider);
    final chat = await chatStore.findChat(chatType, targetId);
    if (chat == null) return;

    final localCount =
        await db.messageDao.countMessages(chatType, targetId);

    if (!force && chat.messagesLoaded && localCount > 0 && chat.unreadCount <= 0) {
      if (chatType == ChatType.private) {
        // 角标已清仍可能有中间空洞，只补未读后返回。
        await _pullUnreadPrivateByChat(targetId);
        await ref.read(messageDispatcherProvider).flushBufferedMessages();
      }
      log.i(
        '[Offline] chat offline skip loaded $chatType/$targetId count=$localCount',
      );
      return;
    }

    if (localCount == 0) {
      await db.chatDao.resetOfflinePullState(chatType, targetId);
    }

    final refreshed = await chatStore.findChat(chatType, targetId);
    final dbMax = await db.messageDao.maxMessageId(chatType, targetId);
    final lastMsgId = refreshed?.lastMsgId ?? 0;
    // 私聊始终先拉未读：进会话可能已清 unreadCount，但中间空洞仍需补齐。
    final needUnread = chatType == ChatType.private;

    final dispatcher = ref.read(messageDispatcherProvider);
    final config = ref.read(configStoreProvider.notifier);
    final wasLoading = ref.read(configStoreProvider).chatSyncLoading;
    if (!wasLoading) {
      config.setChatSyncLoading(true);
    }
    _setChatSyncing(chatType, targetId, true);
    try {
      if (needUnread) {
        await _pullUnreadPrivateByChat(targetId);
      }

      final batchSize = ChatMessageWindowConfig.initialPullSize;
      var minId = dbMax > lastMsgId ? dbMax : lastMsgId;
      // 未读补洞后再读一次本地 max，避免仍用旧 cursor。
      final afterUnreadMax =
          await db.messageDao.maxMessageId(chatType, targetId);
      if (afterUnreadMax > minId) {
        minId = afterUnreadMax;
      }
      var totalFetched = 0;
      var syncedToEnd = false;
      if (chatType == ChatType.private) {
        while (true) {
          final msgs = await _loadPrivateOffline(
            targetId,
            minId,
            size: batchSize,
          );
          if (msgs.isEmpty) {
            syncedToEnd = true;
            break;
          }
          for (final m in msgs) {
            await dispatcher.dispatch(CmdType.privateMessage, m.toJson());
          }
          final maxId = await db.messageDao.maxMessageId(chatType, targetId);
          if (maxId > 0) {
            await db.chatDao.bumpLastMsgId(chatType, targetId, maxId);
          }
          totalFetched += msgs.length;
          if (maxId <= minId) {
            log.w(
              '[Offline] chat offline cursor stalled $chatType/$targetId '
              'minId=$minId maxId=$maxId fetched=${msgs.length}',
            );
            break;
          }
          minId = maxId;
          if (msgs.length < batchSize) {
            syncedToEnd = true;
            break;
          }
        }
      } else if (chatType == ChatType.group) {
        while (true) {
          final msgs = await _loadGroupOffline(
            targetId,
            minId,
            size: batchSize,
          );
          if (msgs.isEmpty) {
            syncedToEnd = true;
            break;
          }
          for (final m in msgs) {
            await dispatcher.dispatch(CmdType.groupMessage, m.toJson());
          }
          final maxId = await db.messageDao.maxMessageId(chatType, targetId);
          if (maxId > 0) {
            await db.chatDao.bumpLastMsgId(chatType, targetId, maxId);
          }
          totalFetched += msgs.length;
          if (maxId <= minId) {
            log.w(
              '[Offline] chat offline cursor stalled $chatType/$targetId '
              'minId=$minId maxId=$maxId fetched=${msgs.length}',
            );
            break;
          }
          minId = maxId;
          if (msgs.length < batchSize) {
            syncedToEnd = true;
            break;
          }
        }
      } else {
        return;
      }

      final maxId = await db.messageDao.maxMessageId(chatType, targetId);
      if (maxId > 0) {
        await db.chatDao.bumpLastMsgId(chatType, targetId, maxId);
      }
      await chatStore.setChatMessagesLoaded(chatType, targetId, syncedToEnd);
      log.i(
        '[Offline] chat offline $chatType/$targetId done '
        'fetched=$totalFetched syncedToEnd=$syncedToEnd maxId=$maxId',
      );
    } catch (e, st) {
      log.w('[Offline] chat offline failed: $e\n$st');
      await chatStore.setChatMessagesLoaded(chatType, targetId, false);
    } finally {
      _setChatSyncing(chatType, targetId, false);
      if (!wasLoading) {
        config.setChatSyncLoading(false);
        await dispatcher.flushBufferedMessages();
      }
    }
  }

  Future<List<PrivateMessage>> _loadPrivateOffline(
    int friendId,
    int minId, {
    int size = ChatMessageWindowConfig.initialPullSize,
  }) async {
    final api = ref.read(messageApiProvider);
    try {
      return await api.loadOfflinePrivateByChat(friendId, minId, size: size);
    } catch (e) {
      log.w('[Offline] byChat private failed, fallback global: $e');
      final selfId = ref.read(userStoreProvider)?.id ?? 0;
      final all = await api.loadOfflinePrivate(minId);
      return all.where((m) {
        final selfSend = m.sendId == selfId;
        final fid = selfSend ? m.recvId : m.sendId;
        return fid == friendId;
      }).toList();
    }
  }

  Future<List<GroupMessage>> _loadGroupOffline(
    int groupId,
    int minId, {
    int size = ChatMessageWindowConfig.initialPullSize,
  }) async {
    final api = ref.read(messageApiProvider);
    try {
      return await api.loadOfflineGroupByChat(groupId, minId, size: size);
    } catch (e) {
      log.w('[Offline] byChat group failed, fallback global: $e');
      final all = await api.loadOfflineGroup(minId);
      return all.where((m) => m.groupId == groupId).toList();
    }
  }

  /// 贴顶时按 maxId 向服务端分页拉更早历史。
  Future<int> pullOlderChatHistory({
    required String chatType,
    required int targetId,
    required int maxId,
    int limit = ChatMessageWindowConfig.preloadStep,
  }) async {
    if (maxId <= 0) return 0;
    final dispatcher = ref.read(messageDispatcherProvider);
    final api = ref.read(messageApiProvider);
    try {
      if (chatType == ChatType.private) {
        final msgs = await api.privateHistoryByChat(targetId, maxId, size: limit);
        if (msgs.isEmpty) return 0;
        for (final m in msgs) {
          await dispatcher.dispatch(CmdType.privateMessage, m.toJson());
        }
        await dispatcher.flushBufferedMessages();
        return msgs.length;
      }
      if (chatType == ChatType.group) {
        final msgs = await api.groupHistoryByChat(targetId, maxId, size: limit);
        if (msgs.isEmpty) return 0;
        for (final m in msgs) {
          await dispatcher.dispatch(CmdType.groupMessage, m.toJson());
        }
        await dispatcher.flushBufferedMessages();
        return msgs.length;
      }
    } catch (e) {
      log.w('[Offline] pullOlderChatHistory failed: $e');
    }
    return 0;
  }
}

final offlineSyncProvider = Provider<OfflineSync>((ref) => OfflineSync(ref));

class ChatOfflineSyncKeysNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  void setSyncing(String key, bool syncing) {
    if (syncing) {
      state = <String>{...state, key};
      return;
    }
    state = <String>{...state}..remove(key);
  }
}

final activeChatOfflineSyncKeysProvider =
    NotifierProvider<ChatOfflineSyncKeysNotifier, Set<String>>(
      ChatOfflineSyncKeysNotifier.new,
    );

final chatOfflineSyncingProvider =
    Provider.family<bool, ({String chatType, int targetId})>((ref, query) {
  final key = '${query.chatType}:${query.targetId}';
  return ref.watch(
    activeChatOfflineSyncKeysProvider.select((keys) => keys.contains(key)),
  );
});

/// WS 登录成功后：先拉好友/群 → 会话摘要 → 系统离线 → 补全会话资料。
/// 对齐 uniapp onReconnectWs / 首次 onConnect 离线同步。
Future<void> runOfflineSyncAfterWsLogin(Ref ref) async {
  final config = ref.read(configStoreProvider.notifier);
  config.setChatSyncLoading(true);
  try {
    await () async {
      await ref.read(chatStoreProvider).repairStaleSendingMessages();
      await Future.wait([
        ref.read(friendStoreProvider.notifier).loadFriends().catchError((_) {}),
        ref.read(groupStoreProvider.notifier).loadGroups().catchError((_) {}),
      ]);
      await ref.read(offlineSyncProvider).pullAfterWsLogin();
      await ref.read(chatStoreProvider).enrichFromContacts();
    }().timeout(const Duration(seconds: 15));
  } on TimeoutException {
    log.w('[Offline] pullAfterWsLogin timeout, continue with local chats');
  } catch (e) {
    log.w('[Offline] pullAfterWsLogin failed, continue with local chats: $e');
    await _handleOfflineInitError(ref, e);
  } finally {
    if (ref.mounted) {
      config.setChatSyncLoading(false);
      config.setAppInit(true);
      await ref.read(messageDispatcherProvider).flushBufferedMessages();
      refreshAllBadgesFromRef(ref);
    }
  }
}
