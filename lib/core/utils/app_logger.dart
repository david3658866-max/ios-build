import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../config/env.dart';
import 'device_file_log.dart';

/// 默认关闭应用日志；需要排查时可用：
/// flutter run --dart-define=ENABLE_APP_LOG=true
const bool _enableAppLog = bool.fromEnvironment(
  'ENABLE_APP_LOG',
  defaultValue: false,
);

/// 全局日志实例。WS 收发、消息入库、token 刷新、状态变更统一走这里。
/// 真机：adb logcat -s flutter；adb 不稳时用 tool/pull_device_logs.ps1 拉文件日志。
final Logger log = Logger(
  // ENABLE_APP_LOG=true 时放开 debug，便于 profile/release 真机排查线路远程配置等。
  level: _enableAppLog ? Level.debug : Level.off,
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 6,
    lineLength: 100,
    colors: false,
    printEmojis: false,
  ),
  output: _LogOutput(),
);

/// logcat（debugPrint）+ 应用内文件双写。
class _LogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    if (!_enableAppLog) return;
    final text = event.lines.join('\n');
    debugPrint(text);
    if (Env.isDebug) {
      // 不阻塞 UI 线程。
      DeviceFileLog.append(text);
    }
  }
}
