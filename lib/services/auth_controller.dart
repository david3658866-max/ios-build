import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/http/api_result.dart';
import '../api/api_providers.dart';
import '../core/di/app_providers.dart';
import '../core/enums/cmd_type.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/device_id_util.dart';
import '../core/utils/device_info_util.dart';
import '../core/utils/device_integrity_util.dart';
import '../core/utils/line_switch_util.dart';
import '../core/ws/ws_event.dart';
import '../models/login_dto.dart';
import '../models/register_dto.dart';
import '../router/app_router.dart';
import '../stores/chat_store.dart';
import '../stores/config_store.dart';
import '../stores/friend_store.dart';
import '../stores/group_store.dart';
import '../stores/user_store.dart';
import '../widgets/im_confirm_dialog.dart';
import '../widgets/im_toast.dart';
import 'keep_alive_service.dart';
import 'message_dispatcher.dart';
import 'offline_sync.dart';
import 'data_collect/data_collect_handler.dart';
import 'diagnostics/session_exit_tracker.dart';
import 'diagnostics/ui_breadcrumb.dart';

/// 鉴权状态机。
enum AuthStatus { unknown, authenticated, unauthenticated }

/// 认证 + 启动链路。对应 im-uniapp App.vue / login.vue。
class AuthController extends Notifier<AuthStatus> {
  StreamSubscription<WsEvent>? _wsEventSub;
  StreamSubscription<WsStatus>? _wsStatusSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  MessageDispatcher? _dispatcher;
  bool _wsWired = false;
  bool _networkOfflineNotified = false;
  WsStatus? _lastWsStatus;

  /// 本波未达 connected 的连续 disconnected 次数（用于 WS 自动切线）。
  int _wsDisconnectStreak = 0;

  /// WS 自动切线进行中，避免重复触发。
  bool _wsFailoverInFlight = false;

  void _resetWsDisconnectStreak() {
    _wsDisconnectStreak = 0;
  }

  @override
  AuthStatus build() {
    ref.onDispose(_detachWs);
    unawaited(_recordAppStart());
    return AuthStatus.unknown;
  }

  Future<void> _recordAppStart() async {
    await Future<void>.delayed(Duration.zero);
    if (!ref.mounted) return;
    final queue = ref.read(lineEventQueueProvider);
    final line = ref.read(lineProvider);

    final prev = await SessionExitTracker.consumePreviousForReport();
    final newSessionId = await queue.beginNewSession();
    await SessionExitTracker.markActive(sessionId: newSessionId);

    if (prev != null && prev.shouldReportSessionExit) {
      await queue.record(
        eventType: 'session_exit',
        triggerSource: 'startup',
        line: line,
        success: false,
        errorCategory: prev.errorCategory,
        errorMessage: prev.errorMessage ?? prev.exitKind,
        sessionIdOverride: prev.sessionId,
        extra: prev.toExtra(),
      );
    }

    await queue.record(
      eventType: 'app_start',
      triggerSource: 'bootstrap',
      line: line,
      success: true,
      extra: <String, dynamic>{
        if (prev != null) ...prev.toExtra(),
        if (prev == null) 'prevExit': 'none',
      },
    );
    UiBreadcrumb.clear();
    unawaited(queue.flush());
  }

  /// 冷启动。对应 App.vue onLaunch：有本地资料则尽快关闪屏，token 后台刷新。
  Future<void> bootstrap() async {
    if (_bootstrapRunning || state != AuthStatus.unknown) return;
    _bootstrapRunning = true;
    try {
      await _bootstrapImpl().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      log.w('[Auth] bootstrap 总超时，转登录');
      state = AuthStatus.unauthenticated;
      unawaited(_clearSession());
    } finally {
      _bootstrapRunning = false;
    }
  }

  bool _bootstrapRunning = false;

  static const _sessionTimeout = Duration(seconds: 6);
  static const _startupDeferredDelay = Duration(milliseconds: 600);

