import '../line/line_config.dart';
import '../line/line_probe_outcome.dart';
import '../ws/ws_event.dart';

/// 线路切换结果。对齐 uniapp `switchLine()` 返回值语义。
class LineSwitchOutcome {
  const LineSwitchOutcome({
    required this.success,
    required this.switched,
    required this.line,
  });

  final bool success;
  final bool switched;
  final LineConfig line;
}

/// 线路切换辅助。对齐 im-uniapp line-manager / line-switcher。
abstract final class LineSwitchUtil {
  static String successToast(String lineName) => '已切换到$lineName';

  /// 登录/注册页探活后自动切线。
  static String autoSwitchToast(String lineName) => '已切换至$lineName';

  /// 登录/注册页并发探活全部不可用。
  static const allLinesFailedToast = '网络异常，请稍后重试或手动切换线路';

  static const probeFailedToast = '该线路连接失败，请换一条试试';

  static const switchFailedToast = '切换失败，该线路暂不可用';

  static const reconnectFailedToast = '重连失败，请换一条线路或稍后重试';

  static const retryProbeToast = '正在重新检测线路…';

  static const retryProbeOkToast = '线路检测完成';

  static const retryProbeAllFailedToast = '仍无法连接，请检查网络后重试';

  /// 手切失败后倒计时自动切线。
  static const autoFailoverCountdownSeconds = 3;

  static const autoFailoverCancelLabel = '取消';

  /// chip「连接失败」旁的秒数，如 `3s`。
  static String autoFailoverChipSeconds(int seconds) => '${seconds}s';

  static String autoFailoverCountdown(String lineName, int seconds) =>
      '该线路不可用，$seconds 秒后切换到$lineName';

  static const autoFailoverCancelledToast = '已取消自动切换';

  /// 面板展示：通 120ms / 不通 / 未检测
  static String probeStatusLabel(LineProbeCacheEntry? entry) {
    if (entry == null) return '未检测';
    if (entry.ok) {
      final ms = entry.latencyMs;
      return ms == null ? '通' : '通 ${ms}ms';
    }
    return '不通';
  }

  /// 线路 chip 状态：对齐 uniapp line-switcher，始终看 HTTPS 探活（非真实 WS）。
  static WsStatus chipStatus({
    required bool isAuthenticated,
    required WsStatus lineStatus,
    required WsStatus wsStatus,
  }) =>
      lineStatus;

  /// 同线路再次选择且 WS 失败时，对齐 panel `afterLineSwitch` + `onLineSwitched`。
  static bool shouldReconnectSameLine({
    required bool isAuthenticated,
    required WsStatus chipStatus,
  }) =>
      isAuthenticated && chipStatus == WsStatus.disconnected;

  /// 注册/登录网络失败换线：从已探通列表里排除已试过的，按延迟顺序取下一条。
  static LineConfig? nextHealthyCandidate({
    required List<LineConfig> healthySortedByLatency,
    required Set<String> triedIds,
  }) {
    for (final line in healthySortedByLatency) {
      if (!triedIds.contains(line.id)) return line;
    }
    return null;
  }

  /// 登录/注册前是否可跳过全量探活。
  ///
  /// chip 已连通，且当前线路近期探活成功 → 直接请求，避免再闪「连接中」。
  static bool shouldSkipAuthPreProbe({
    required WsStatus lineStatus,
    required LineProbeCacheEntry? currentLineProbe,
    Duration maxAge = const Duration(minutes: 2),
    int? nowMs,
  }) {
    if (lineStatus != WsStatus.connected) return false;
    final entry = currentLineProbe;
    if (entry == null || !entry.ok) return false;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final age = now - entry.checkedAtMs;
    return age >= 0 && age <= maxAge.inMilliseconds;
  }
}
