import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../core/utils/app_logger.dart';
import '../core/ws/ws_event.dart';

/// 全局配置 / 运行态。对应原 Pinia configStore。
class ConfigState {
  const ConfigState({
    /// 登录/注册页线路 chip：HTTP 探活结果（与 WS 无关）。
    this.lineStatus = WsStatus.connecting,
    /// 登录后主界面：真实 WebSocket 状态。
    this.wsStatus = WsStatus.disconnected,
    this.appInit = false,
    /// 全量/按会话离线同步中。对齐 uniapp chatStore.loading。
    this.chatSyncLoading = false,
    this.systemConfig,
  });

  /// 线路 HTTPS 探活状态（line-switcher 专用）。
  final WsStatus lineStatus;

  /// WebSocket 连接状态（主界面专用）。
  final WsStatus wsStatus;

  /// 应用是否已完成首屏初始化。
  final bool appInit;

  /// 离线消息批量同步中（全量降级 / 按会话补拉）。
  final bool chatSyncLoading;

  /// 系统配置（/system/config 返回）。
  final Map<String, dynamic>? systemConfig;

  ConfigState copyWith({
    WsStatus? lineStatus,
    WsStatus? wsStatus,
    bool? appInit,
    bool? chatSyncLoading,
    Map<String, dynamic>? systemConfig,
  }) {
    return ConfigState(
      lineStatus: lineStatus ?? this.lineStatus,
      wsStatus: wsStatus ?? this.wsStatus,
      appInit: appInit ?? this.appInit,
      chatSyncLoading: chatSyncLoading ?? this.chatSyncLoading,
      systemConfig: systemConfig ?? this.systemConfig,
    );
  }
}

class ConfigStore extends Notifier<ConfigState> {
  @override
  ConfigState build() => const ConfigState();

  /// 加载系统配置。
  Future<void> loadConfig() async {
    try {
      final cfg = await ref.read(systemApiProvider).config();
      state = state.copyWith(systemConfig: cfg);
    } catch (e) {
      log.w('[Config] loadConfig failed: $e');
    }
  }

  void setLineStatus(WsStatus status) =>
      state = state.copyWith(lineStatus: status);

  void setWsStatus(WsStatus status) =>
      state = state.copyWith(wsStatus: status);

  void setAppInit(bool value) {
    if (state.appInit == value) return;
    log.i('[Config] appInit $value');
    state = state.copyWith(appInit: value);
  }

  void setChatSyncLoading(bool value) {
    if (state.chatSyncLoading == value) return;
    log.i('[Config] chatSyncLoading $value');
    state = state.copyWith(chatSyncLoading: value);
  }
}

/// 是否显示音视频通话入口。对齐 uniapp chat-box enableRtcCall + webrtc.enable。
bool enableRtcCallFromConfig(Map<String, dynamic>? systemConfig) {
  // ios-build: RTC hybrid assets omitted; keep call entry off.
  return false;
}

final configStoreProvider =
    NotifierProvider<ConfigStore, ConfigState>(ConfigStore.new);