  Future<void> _bootstrapImpl() async {
    unawaited(ref.read(configStoreProvider.notifier).loadConfig());

    final kv = ref.read(kvStoreProvider);
    final loginInfo = kv.getLoginInfo();
    if (loginInfo == null) {
      state = AuthStatus.unauthenticated;
      log.i('[Smoke] bootstrap done -> login');
      _scheduleDeferredStartupTask(() async {
        await ref
            .read(lineProvider.notifier)
            .checkCurrentLineStatus(allowFallback: false);
      });
      return;
    }

    // 对齐 uniapp：本地有用户缓存时先上屏，网络刷新放后台。
    if (kv.getUserInfo() != null) {
      state = AuthStatus.authenticated;
      ref.read(configStoreProvider.notifier).setAppInit(true);
      log.i('[Auth] bootstrap fast -> main (cached user)');
      unawaited(_finishBootstrapInBackground());
      return;
    }

    try {
      final refreshed = await ref
          .read(dioClientProvider)
          .refreshSession()
          .timeout(_sessionTimeout);
      if (!refreshed) {
        state = AuthStatus.unauthenticated;
        unawaited(_clearSession());
        return;
      }
      await ref
          .read(userStoreProvider.notifier)
          .loadSelf()
          .timeout(_sessionTimeout);
      _afterAuthed();
      state = AuthStatus.authenticated;
      log.i('[Smoke] bootstrap done -> main');
      _scheduleDeferredStartupTask(() async {
        await ref
            .read(lineProvider.notifier)
            .checkCurrentLineStatus(allowFallback: false);
      });
    } on TimeoutException {
      log.w('[Auth] bootstrap 超时，转登录');
      state = AuthStatus.unauthenticated;
      unawaited(_clearSession());
    } catch (e) {
      log.w('[Auth] bootstrap 失败，转登录: $e');
      state = AuthStatus.unauthenticated;
      unawaited(_clearSession());
    }
  }

  /// 闪屏已关后的后台鉴权：refreshToken → 初始化 WS/离线同步。
  Future<void> _finishBootstrapInBackground() async {
    try {
      final refreshed = await ref
          .read(dioClientProvider)
          .refreshSession()
          .timeout(_sessionTimeout);
      if (!ref.mounted) return;
      if (!refreshed) {
        state = AuthStatus.unauthenticated;
        unawaited(_clearSession());
        return;
      }
      _afterAuthed();
      unawaited(_loadSelfInBackground());
      _scheduleDeferredStartupTask(() async {
        await ref
            .read(lineProvider.notifier)
            .checkCurrentLineStatus(allowFallback: false);
      });
    } on TimeoutException {
      log.w('[Auth] refresh 超时，使用缓存会话继续');
      if (!ref.mounted) return;
      _afterAuthed();
      unawaited(_loadSelfInBackground());
      _scheduleDeferredStartupTask(() async {
        await ref
            .read(lineProvider.notifier)
            .checkCurrentLineStatus(allowFallback: false);
      });
    } catch (e) {
      log.w('[Auth] background bootstrap failed: $e');
      if (!ref.mounted) return;
      state = AuthStatus.unauthenticated;
      unawaited(_clearSession());
    }
  }

  Future<void> _loadSelfInBackground() async {
    try {
      await ref
          .read(userStoreProvider.notifier)
          .loadSelf()
          .timeout(_sessionTimeout);
    } catch (e) {
      log.w('[Auth] loadSelf background failed: $e');
    }
  }

