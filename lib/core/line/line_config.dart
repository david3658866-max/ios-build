/// 内置线路：Release 走生产 bgznp（4 条）；Debug 额外显示「本地调试」。
///
/// 构建：`--dart-define=APP_ENV=test` 时使用 de010 测试线路（仅联调/H5 测试包）。
/// 默认 `APP_ENV=prod`（正式 Release）。
///
/// 切换时 IM API + WebSocket + 扫码地址整组切换。
/// 取值与 im-uniapp `common/line-config.js` 一致（本期 Flutter 未单独配置 baseBizUrl）。
import 'package:flutter/foundation.dart';

class LineConfig {
  const LineConfig({
    required this.id,
    required this.name,
    required this.label,
    required this.host,
    required this.baseUrl,
    required this.wsUrl,
    required this.scanUrl,
  });

  final String id;
  final String name;
  final String label;
  final String host;

  /// IM REST API 前缀，例如 `https://zenty.bgznp.com/api`。
  final String baseUrl;

  /// WebSocket 地址，例如 `wss://zenty.bgznp.com/im`。
  final String wsUrl;

  /// 扫码跳转地址。
  final String scanUrl;
}

/// Hive 中保存当前线路 id 的 key。
const String kLineStorageKey = 'app_line_id';

const _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');

/// 生产 H5 扫码域（与 im-uniapp line-config 一致）。
const _prodH5Scan = 'https://kavun.bgznp.com';

/// 生产 bgznp：1 主 + 3 备。
const List<LineConfig> _prodRemoteLines = [
  LineConfig(
    id: 'line1',
    name: '主线路',
    label: 'bgznp 主通道',
    host: 'zenty.bgznp.com',
    baseUrl: 'https://zenty.bgznp.com/api',
    wsUrl: 'wss://zenty.bgznp.com/im',
    scanUrl: _prodH5Scan,
  ),
  LineConfig(
    id: 'line2',
    name: '备用线路1',
    label: 'bgznp 备用通道1',
    host: 'drako.bgznp.com',
    baseUrl: 'https://drako.bgznp.com/api',
    wsUrl: 'wss://drako.bgznp.com/im',
    scanUrl: _prodH5Scan,
  ),
  LineConfig(
    id: 'line3',
    name: '备用线路2',
    label: 'bgznp 备用通道2',
    host: 'muvin.bgznp.com',
    baseUrl: 'https://muvin.bgznp.com/api',
    wsUrl: 'wss://muvin.bgznp.com/im',
    scanUrl: _prodH5Scan,
  ),
  LineConfig(
    id: 'line4',
    name: '备用线路3',
    label: 'bgznp 备用通道3',
    host: 'jovik.bgznp.com',
    baseUrl: 'https://jovik.bgznp.com/api',
    wsUrl: 'wss://jovik.bgznp.com/im',
    scanUrl: _prodH5Scan,
  ),
];

/// 测试 de010：1 主 + 3 备（`APP_ENV=test`）。
const List<LineConfig> _testRemoteLines = [
  LineConfig(
    id: 'line1',
    name: '主线路',
    label: 'de010 主线路',
    host: 'kivola.de010.com',
    baseUrl: 'https://kivola.de010.com/api',
    wsUrl: 'wss://kivola.de010.com/im',
    scanUrl: 'https://novali.de010.com',
  ),
  LineConfig(
    id: 'line2',
    name: '备用线路1',
    label: 'de010 备用线路1',
    host: 'mexato.de010.com',
    baseUrl: 'https://mexato.de010.com/api',
    wsUrl: 'wss://mexato.de010.com/im',
    scanUrl: 'https://novali.de010.com',
  ),
  LineConfig(
    id: 'line3',
    name: '备用线路2',
    label: 'de010 备用线路2',
    host: 'roxani.de010.com',
    baseUrl: 'https://roxani.de010.com/api',
    wsUrl: 'wss://roxani.de010.com/im',
    scanUrl: 'https://novali.de010.com',
  ),
  LineConfig(
    id: 'line4',
    name: '备用线路3',
    label: 'de010 备用线路3',
    host: 'setura.de010.com',
    baseUrl: 'https://setura.de010.com/api',
    wsUrl: 'wss://setura.de010.com/im',
    scanUrl: 'https://novali.de010.com',
  ),
];

/// 当前构建环境的线上线路。
List<LineConfig> get kProductionLines =>
    _appEnv == 'test' ? _testRemoteLines : _prodRemoteLines;

/// 本机调试（仅 Debug 包出现在线路列表）。
const LineConfig kLocalDevLine = LineConfig(
  id: 'line_local',
  name: '本地调试',
  label: '127.0.0.1（adb reverse）',
  host: '127.0.0.1',
  baseUrl: 'http://127.0.0.1:27418',
  wsUrl: 'ws://127.0.0.1:27893/im',
  scanUrl: 'http://127.0.0.1:8080',
);

/// 构建时注入的局域网 IP（build-apk.ps1 自动检测），adb reverse 失效时可直连电脑。
const String kLocalDevLanHost =
    String.fromEnvironment('LOCAL_DEV_HOST', defaultValue: '');

/// 本地开发探活顺序：USB adb reverse → 局域网 IP。
List<String> get kLocalDevProbeHosts {
  if (kLocalDevLanHost.isEmpty) return const ['127.0.0.1'];
  return ['127.0.0.1', kLocalDevLanHost];
}

/// 按 host 生成本地开发线路（Debug 包默认 127.0.0.1）。
LineConfig localDevLineForHost(String host) => LineConfig(
      id: 'line_local',
      name: '本地调试',
      label: '本地 DEV ($host)',
      host: host,
      baseUrl: 'http://$host:27418',
      wsUrl: 'ws://$host:27893/im',
      scanUrl: 'http://$host:8080',
    );

/// 与历史代码兼容：线上线路常量名保留为 kLines。
List<LineConfig> get kLines => kProductionLines;

/// 线路面板展示列表。
List<LineConfig> get kVisibleLines =>
    kDebugMode ? [kLocalDevLine, ...kProductionLines] : kProductionLines;

/// 默认线路：Debug 本机，Release 主线路。
LineConfig get kDefaultLine => kDebugMode ? kLocalDevLine : kProductionLines.first;

/// 按 id 查找线路；兼容历史 line5。
LineConfig lineById(String? id) {
  if (id == null) return kDefaultLine;
  if (id == 'line5') return kDebugMode ? kLocalDevLine : kProductionLines.first;
  if (id == 'line_local' && !kDebugMode) return kProductionLines.first;
  for (final line in kVisibleLines) {
    if (line.id == id) return line;
  }
  return kDefaultLine;
}
