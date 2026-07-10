import '../line/line_config.dart';

/// 运行环境。本期仅 Android/iOS，网络地址全部走线路配置（见 line_config.dart）。
enum AppEnv { de010 }

/// 全局环境配置。
///
/// 与 im-uniapp `.env.js` 不同：网络基址（BASE_URL/WS_URL）不再写死在这里，
/// 而是由当前选中的 [LineConfig] 提供，支持运行时切换线路。
abstract final class Env {
  static const AppEnv current = AppEnv.de010;

  /// 是否为调试构建（影响日志级别等）。
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;

  /// 缺省线路（首次启动、无持久化时使用）。
  static final LineConfig defaultLine = kDefaultLine;
}