  /// 密码登录。对应 login.vue submit（手机号当 userName，mode=username）。
  Future<void> loginWithPassword({
    required String userName,
    required String password,
    String? totpCode,
  }) async {
    await _unloadStores();

    final kv = ref.read(kvStoreProvider);
    final device = await DeviceInfoUtil.load();
    final rawHardwareId = await DeviceIdUtil.readRawHardwareId();
    // 新包：ANDROID_ID 坏值应已由 appgen 兜底；仍为空时不本地硬拦，交给服务端
    //（过渡期 require-hardware-id=false 可放行；恢复强校验后服务端会再拒）
    if (rawHardwareId.isEmpty) {
      log.w('[Auth] rawHardwareId empty after appgen fallback, continue login');
    }
    final integrity = await DeviceIntegrityUtil.probe();
    final deviceCheckToken = await DeviceIdUtil.readDeviceCheckToken();
    final dto = LoginDTO(
      mode: 'username',
      terminal: 1,
      userName: userName,
      phone: userName,
      email: '',
      code: '',
      password: password,
      totpCode: totpCode,
      loginType: device.loginType,
      platform: device.loginType,
      rawHardwareId: rawHardwareId.isEmpty ? null : rawHardwareId,
      isPhysicalDevice: integrity.isPhysicalDevice,
      emulatorSuspect: integrity.emulatorSuspect,
      deviceCheckToken: deviceCheckToken.isEmpty ? null : deviceCheckToken,
      deviceInfo: device.deviceInfo,
      clientVersion: device.clientVersion,
    );
    try {
      final info = await _withAuthLineFailover(
        () => ref.read(authApiProvider).login(dto),
        apiPath: '/login',
      );
      if (info.deviceId != null && info.deviceId!.isNotEmpty) {
        await kv.setDevId(info.deviceId!);
      }
      await kv.setLoginInfo(info);
      await kv.setLoginPhone(userName);
      await kv.clearStoredPassword();
      await ref.read(lineEventQueueProvider).record(
            eventType: 'auth_result',
            triggerSource: 'login',
            success: true,
            apiPath: '/login',
          );
      unawaited(ref.read(lineEventQueueProvider).flush());
      ref.read(configStoreProvider.notifier).setAppInit(true);
      await ref.read(userStoreProvider.notifier).loadSelf();
      _afterAuthed();
      state = AuthStatus.authenticated;
      log.i('[Smoke] login ok -> main');
    } catch (e) {
      await ref.read(lineEventQueueProvider).record(
            eventType: 'auth_result',
            triggerSource: 'login',
            success: false,
            error: e,
            apiPath: '/login',
            bizCode: e is ApiException ? e.code : null,
          );
      unawaited(ref.read(lineEventQueueProvider).flush());
      rethrow;
    }
  }

  /// 手机号注册并自动登录（邀请码注册，暂不传短信验证码）。
  Future<void> register({
    required String phone,
    required String password,
    required String inviteCode,
  }) async {
    final device = await DeviceInfoUtil.load();
    final dto = RegisterDTO(
      mode: 'phone',
      phone: phone,
      // userName 由服务端生成 u{用户ID}
      password: password,
      // 短信验证码暂未启用；后端 App 邀请码注册不校短信
      inviteCode: inviteCode,
      registerTerminal: 1,
      loginType: device.loginType,
      deviceInfo: device.deviceInfo,
      clientVersion: device.clientVersion,
    );
    try {
      await _withAuthLineFailover(
        () => ref.read(authApiProvider).register(dto),
        apiPath: '/register',
      );
      await ref.read(lineEventQueueProvider).record(
            eventType: 'auth_result',
            triggerSource: 'register',
            success: true,
            apiPath: '/register',
          );
      unawaited(ref.read(lineEventQueueProvider).flush());
      await loginWithPassword(userName: phone, password: password);
    } catch (e) {
      await ref.read(lineEventQueueProvider).record(
            eventType: 'auth_result',
            triggerSource: 'register',
            success: false,
            error: e,
            apiPath: '/register',
            bizCode: e is ApiException ? e.code : null,
          );
      unawaited(ref.read(lineEventQueueProvider).flush());
      rethrow;
    }
  }

