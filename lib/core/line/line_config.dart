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
/// Bump when package builtin seeds change so cold clients re-pull /line/config.
const kLineConfigVersion = '2026-07-28-prod-44';

const _prodH5Scan = 'https://kavun.bgznp.com';

LineConfig _prodBuiltin({
  required String id,
  required String name,
  required String label,
  required String host,
  String? scanUrl,
}) =>
    LineConfig(
      id: id,
      name: name,
      label: label,
      host: host,
      baseUrl: 'https://$host/api',
      wsUrl: 'wss://$host/im',
      scanUrl: scanUrl ?? _prodH5Scan,
    );

/// Cold-start seeds: full prod app_line (line1-line44). Remote /line/config wins;
/// admin-disabled ids drop after remote apply (merge does not re-inject).
final List<LineConfig> kBuiltinProdLines = [
  _prodBuiltin(
    id: 'line1',
    name: '线路1',
    label: 'bgznp 主通道',
    host: 'zenty.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line2',
    name: '线路2',
    label: 'bgznp 备用通道1',
    host: 'castle.dvdda.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line3',
    name: '线路3',
    label: 'bgznp 备用通道2',
    host: 'forest.dvdda.com',
    scanUrl: 'https://forest.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line4',
    name: '线路4',
    label: 'bgznp 备用通道3',
    host: 'nuvor.dvdda.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line5',
    name: '线路5',
    label: 'bgznp 备用通道4',
    host: 'breeze.dvdda.com',
    scanUrl: 'https://kavun.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line6',
    name: '线路6',
    label: 'bgznp 备用通道4',
    host: 'planet.dvdda.com',
    scanUrl: 'https://kavun.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line7',
    name: '线路7',
    label: 'bgznp 备用通道4',
    host: 'bright.dvdda.com',
    scanUrl: 'https://kavun.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line8',
    name: '线路8',
    label: 'bgznp 备用通道4',
    host: 'muvin.dvdda.com',
    scanUrl: 'https://muvin.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line9',
    name: '线路9',
    label: 'bgznp 备用通道4',
    host: 'orange.dvdda.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line10',
    name: '线路10',
    label: 'bgznp 备用通道4',
    host: 'silver.dvdda.com',
    scanUrl: 'https://kavun.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line11',
    name: '线路11',
    label: 'scnjrm 线路11',
    host: 'jovik.dvdda.com',
    scanUrl: 'https://kavun.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line12',
    name: '线路12',
    label: 'scnjrm 线路12',
    host: 'fylax.dvdda.com',
    scanUrl: 'https://kavun.bgznp.com',
  ),
  _prodBuiltin(
    id: 'line13',
    name: '线路13',
    label: 'dvdda 线路13',
    host: 'kavun.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line14',
    name: '线路14',
    label: 'dvdda 线路14',
    host: 'bexal.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line15',
    name: '线路15',
    label: 'dvdda 线路15',
    host: 'velox.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line16',
    name: '线路16',
    label: 'zenty.bgznp.com',
    host: 'zenty.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line17',
    name: '线路17',
    label: 'castle.bgznp.com',
    host: 'castle.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line18',
    name: '线路18',
    label: 'muvin.bgznp.com',
    host: 'muvin.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line19',
    name: '线路19',
    label: 'nuvor.bgznp.com',
    host: 'nuvor.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line20',
    name: '线路20',
    label: 'breeze.bgznp.com',
    host: 'breeze.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line21',
    name: '线路21',
    label: 'planet.bgznp.com',
    host: 'planet.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line22',
    name: '线路22',
    label: 'bright.bgznp.com',
    host: 'bright.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line23',
    name: '线路23',
    label: 'forest.bgznp.com',
    host: 'forest.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line24',
    name: '线路24',
    label: 'orange.bgznp.com',
    host: 'orange.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line25',
    name: '线路25',
    label: 'silver.bgznp.com',
    host: 'silver.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line26',
    name: '线路26',
    label: 'jovik.bgznp.com',
    host: 'jovik.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line27',
    name: '线路27',
    label: 'kavun.bgznp.com',
    host: 'kavun.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line28',
    name: '线路28',
    label: 'bexal.bgznp.com',
    host: 'bexal.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line29',
    name: '线路29',
    label: 'velox.bgznp.com',
    host: 'velox.bgznp.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line30',
    name: '线路30',
    label: 'zenty.scnjrm.com',
    host: 'zenty.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line31',
    name: '线路31',
    label: 'castle.scnjrm.com',
    host: 'castle.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line32',
    name: '线路32',
    label: 'muvin.scnjrm.com',
    host: 'muvin.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line33',
    name: '线路33',
    label: 'nuvor.scnjrm.com',
    host: 'nuvor.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line34',
    name: '线路34',
    label: 'breeze.scnjrm.com',
    host: 'breeze.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line35',
    name: '线路35',
    label: 'planet.scnjrm.com',
    host: 'planet.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line36',
    name: '线路36',
    label: 'bright.scnjrm.com',
    host: 'bright.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line37',
    name: '线路37',
    label: 'forest.scnjrm.com',
    host: 'forest.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line38',
    name: '线路38',
    label: 'orange.scnjrm.com',
    host: 'orange.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line39',
    name: '线路39',
    label: 'silver.scnjrm.com',
    host: 'silver.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line40',
    name: '线路40',
    label: 'jovik.scnjrm.com',
    host: 'jovik.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line41',
    name: '线路41',
    label: 'fylax.scnjrm.com',
    host: 'fylax.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line42',
    name: '线路42',
    label: 'kavun.scnjrm.com',
    host: 'kavun.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line43',
    name: '线路43',
    label: 'bexal.scnjrm.com',
    host: 'bexal.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line44',
    name: '线路44',
    label: 'velox.scnjrm.com',
    host: 'velox.scnjrm.com',
    scanUrl: 'https://kavun.scnjrm.com',
  ),
];

LineConfig _testBuiltin({
  required String id,
  required String name,
  required String label,
  required String host,
}) =>
    LineConfig(
      id: id,
      name: name,
      label: label,
      host: host,
      baseUrl: 'https://$host/api',
      wsUrl: 'wss://$host/im',
      scanUrl: 'https://novali.de010.com',
    );

final List<LineConfig> kBuiltinTestLines = [
  _testBuiltin(
    id: 'line1',
    name: '线路1',
    label: 'de010 主线路',
    host: 'kivola.de010.com',
  ),
  _testBuiltin(
    id: 'line2',
    name: '线路2',
    label: 'de010 备用线路1',
    host: 'mexato.de010.com',
  ),
  _testBuiltin(
    id: 'line3',
    name: '线路3',
    label: 'de010 备用线路2',
    host: 'roxani.de010.com',
  ),
  _testBuiltin(
    id: 'line4',
    name: '线路4',
    label: 'de010 备用线路3',
    host: 'setura.de010.com',
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
