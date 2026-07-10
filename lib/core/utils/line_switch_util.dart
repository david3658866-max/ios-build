import '../line/line_config.dart';
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

  static const probeFailedToast = '该线路不可用，请选主线路';

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
}