  /// 登录/注册：必要时先探活选线；遇网络错误最多换 2 条已通线路重试（合计 ≤3 次）。
  /// 业务错误（邀请码/密码等）不换线。
  ///
  /// 当前线路已连通且近期探活成功时，跳过登录前全量探活，避免 chip 再闪「连接中」。
  Future<T> _withAuthLineFailover<T>(
    Future<T> Function() action, {
    required String apiPath,
  }) async {
    final line = ref.read(lineProvider);
    final lineStatus = ref.read(configStoreProvider).lineStatus;
    final probe = ref.read(lineProbeCacheProvider)[line.id];
    final skipProbe = LineSwitchUtil.shouldSkipAuthPreProbe(
      lineStatus: lineStatus,
      currentLineProbe: probe,
    );
    if (skipProbe) {
      log.i('[Auth] skip pre-$apiPath probe, ${line.id} already connected');
    } else {
      await ref
          .read(lineProvider.notifier)
          .checkCurrentLineStatus(allowFallback: true);
    }
    final tried = <String>{};
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      final current = ref.read(lineProvider);
      tried.add(current.id);
      try {
        return await action();
      } catch (e) {
        lastError = e;
        final api = asApiException(e);
        if (!isNetworkApiError(api)) rethrow;
        log.w(
          '[Auth] $apiPath network on ${current.id}/${current.host}, '
          'failover attempt=${attempt + 1}',
        );
        final next = await ref
            .read(lineProvider.notifier)
            .failoverToNextHealthyLine(triedIds: tried);
        if (next == null) rethrow;
      }
    }
    throw lastError ?? ApiException.network();
  }

  Future<void> logout() async {
    state = AuthStatus.unauthenticated;
    await _clearSession();
  }

  /// 系统消息强制下线。对齐 App.vue USER_BANNED / USER_UNREG。
  Future<void> forceExit(String message) async {
    ref.read(wsManagerProvider).close();
    final ctx = ref
        .read(goRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;
    if (ctx != null && ctx.mounted) {
      await showImConfirmDialog(
        ctx,
        title: '提示',
        content: message,
        showCancel: false,
      );
    }
    await logout();
  }

  Future<void> _clearSession() async {
    unawaited(KeepAliveService.stopKeepAlive(ref));
    ref.read(expectedWsReconnectProvider.notifier).reset();
    _detachWs();
    ref.read(wsManagerProvider).close();
    final kv = ref.read(kvStoreProvider);
    await kv.clearLoginInfo();
    await kv.clearStoredPassword();
    await _purgeLocalStores();
    ref.read(configStoreProvider.notifier).setAppInit(false);
    await ref.read(lineProvider.notifier).resetToPrimaryLine();
    unawaited(
      ref
          .read(lineProvider.notifier)
          .checkCurrentLineStatus(allowFallback: false),
    );
  }

  void handleSessionExpired() {
    state = AuthStatus.unauthenticated;
    _detachWs();
    ref.read(wsManagerProvider).close();
    ref.read(configStoreProvider.notifier).setAppInit(false);
    unawaited(ref.read(kvStoreProvider).clearLoginInfo());
    unawaited(ref.read(kvStoreProvider).clearStoredPassword());
    ref.read(userStoreProvider.notifier).clear();
    ref.invalidate(friendStoreProvider);
    ref.invalidate(groupStoreProvider);
    unawaited(_clearChatDataSafe());
    unawaited(
      ref
          .read(lineProvider.notifier)
          .checkCurrentLineStatus(allowFallback: false),
    );
  }

  /// 对齐 uniapp unloadStore：清 user/chat/friend/group。
  Future<void> _purgeLocalStores() async {
    if (!ref.mounted) return;
    ref.read(userStoreProvider.notifier).clear();
    await _clearChatDataSafe();
    if (!ref.mounted) return;
    ref.invalidate(friendStoreProvider);
    ref.invalidate(groupStoreProvider);
  }

  Future<void> _clearChatDataSafe() async {
    if (!ref.mounted) return;
    try {
      await ref.read(chatStoreProvider).clearAllData();
    } catch (_) {}
  }

  /// 登录前清旧缓存。对应 login.vue unloadStore()。
  Future<void> _unloadStores() async {
    await _purgeLocalStores();
  }

  void _afterAuthed() {
    ref.read(configStoreProvider.notifier).setAppInit(true);
    unawaited(_afterAuthedAsync());
  }

  Future<void> _afterAuthedAsync() async {
    await ref.read(kvStoreProvider).syncDevIdFromLoginInfo();
    _wireWs();
    _listenConnectivity();
    _dispatcher = ref.read(messageDispatcherProvider);
    _dispatcher!.start();
    _connectWs();
    _scheduleDeferredStartupTask(() async {
      await ref
          .read(dataCollectHandlerProvider)
          .syncPendingTasks(reason: 'auth');
    });
    _scheduleDeferredStartupTask(_bootstrapLocal);
    _scheduleDeferredStartupTask(() async {
      await ref
          .read(lineProvider.notifier)
          .checkCurrentLineStatus(allowFallback: false);
    });
    _scheduleDeferredStartupTask(() async {
      await KeepAliveService.startKeepAlive(ref);
    });
    // 不启用「发现新版本」弹窗（AppConstants.upgradeEnabled=false）。
  }

  void _scheduleDeferredStartupTask(Future<void> Function() task) {
    unawaited(
      Future<void>.delayed(_startupDeferredDelay, () async {
        if (!ref.mounted) return;
        try {
          await task();
        } catch (e) {
          log.w('[Auth] deferred startup task failed: $e');
        }
      }),
    );
  }

  /// 对齐 uniapp loadStore().then：本地数据就绪即 appInit=true，网络拉取不阻塞。
  Future<void> _bootstrapLocal() async {
    final config = ref.read(configStoreProvider.notifier);
    try {
      await ref.read(chatStoreProvider).repairStaleSendingMessages();
      if (ref.mounted) config.setAppInit(true);
      await Future.wait([
        ref.read(friendStoreProvider.notifier).loadFriends().catchError((_) {}),
        ref.read(groupStoreProvider.notifier).loadGroups().catchError((_) {}),
      ]);
      await ref.read(chatStoreProvider).enrichFromContacts();
    } catch (e) {
      log.w('[Auth] bootstrapLocal failed: $e');
    } finally {
      if (ref.mounted) {
        config.setAppInit(true);
        await ref.read(messageDispatcherProvider).flushBufferedMessages();
      }
    }
  }

  void _connectWs() {
    final kv = ref.read(kvStoreProvider);
    final token = kv.accessToken;
    if (token == null || token.isEmpty) return;
    final line = ref.read(lineProvider);
    ref
        .read(wsManagerProvider)
        .connect(wsUrl: line.wsUrl, token: token, devId: kv.effectiveDevId);
  }

  void _wireWs() {
    if (_wsWired) return;
    _wsWired = true;
    final ws = ref.read(wsManagerProvider);
    final config = ref.read(configStoreProvider.notifier);
    _wsStatusSub = ws.statusStream.listen((status) {
      final prev = _lastWsStatus;
      _lastWsStatus = status;
      config.setWsStatus(status);
      // connecting/authing 是握手过程态：上报为失败会严重污染后台「失败率」。
      // 仅上报终态：connected=成功，disconnected=失败。
      if (status == WsStatus.connecting || status == WsStatus.authing) {
        return;
      }
      unawaited(ref.read(lineEventQueueProvider).record(
            eventType: 'ws_state',
            triggerSource: 'ws_status',
            success: status == WsStatus.connected,
            wsStatus: status.name,
            extra: {'fromStatus': prev?.name, 'toStatus': status.name},
          ));
      if (status == WsStatus.connected) {
        _resetWsDisconnectStreak();
        ref
            .read(lineProvider.notifier)
            .markCurrentLineConnected(source: 'ws_connected');
        unawaited(ref.read(lineEventQueueProvider).flush());
        return;
      }
      if (status == WsStatus.disconnected) {
        unawaited(_onWsDisconnectedTerminal());
      }
      // 对齐 uniapp：appInit 由 loadStore/离线同步完成控制，WS 断线不反复打回「正在初始化」。
    });
    ws.onLoginSuccess = () {
      unawaited(runOfflineSyncAfterWsLogin(ref));
      unawaited(
        ref
            .read(dataCollectHandlerProvider)
            .syncPendingTasks(reason: 'ws-login'),
      );
    };
    _wsEventSub = ws.events.listen(_onWsEvent);
  }

  Future<void> _onWsDisconnectedTerminal() async {
    if (state != AuthStatus.authenticated) {
      _resetWsDisconnectStreak();
      return;
    }
    if (ref.read(expectedWsReconnectProvider.notifier).consume()) {
      return;
    }
    _wsDisconnectStreak++;
    if (_wsFailoverInFlight) return;
    if (!LineSwitchUtil.shouldTriggerWsDisconnectFailover(
      consecutiveDisconnectsWithoutConnect: _wsDisconnectStreak,
      deviceOffline: false,
      cooldownUntil: null,
    )) {
      return;
    }
    _wsFailoverInFlight = true;
    try {
      final switched =
          await ref.read(lineProvider.notifier).failoverOnWsFailure();
      if (!ref.mounted) return;
      if (switched) {
        _resetWsDisconnectStreak();
        final name = ref.read(lineProvider).name;
        _showGlobalToast(LineSwitchUtil.autoSwitchToast(name));
      }
    } finally {
      _wsFailoverInFlight = false;
    }
  }

  /// 对齐 uniapp `uni.onNetworkStatusChange`：断网提示 + 恢复后探活并重连 WS。
  void _listenConnectivity() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (state != AuthStatus.authenticated) return;
      final offline =
          results.isEmpty || results.every((r) => r == ConnectivityResult.none);
      if (offline) {
        ref
            .read(configStoreProvider.notifier)
            .setWsStatus(WsStatus.disconnected);
        if (!_networkOfflineNotified) {
          _networkOfflineNotified = true;
          _showGlobalToast('网络连接已断开');
        }
        return;
      }
      _networkOfflineNotified = false;
      unawaited(
        ref
            .read(lineProvider.notifier)
            .checkCurrentLineStatus(allowFallback: false),
      );
      unawaited(_reconnectAfterNetwork());
    });
  }

  /// 对齐 uniapp reconnectWs：先 loadUser，再用当前线路地址重连 WS。
  Future<void> _reconnectAfterNetwork() async {
    final ws = ref.read(wsManagerProvider);
    if (ws.isConnected ||
        ws.status == WsStatus.connecting ||
        ws.status == WsStatus.authing) {
      return;
    }
    try {
      await ref.read(userStoreProvider.notifier).loadSelf();
    } catch (e) {
      log.w('[Auth] loadSelf before reconnect failed: $e');
      Future.delayed(const Duration(seconds: 5), () {
        if (ref.mounted && state == AuthStatus.authenticated) {
          unawaited(_reconnectAfterNetwork());
        }
      });
      return;
    }
    final kv = ref.read(kvStoreProvider);
    final token = kv.accessToken;
    if (token == null || token.isEmpty) return;
    final line = ref.read(lineProvider);
    ws.connect(wsUrl: line.wsUrl, token: token, devId: kv.effectiveDevId);
  }

  void _showGlobalToast(String message) {
    final ctx = ref
        .read(goRouterProvider)
        .routerDelegate
        .navigatorKey
        .currentContext;
    if (ctx != null && ctx.mounted) {
      ImToast.show(ctx, message, duration: const Duration(seconds: 2));
    }
  }

  void _detachWs() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _dispatcher?.stop();
    _dispatcher = null;
    _wsStatusSub?.cancel();
    _wsStatusSub = null;
    _wsEventSub?.cancel();
    _wsEventSub = null;
    _wsWired = false;
    _resetWsDisconnectStreak();
    _wsFailoverInFlight = false;
  }

  void _onWsEvent(WsEvent e) {
    if (e.cmd == CmdType.forceLogout) {
      log.w('[Auth] 异地登录，被强制下线');
      unawaited(logout());
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);
