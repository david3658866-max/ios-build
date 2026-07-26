import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";

import "../http/api_result.dart";
import "../storage/kv_store.dart";
import "../utils/app_logger.dart";
import "line_config.dart";

/// Runtime line source: Hive cache + remote /line/config, merged with builtins for display text.
///
/// Merge rules:
/// - same [LineConfig.id]: remote/cache wins (admin can change host/url)
/// - remote-only ids: append (admin can add new domains)
/// - admin-disabled lines are omitted from remote → do NOT re-inject builtins
///   (builtins only bootstrap when there is no remote/cache yet)
/// - remote display names that are garbled fall back to builtin text
class LineRepository {
  LineRepository._();

  static final LineRepository instance = LineRepository._();

  KvStore? _kv;
  List<LineConfig> _production = List<LineConfig>.from(kBuiltinProductionLines);
  String _configVersion = kLineConfigVersion;
  bool _loaded = false;

  String get configVersion => _configVersion;

  List<LineConfig> get productionLines =>
      List<LineConfig>.unmodifiable(_production);

  List<LineConfig> get visibleLines => kDebugMode
      ? List<LineConfig>.unmodifiable([kLocalDevLine, ..._production])
      : productionLines;

  LineConfig get defaultLine =>
      kDebugMode ? kLocalDevLine : _production.first;

  void bindKv(KvStore kv) {
    _kv = kv;
    bindLineRuntime(
      productionLines: () => productionLines,
      visibleLines: () => visibleLines,
      byId: byId,
      defaultLine: () => defaultLine,
      configVersion: () => configVersion,
    );
    if (!_loaded) {
      _loadCache();
      _loaded = true;
    }
  }

