import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../core/config/app_constants.dart';
import '../core/http/api_result.dart';
import '../core/line/line_config.dart';
import '../core/storage/kv_store.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/line_error_util.dart';

class LineEventQueue {
  LineEventQueue({
    required this.kv,
    required this.getLine,
    required this.getBaseUrl,
    this.httpClientAdapter,
  });

  static const int _maxQueueSize = 1000;
  static const int _batchSize = 50;

  final KvStore kv;
  final LineConfig Function() getLine;
  final String Function() getBaseUrl;
  /// 测试可注入，避免 Flutter TestBinding 劫持真实 HTTP。
  final HttpClientAdapter? httpClientAdapter;
  final _uuid = const Uuid();

  bool _flushing = false;
  bool _flushAgain = false;
  PackageInfo? _packageInfo;

  Future<void> record({
    required String eventType,
    required bool success,
    String? triggerSource,
    LineConfig? line,
    String? fromLineId,
    String? toLineId,
    int? latencyMs,
    Object? error,
    String? errorCategory,
    String? errorMessage,
    String? apiPath,
    int? httpStatus,
    int? bizCode,
    String? wsStatus,
    Map<String, dynamic>? extra,
    String? sessionIdOverride,
  }) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final activeLine = line ?? getLine();
      final networkType = await _networkType();
      final resolvedCategory =
          success ? null : (errorCategory ?? _classifyError(error));
      final resolvedMessage =
          _clipErrorMessage(errorMessage) ?? _safeErrorMessage(error);

      Map<String, dynamic>? mergedExtra =
          extra == null ? null : Map<String, dynamic>.from(extra);
      if (eventType == 'line_probe_result' && !success) {
        mergedExtra = {
          ...?mergedExtra,
          ...LineErrorUtil.probeDiagnosisExtra(
            success: false,
            networkType: networkType,
            errorCategory: resolvedCategory,
          ),
        };
      }

