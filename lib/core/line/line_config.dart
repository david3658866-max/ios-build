// Built-in APP lines (bootstrap). Runtime list may be overridden via [LineRepository].
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
  final String baseUrl;
  final String wsUrl;
  final String scanUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'label': label,
        'host': host,
        'baseUrl': baseUrl,
        'wsUrl': wsUrl,
        'scanUrl': scanUrl,
      };

  factory LineConfig.fromJson(Map<String, dynamic> json) {
    return LineConfig(
      id: (json['id'] ?? json['lineKey'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      baseUrl: (json['baseUrl'] ?? '').toString(),
      wsUrl: (json['wsUrl'] ?? '').toString(),
      scanUrl: (json['scanUrl'] ?? '').toString(),
    );
  }
}

const String kLineStorageKey = 'app_line_id';

const kAppEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
const kLineConfigVersion = '2026-07-12-bgznp-v1';

const _prodH5Scan = 'https://kavun.bgznp.com';

const List<LineConfig> kBuiltinProdLines = [
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
    host: 'castle.bgznp.com',
    baseUrl: 'https://castle.bgznp.com/api',
    wsUrl: 'wss://castle.bgznp.com/im',
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
  // App 备用3 = nuvor（config.prod.local backup3）；jovik 仅 Web 用户端。
  LineConfig(
    id: 'line4',
    name: '备用线路3',
    label: 'bgznp 备用通道3',
    host: 'nuvor.bgznp.com',
    baseUrl: 'https://nuvor.bgznp.com/api',
    wsUrl: 'wss://nuvor.bgznp.com/im',
    scanUrl: _prodH5Scan,
  ),
];

const List<LineConfig> kBuiltinTestLines = [
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

List<LineConfig> get kBuiltinProductionLines =>
    kAppEnv == 'test' ? kBuiltinTestLines : kBuiltinProdLines;

const LineConfig kLocalDevLine = LineConfig(
  id: 'line_local',
  name: '本地调试',
  label: '127.0.0.1（adb reverse）',
  host: '127.0.0.1',
  baseUrl: 'http://127.0.0.1:27418',
  wsUrl: 'ws://127.0.0.1:27893/im',
  scanUrl: 'http://127.0.0.1:8080',
);

const String kLocalDevLanHost =
    String.fromEnvironment('LOCAL_DEV_HOST', defaultValue: '');

List<String> get kLocalDevProbeHosts {
  if (kLocalDevLanHost.isEmpty) return const ['127.0.0.1'];
  return ['127.0.0.1', kLocalDevLanHost];
}

LineConfig localDevLineForHost(String host) => LineConfig(
      id: 'line_local',
      name: '本地调试',
      label: '本地 DEV ($host)',
      host: host,
      baseUrl: 'http://$host:27418',
      wsUrl: 'ws://$host:27893/im',
      scanUrl: 'http://$host:8080',
    );

/// Compatibility: runtime overrides via [bindLineRuntime] (LineRepository).
List<LineConfig> Function()? _productionLinesOverride;
List<LineConfig> Function()? _visibleLinesOverride;
LineConfig Function(String?)? _byIdOverride;
LineConfig Function()? _defaultLineOverride;
String Function()? _configVersionOverride;

void bindLineRuntime({
  required List<LineConfig> Function() productionLines,
  required List<LineConfig> Function() visibleLines,
  required LineConfig Function(String?) byId,
  required LineConfig Function() defaultLine,
  required String Function() configVersion,
}) {
  _productionLinesOverride = productionLines;
  _visibleLinesOverride = visibleLines;
  _byIdOverride = byId;
  _defaultLineOverride = defaultLine;
  _configVersionOverride = configVersion;
}

String get effectiveLineConfigVersion =>
    _configVersionOverride?.call() ?? kLineConfigVersion;

/// Runtime production lines (remote cache or builtin).
List<LineConfig> get kProductionLines =>
    _productionLinesOverride?.call() ?? kBuiltinProductionLines;

List<LineConfig> get kLines => kProductionLines;

List<LineConfig> get kVisibleLines =>
    _visibleLinesOverride?.call() ??
    (kDebugMode ? [kLocalDevLine, ...kBuiltinProductionLines] : kBuiltinProductionLines);

LineConfig get kDefaultLine =>
    _defaultLineOverride?.call() ??
    (kDebugMode ? kLocalDevLine : kBuiltinProductionLines.first);

LineConfig lineById(String? id) {
  final override = _byIdOverride;
  if (override != null) return override(id);
  if (id == null) return kDefaultLine;
  if (id == 'line_local' && !kDebugMode) {
    return kBuiltinProductionLines.first;
  }
  for (final line in kVisibleLines) {
    if (line.id == id) return line;
  }
  return kDefaultLine;
}