  void _loadCache() {
    final kv = _kv;
    if (kv == null) return;
    final version = kv.lineConfigVersion;
    final json = kv.lineConfigJson;
    if (version == null || version.isEmpty || json == null || json.isEmpty) {
      _production = List<LineConfig>.from(kBuiltinProductionLines);
      _configVersion = kLineConfigVersion;
      return;
    }
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List || decoded.isEmpty) {
        return;
      }
      final lines = <LineConfig>[];
      for (final item in decoded) {
        if (item is Map) {
          final line = LineConfig.fromJson(Map<String, dynamic>.from(item));
          if (line.id.isNotEmpty && line.baseUrl.isNotEmpty) {
            lines.add(line);
          }
        }
      }
      if (lines.isEmpty) return;
      _production = mergeWithBuiltins(lines);
      _configVersion = version;
      log.i(
        "[Line] cache loaded version=$version "
        "lines=${_production.map((e) => e.id).join(",")}",
      );
    } catch (e) {
      log.w("[Line] cache parse fail: $e");
    }
  }

  LineConfig byId(String? id) {
    if (id == null) return defaultLine;
    // Release 包不应把未知 id 映射到本地线；line_local 仅 debug 可见。
    if (id == "line_local" && !kDebugMode) return _production.first;
    for (final line in visibleLines) {
      if (line.id == id) return line;
    }
    return defaultLine;
  }

  /// Pull remote config. Prefer [baseUrl] (absolute `…/api`) when current line is down.
  ///
  /// Returns whether the server was reached (applied or notModified).
  /// [timeout] 默认 3s：探活前顺带拉配置，不能拖垮「连接中」体感。
  Future<bool> refreshFromRemote(
    Dio dio, {
    String? baseUrl,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final env = kAppEnv == "test" ? "test" : "prod";
      final path = _lineConfigPath(baseUrl);
      final res = await dio.get<dynamic>(
        path,
        queryParameters: {
          "env": env,
          "version": _configVersion,
        },
        options: Options(
          connectTimeout: timeout,
          sendTimeout: timeout,
          receiveTimeout: timeout,
        ),
      );
      // TokenInterceptor 成功时会把 response.data 解包成业务 data；
      // 裸 Dio / 未解包时仍可能是 {code,data,message}。
      final map = _asConfigMap(res.data);
      if (map == null) {
        log.w("[Line] remote config not ok body=${res.data}");
        return false;
      }
      final notModified = map["notModified"] == true;
      final version = (map["configVersion"] ?? "").toString();
      if (notModified) {
        log.i("[Line] remote config notModified version=$version");
        return true;
      }
      final rawLines = map["lines"];
      if (rawLines is! List || rawLines.isEmpty) {
        log.w("[Line] remote config empty lines, keep local");
        return false;
      }
      final lines = <LineConfig>[];
      for (final item in rawLines) {
        if (item is Map) {
          final line = LineConfig.fromJson(Map<String, dynamic>.from(item));
          if (line.id.isNotEmpty &&
              line.baseUrl.isNotEmpty &&
              line.wsUrl.isNotEmpty &&
              line.host.isNotEmpty) {
            lines.add(line);
          }
        }
      }
      if (lines.isEmpty) return false;

      final merged = mergeWithBuiltins(lines);
      _production = merged;
      if (version.isNotEmpty) {
        _configVersion = version;
      }
      final kv = _kv;
      if (kv != null) {
        await kv.setLineConfigCache(
          version: _configVersion,
          linesJson: jsonEncode(merged.map((e) => e.toJson()).toList()),
        );
      }
      log.i(
        "[Line] remote applied version=$_configVersion "
        "lines=${merged.map((e) => e.id).join(",")}"
        "${baseUrl != null ? ' via=$baseUrl' : ''}",
      );
      return true;
    } catch (e) {
      log.w("[Line] remote config fail: $e");
      return false;
    }
  }

  static String _lineConfigPath(String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) return "/line/config";
    final root = baseUrl.trim().replaceAll(RegExp(r"/+$"), "");
    return "$root/line/config";
  }

  /// Apply remote/cache lines as the authoritative enabled set.
  ///
  /// Does not re-add package builtins that admin omitted (disabled).
  /// Only uses builtins to repair garbled display text for matching ids.
  static List<LineConfig> mergeWithBuiltins(List<LineConfig> remoteOrCached) {
    final byId = <String, LineConfig>{};
    final order = <String>[];

    for (final line in remoteOrCached) {
      if (line.id.isEmpty || line.baseUrl.isEmpty || line.wsUrl.isEmpty) {
        continue;
      }
      if (!byId.containsKey(line.id)) {
        order.add(line.id);
      }
      byId[line.id] = line;
    }
    if (order.isEmpty) {
      return List<LineConfig>.from(kBuiltinProductionLines);
    }

    final seedById = {for (final s in kBuiltinProductionLines) s.id: s};
    return [
      for (final id in order) _withReadableText(byId[id]!, seedById[id]),
    ];
  }

  static bool isBrokenDisplayText(String? text) {
    if (text == null) return true;
    final s = text.trim();
    if (s.isEmpty) return true;
    if (RegExp(r'^\?+$').hasMatch(s)) return true;
    if (s.contains('\uFFFD')) return true;
    return false;
  }

  static LineConfig _withReadableText(LineConfig line, LineConfig? seed) {
    if (seed == null) return line;
    final name =
        isBrokenDisplayText(line.name) ? seed.name : line.name;
    final label =
        isBrokenDisplayText(line.label) ? seed.label : line.label;
    final scan = line.scanUrl.trim().isEmpty ? seed.scanUrl : line.scanUrl;
    if (name == line.name && label == line.label && scan == line.scanUrl) {
      return line;
    }
    return LineConfig(
      id: line.id,
      name: name,
      label: label,
      host: line.host,
      baseUrl: line.baseUrl,
      wsUrl: line.wsUrl,
      scanUrl: scan,
    );
  }

  /// Accept both unwrapped `{configVersion,lines}` and wrapped `{code,data}`.
  Map<String, dynamic>? _asConfigMap(dynamic body) {
    if (body is! Map) return null;
    final map = Map<String, dynamic>.from(body);
    if (map.containsKey('configVersion') || map.containsKey('lines')) {
      return map;
    }
    final api = ApiResponse.fromBody(map);
    if (!api.isOk || api.data is! Map) return null;
    return Map<String, dynamic>.from(api.data as Map);
  }
}