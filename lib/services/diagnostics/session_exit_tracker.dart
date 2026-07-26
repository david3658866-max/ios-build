import 'dart:convert';

import '../../core/config/app_constants.dart';
import '../../core/storage/kv_store.dart';
import '../../core/utils/app_logger.dart';
import 'ui_breadcrumb.dart';

/// 上一会话退出摘要（启动时消费并上报）。
class PrevSessionExit {
  const PrevSessionExit({
    required this.state,
    required this.atMs,
    required this.sessionId,
    required this.exitKind,
    this.errorType,
    this.errorMessage,
    this.stack,
    this.breadcrumbs = const [],
  });

  /// active | background | detached | dart_error
  final String state;
  final int atMs;
  final String? sessionId;

  /// graceful | abnormal | dart_error
  final String exitKind;
  final String? errorType;
  final String? errorMessage;
  final String? stack;
  final List<Map<String, dynamic>> breadcrumbs;

  bool get isGraceful => exitKind == 'graceful';
  bool get shouldReportSessionExit => !isGraceful;

  String? get errorCategory {
    switch (exitKind) {
      case 'dart_error':
        return 'dart_error';
      case 'abnormal':
        return 'abnormal_exit';
      default:
        return null;
    }
  }

  Map<String, dynamic> toExtra() => <String, dynamic>{
        'prevExit': exitKind,
        'prevState': state,
        'prevAtMs': atMs,
        if (sessionId != null && sessionId!.isNotEmpty)
          'prevSessionId': sessionId,
        if (errorType != null && errorType!.isNotEmpty) 'errorType': errorType,
        if (errorMessage != null && errorMessage!.isNotEmpty)
          'errorMessage': errorMessage,
        if (stack != null && stack!.isNotEmpty) 'stack': stack,
        if (breadcrumbs.isNotEmpty) 'breadcrumbs': breadcrumbs,
      };
}

/// 进程会话退出标记：用于下次启动判断是否异常退出。
///
/// 注意：iOS 权限弹窗会触发 [AppLifecycleState.inactive]，不可据此标为 background。
abstract final class SessionExitTracker {
  static KvStore? _kv;

  static void bind(KvStore kv) {
    _kv = kv;
  }

  static Future<void> markActive({String? sessionId}) async {
    await _writeMarker(
      state: 'active',
      sessionId: sessionId ?? _currentSessionId(),
      keepError: false,
    );
  }

  static Future<void> markBackground() async {
    if (_currentState() == 'dart_error') return;
    await _writeMarker(
      state: 'background',
      sessionId: _currentSessionId(),
      keepError: false,
    );
  }

  static Future<void> markDetached() async {
    if (_currentState() == 'dart_error') return;
    await _writeMarker(
      state: 'detached',
      sessionId: _currentSessionId(),
      keepError: false,
    );
  }

  static Future<void> markDartError({
    required Object error,
    StackTrace? stack,
  }) async {
    final msg = _clip(error.toString(), 240);
    final st = stack == null ? null : _clip(stack.toString(), 800);
    await _writeMarker(
      state: 'dart_error',
      sessionId: _currentSessionId(),
      keepError: true,
      errorType: error.runtimeType.toString(),
      errorMessage: msg,
      stack: st,
    );
  }

  /// 读取并清除上一会话标记；同时带上当前面包屑快照。
  static Future<PrevSessionExit?> consumePreviousForReport() async {
    final kv = _kv;
    if (kv == null) return null;
    Map<String, dynamic>? marker;
    try {
      final raw = kv.get<String>(StorageKeys.sessionExitMarker);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          marker = decoded.cast<String, dynamic>();
        }
      }
    } catch (_) {}

    final crumbs = UiBreadcrumb.snapshot();
    try {
      await kv.set(StorageKeys.sessionExitMarker, '');
      await kv.flush();
    } catch (_) {}

    if (marker == null || marker.isEmpty) {
      return null;
    }

    final state = (marker['state'] as String?)?.trim() ?? 'active';
    final atMs = (marker['atMs'] as num?)?.toInt() ?? 0;
    final sessionId = marker['sessionId'] as String?;
    final errorType = marker['errorType'] as String?;
    final errorMessage = marker['errorMessage'] as String?;
    final stack = marker['stack'] as String?;
    final exitKind = _exitKind(state);
    return PrevSessionExit(
      state: state,
      atMs: atMs,
      sessionId: sessionId,
      exitKind: exitKind,
      errorType: errorType,
      errorMessage: errorMessage,
      stack: stack,
      breadcrumbs: crumbs,
    );
  }

  static String _exitKind(String state) {
    if (state == 'dart_error') return 'dart_error';
    if (state == 'background' || state == 'detached') return 'graceful';
    return 'abnormal';
  }

  static String? _currentSessionId() {
    final kv = _kv;
    if (kv == null) return null;
    final id = kv.get<String>(StorageKeys.lineEventSessionId);
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static String? _currentState() {
    final kv = _kv;
    if (kv == null) return null;
    try {
      final raw = kv.get<String>(StorageKeys.sessionExitMarker);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded['state'] as String?;
    } catch (_) {}
    return null;
  }

  static Future<void> _writeMarker({
    required String state,
    String? sessionId,
    required bool keepError,
    String? errorType,
    String? errorMessage,
    String? stack,
  }) async {
    final kv = _kv;
    if (kv == null) return;
    try {
      String? et = errorType;
      String? em = errorMessage;
      String? st = stack;
      if (keepError && et == null) {
        final prev = _readMarkerMap();
        et = prev?['errorType'] as String?;
        em = prev?['errorMessage'] as String?;
        st = prev?['stack'] as String?;
      }
      final map = <String, dynamic>{
        'state': state,
        'atMs': DateTime.now().millisecondsSinceEpoch,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        if (et != null && et.isNotEmpty) 'errorType': et,
        if (em != null && em.isNotEmpty) 'errorMessage': em,
        if (st != null && st.isNotEmpty) 'stack': st,
      };
      await kv.set(StorageKeys.sessionExitMarker, jsonEncode(map));
      await kv.flush();
    } catch (e) {
      log.w('[SessionExit] write failed: $e');
    }
  }

  static Map<String, dynamic>? _readMarkerMap() {
    final kv = _kv;
    if (kv == null) return null;
    try {
      final raw = kv.get<String>(StorageKeys.sessionExitMarker);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {}
    return null;
  }

  static String _clip(String text, int max) {
    final cleaned =
        text.replaceAll(RegExp(r'accessToken=[^,\s]+'), 'accessToken=***');
    if (cleaned.length <= max) return cleaned;
    return cleaned.substring(0, max);
  }
}