      final event = <String, dynamic>{
        'eventId': _uuid.v4(),
        'sessionId': (sessionIdOverride != null && sessionIdOverride.isNotEmpty)
            ? sessionIdOverride
            : await _sessionId(),
        'installHash': await _installId(),
        'userId': kv.getLoginInfo()?.userId,
        'eventType': eventType,
        'triggerSource': triggerSource,
        'lineId': activeLine.id,
        'lineName': activeLine.name,
        'lineHost': activeLine.host,
        'fromLineId': fromLineId,
        'toLineId': toLineId,
        'lineConfigVersion': effectiveLineConfigVersion,
        'appEnv': kAppEnv,
        'appVersion': await _appVersion(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'osVersion': Platform.operatingSystemVersion,
        'networkType': networkType,
        'success': success,
        'latencyMs': latencyMs,
        'errorCategory': resolvedCategory,
        'errorMessage': resolvedMessage,
        'apiPath': apiPath,
        'httpStatus': httpStatus,
        'bizCode': bizCode,
        'wsStatus': wsStatus,
        'occurredAtMs': now,
        'extraJson': mergedExtra == null ? null : jsonEncode(mergedExtra),
      };
      await _append(event);
    } catch (e) {
      log.w('[LineEvent] record ignored: $e');
    }
  }

  /// 每次冷启动轮换会话 ID，便于把「上次退出」与本轮启动对齐。
  Future<String> beginNewSession() async {
    final id = _uuid.v4();
    await kv.set(StorageKeys.lineEventSessionId, id);
    await kv.flush();
    return id;
  }

  Future<void> flush() async {
    if (_flushing) {
      // 并发 flush 不能直接丢弃：否则刚写入的 connected 会一直趴在队列里，
      // 直到队列被挤爆时还可能因优先级低被删掉。
      _flushAgain = true;
      return;
    }
    _flushing = true;
    try {
      do {
        _flushAgain = false;
        final rows = _loadQueue();
        if (rows.isEmpty) break;
        final batch = rows.take(_batchSize).toList();
        final dio = Dio(BaseOptions(
          baseUrl: getBaseUrl(),
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ));
        if (httpClientAdapter != null) {
          dio.httpClientAdapter = httpClientAdapter!;
        }
        try {
          final headers = <String, dynamic>{};
          final token = kv.accessToken;
          if (token != null && token.isNotEmpty) {
            headers['accessToken'] = token;
          }
          final res = await dio.post(
            '/line/event/report',
            data: {'events': batch},
            options: Options(headers: headers),
          );
          final api = ApiResponse.fromBody(res.data);
          if (!api.isOk) {
            log.w('[LineEvent] flush rejected code=${api.code}');
            break;
          }
          final sentIds =
              batch.map((e) => e['eventId']).whereType<String>().toSet();
          // 必须重新读队列：上传期间可能又写入了 connected 等终态，
          // 若用旧 snapshot 回写会把新事件覆盖丢失。
          final latest = _loadQueue();
          final remain =
              latest.where((e) => !sentIds.contains(e['eventId'])).toList();
          await _saveQueue(remain);
          log.i(
            '[LineEvent] uploaded ${sentIds.length}, remain=${remain.length}',
          );
        } finally {
          dio.close();
        }
      } while (_flushAgain);
    } catch (e) {
      log.w('[LineEvent] flush deferred: $e');
    } finally {
      _flushing = false;
      if (_flushAgain) {
        _flushAgain = false;
        unawaited(flush());
      }
    }
  }

  Future<void> _append(Map<String, dynamic> event) async {
    final rows = _loadQueue();
    rows.add(event);
    if (rows.length > _maxQueueSize) {
      rows.sort((a, b) {
        final aKeep = _eventPriority(a);
        final bKeep = _eventPriority(b);
        if (aKeep != bKeep) return aKeep.compareTo(bKeep);
        return ((a['occurredAtMs'] as num?)?.toInt() ?? 0)
            .compareTo((b['occurredAtMs'] as num?)?.toInt() ?? 0);
      });
      rows.removeRange(0, rows.length - _maxQueueSize);
    }
    await _saveQueue(rows);
  }

  int _eventPriority(Map<String, dynamic> event) {
    final type = event['eventType']?.toString() ?? '';
    final ok = event['success'] == true;
    final ws = event['wsStatus']?.toString() ?? '';
    // 数字越大越保留。WS 终态必须高于过程噪声与探活成功。
    if (type == 'session_exit') return 5;
    if (type == 'ws_state' && (ws == 'connected' || ws == 'disconnected')) {
      return 5;
    }
    if (type == 'line_probe_round' || type == 'app_start') return 4;
    if (type == 'line_switch' || type == 'auth_result') return 3;
    if (!ok) return 2;
    if (ok && type == 'line_probe_result') return 0;
    return 1;
  }

  List<Map<String, dynamic>> _loadQueue() {
    final raw = kv.get<String>(StorageKeys.lineEventQueue);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> rows) async {
    await kv.set(StorageKeys.lineEventQueue, jsonEncode(rows));
    await kv.flush();
  }

  Future<String> _sessionId() async {
    final existing = kv.get<String>(StorageKeys.lineEventSessionId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await kv.set(StorageKeys.lineEventSessionId, id);
    return id;
  }

  Future<String> _installId() async {
    final existing = kv.get<String>(StorageKeys.lineEventInstallId);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid.v4();
    await kv.set(StorageKeys.lineEventInstallId, id);
    return id;
  }

  Future<String> _appVersion() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!.version;
  }

  Future<String> _networkType() async {
    try {
      final values = await Connectivity().checkConnectivity();
      if (values.contains(ConnectivityResult.wifi)) return 'wifi';
      if (values.contains(ConnectivityResult.mobile)) return 'mobile';
      if (values.contains(ConnectivityResult.none)) return 'none';
    } catch (_) {}
    return 'unknown';
  }

  String? _classifyError(Object? error) => LineErrorUtil.classify(error);

  String? _clipErrorMessage(String? text) {
    if (text == null || text.isEmpty) return null;
    final cleaned =
        text.replaceAll(RegExp(r'accessToken=[^,\s]+'), 'accessToken=***');
    return cleaned.length > 240 ? cleaned.substring(0, 240) : cleaned;
  }

  String? _safeErrorMessage(Object? error) {
    if (error == null) return null;
    final text = error is ApiException ? error.message : error.toString();
    return _clipErrorMessage(text);
  }
}
