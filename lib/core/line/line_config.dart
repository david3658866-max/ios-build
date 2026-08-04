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
const kLineConfigVersion = '2026-08-04-prod-35p';

/// Prod preferred pool: all 35 builtins (4 new RU x5 + 3 old roots x5).
const Set<String> kPreferredBuiltinLineIds = {
  'line448',
  'line458',
  'line468',
  'line478',
  'line449',
  'line459',
  'line469',
  'line479',
  'line450',
  'line460',
  'line470',
  'line480',
  'line451',
  'line461',
  'line471',
  'line481',
  'line452',
  'line462',
  'line472',
  'line482',
  'line433',
  'line386',
  'line390',
  'line427',
  'line118',
  'line59',
  'line391',
  'line52',
  'line56',
  'line388',
  'line55',
  'line65',
  'line439',
  'line109',
  'line119',
};

bool isPreferredBuiltinLine(String id) =>
    kPreferredBuiltinLineIds.contains(id);

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

/// Cold-start seeds: 35 lines (4 new RU + 3 old roots, each x5); all in preferred pool. Remote /line/config still wins.
final List<LineConfig> kBuiltinProdLines = [
  _prodBuiltin(
    id: 'line448',
    name: '线路448',
    label: 'jjk5.bobobo.site',
    host: 'jjk5.bobobo.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line458',
    name: '线路458',
    label: 'ob5e.wansuxinxi.site',
    host: 'ob5e.wansuxinxi.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line468',
    name: '线路468',
    label: 'zhkh.panjimaoxian.site',
    host: 'zhkh.panjimaoxian.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line478',
    name: '线路478',
    label: 'v5rh.cqtsdx.top',
    host: 'v5rh.cqtsdx.top',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line449',
    name: '线路449',
    label: 'xjhk.bobobo.site',
    host: 'xjhk.bobobo.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line459',
    name: '线路459',
    label: 'mp68.wansuxinxi.site',
    host: 'mp68.wansuxinxi.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line469',
    name: '线路469',
    label: 'aki8.panjimaoxian.site',
    host: 'aki8.panjimaoxian.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line479',
    name: '线路479',
    label: 'a1sv.cqtsdx.top',
    host: 'a1sv.cqtsdx.top',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line450',
    name: '线路450',
    label: 'mieb.bobobo.site',
    host: 'mieb.bobobo.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line460',
    name: '线路460',
    label: 'jivy.wansuxinxi.site',
    host: 'jivy.wansuxinxi.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line470',
    name: '线路470',
    label: 'kv51.panjimaoxian.site',
    host: 'kv51.panjimaoxian.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line480',
    name: '线路480',
    label: 'u42o.cqtsdx.top',
    host: 'u42o.cqtsdx.top',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line451',
    name: '线路451',
    label: 'jbzx.bobobo.site',
    host: 'jbzx.bobobo.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line461',
    name: '线路461',
    label: 'qcz0.wansuxinxi.site',
    host: 'qcz0.wansuxinxi.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line471',
    name: '线路471',
    label: 'znqw.panjimaoxian.site',
    host: 'znqw.panjimaoxian.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line481',
    name: '线路481',
    label: 'jpgx.cqtsdx.top',
    host: 'jpgx.cqtsdx.top',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line452',
    name: '线路452',
    label: 'rlnu.bobobo.site',
    host: 'rlnu.bobobo.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line462',
    name: '线路462',
    label: 'z2ga.wansuxinxi.site',
    host: 'z2ga.wansuxinxi.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line472',
    name: '线路472',
    label: 'rqoo.panjimaoxian.site',
    host: 'rqoo.panjimaoxian.site',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line482',
    name: '线路482',
    label: 'klal.cqtsdx.top',
    host: 'klal.cqtsdx.top',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line433',
    name: '线路433',
    label: 'canyon.bgznp.com',
    host: 'canyon.bgznp.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line386',
    name: '线路386',
    label: 'mint.scnjrm.com',
    host: 'mint.scnjrm.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line390',
    name: '线路390',
    label: 'nimbus.dvdda.com',
    host: 'nimbus.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line427',
    name: '线路427',
    label: 'anvil.bgznp.com',
    host: 'anvil.bgznp.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line118',
    name: '线路118',
    label: 'sage.scnjrm.com',
    host: 'sage.scnjrm.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line59',
    name: '线路59',
    label: 'nova.dvdda.com',
    host: 'nova.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line391',
    name: '线路391',
    label: 'onyx.bgznp.com',
    host: 'onyx.bgznp.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line52',
    name: '线路52',
    label: 'quartz.scnjrm.com',
    host: 'quartz.scnjrm.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line56',
    name: '线路56',
    label: 'prism.dvdda.com',
    host: 'prism.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line388',
    name: '线路388',
    label: 'nimbus.bgznp.com',
    host: 'nimbus.bgznp.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line55',
    name: '线路55',
    label: 'prism.scnjrm.com',
    host: 'prism.scnjrm.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line65',
    name: '线路65',
    label: 'cedar.dvdda.com',
    host: 'cedar.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line439',
    name: '线路439',
    label: 'emberon.bgznp.com',
    host: 'emberon.bgznp.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line109',
    name: '线路109',
    label: 'oak.scnjrm.com',
    host: 'oak.scnjrm.com',
    scanUrl: 'https://zenty.scnjrm.com',
  ),
  _prodBuiltin(
    id: 'line119',
    name: '线路119',
    label: 'sage.dvdda.com',
    host: 'sage.dvdda.com',
    scanUrl: 'https://zenty.scnjrm.com',
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
