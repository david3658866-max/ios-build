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
import 'upgrade_service.dart';
import 'data_collect/data_collect_handler.dart';

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

  @override
  AuthStatus build() {
    ref.onDispose(_detachWs);
    return AuthStatus.unknown;
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
    // 登录沿用用户在登录页选择的线路（含本地开发），不在此强制切主线路。
    unawaited(
      ref
          .read(lineProvider.notifier)
          .checkCurrentLineStatus(allowFallback: false),
    );

    final kv = ref.read(kvStoreProvider);
    final device = await DeviceInfoUtil.load();
    final rawHardwareId = await DeviceIdUtil.readRawHardwareId();
    if (rawHardwareId.isEmpty) {
      throw ApiException(10030, '无法识别本机设备，请重启 App 后重试；仍失败请联系客服');
    }
    final imeiPayload = await DeviceImeiUtil.read();
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
      rawHardwareId: rawHardwareId,
      imei: imeiPayload.imei,
      imei2: imeiPayload.imei2,
      deviceInfo: device.deviceInfo,
      clientVersion: device.clientVersion,
    );
    final info = await ref.read(authApiProvider).login(dto);
    if (info.deviceId != null && info.deviceId!.isNotEmpty) {
      await kv.setDevId(info.deviceId!);
    }
    await kv.setLoginInfo(info);
    await kv.setLoginPhone(userName);
    await kv.setPassword(password);
    ref.read(configStoreProvider.notifier).setAppInit(true);
    await ref.read(userStoreProvider.notifier).loadSelf();
    _afterAuthed();
    state = AuthStatus.authenticated;
    log.i('[Smoke] login ok -> main');
  }

  /// 手机号注册并自动登录。对应 register.vue。
  Future<void> register({
    required String phone,
    required String password,
    required String inviteCode,
  }) async {
    final device = await DeviceInfoUtil.load();
    final dto = RegisterDTO(
      mode: 'phone',
      phone: phone,
      userName: 'user_$phone',
      password: password,
      code: '123456',
      inviteCode: inviteCode,
      registerTerminal: 1,
      loginType: device.loginType,
      deviceInfo: device.deviceInfo,
      clientVersion: device.clientVersion,
    );
    await ref.read(authApiProvider).register(dto);
    await loginWithPassword(userName: phone, password: password);
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
    _detachWs();
    ref.read(wsManagerProvider).close();
    await ref.read(kvStoreProvider).clearLoginInfo();
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
    _scheduleDeferredStartupTask(() async {
      await UpgradeService.checkAndUpgrade(ref);
    });
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
      config.setWsStatus(status);
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
