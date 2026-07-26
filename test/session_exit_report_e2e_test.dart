import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vortek/core/config/app_constants.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/services/diagnostics/session_exit_tracker.dart';
import 'package:vortek/services/diagnostics/ui_breadcrumb.dart';
import 'package:vortek/services/line_event_queue.dart';

class _CapturingAdapter implements HttpClientAdapter {
  final receivedBatches = <List<dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final c in requestStream) {
        chunks.addAll(c);
      }
    }
    final body = utf8.decode(chunks);
    final json = jsonDecode(body) as Map<String, dynamic>;
    receivedBatches.add((json['events'] as List).toList());
    return ResponseBody.fromString(
      jsonEncode({'code': 200, 'message': 'ok', 'data': 1}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 模拟 AuthController._recordAppStart 的上报流程（不拉起完整 Riverpod 树）。
Future<void> _simulateStartupReport(LineEventQueue queue) async {
  final prev = await SessionExitTracker.consumePreviousForReport();
  final newSessionId = await queue.beginNewSession();
  await SessionExitTracker.markActive(sessionId: newSessionId);

  if (prev != null && prev.shouldReportSessionExit) {
    await queue.record(
      eventType: 'session_exit',
      triggerSource: 'startup',
      success: false,
      errorCategory: prev.errorCategory,
      errorMessage: prev.errorMessage ?? prev.exitKind,
      sessionIdOverride: prev.sessionId,
      extra: prev.toExtra(),
    );
  }

  await queue.record(
    eventType: 'app_start',
    triggerSource: 'bootstrap',
    success: true,
    extra: <String, dynamic>{
      if (prev != null) ...prev.toExtra(),
      if (prev == null) 'prevExit': 'none',
    },
  );
  UiBreadcrumb.clear();
  await queue.flush();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  late KvStore kv;
  late _CapturingAdapter adapter;
  late LineEventQueue queue;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'vortek',
      packageName: 'com.vortek.test',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('session_exit_e2e_');
    Hive.init(hiveDir.path);
    kv = await KvStore.open();
    UiBreadcrumb.bind(kv);
    SessionExitTracker.bind(kv);
    UiBreadcrumb.clear();
    await kv.set(StorageKeys.sessionExitMarker, '');
    adapter = _CapturingAdapter();
    queue = LineEventQueue(
      kv: kv,
      getLine: () => kDefaultLine,
      getBaseUrl: () => 'http://127.0.0.1',
      httpClientAdapter: adapter,
    );
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  List<Map<String, dynamic>> uploaded() => adapter.receivedBatches
      .expand((b) => b)
      .map((e) => (e as Map).cast<String, dynamic>())
      .toList();

  test('前台点相册后异常退出，下次启动上报 session_exit + breadcrumbs', () async {
    // ---- 会话 1：用户在前台点相册后进程没了 ----
    await kv.set(StorageKeys.lineEventSessionId, 'prev-session-1');
    await SessionExitTracker.markActive(sessionId: 'prev-session-1');
    UiBreadcrumb.add('chat_album');
    UiBreadcrumb.add('perm_request', detail: '相册');
    // 不 markBackground：模拟闪退/强杀，marker 停在 active

    // ---- 会话 2：冷启动上报 ----
    await _simulateStartupReport(queue);

    final events = uploaded();
    final exitEvents =
        events.where((e) => e['eventType'] == 'session_exit').toList();
    final starts = events.where((e) => e['eventType'] == 'app_start').toList();

    expect(exitEvents.length, 1);
    expect(starts.length, 1);

    final exit = exitEvents.single;
    expect(exit['success'], isFalse);
    expect(exit['errorCategory'], 'abnormal_exit');
    expect(exit['sessionId'], 'prev-session-1');
    expect(exit['triggerSource'], 'startup');

    final exitExtra =
        jsonDecode(exit['extraJson'] as String) as Map<String, dynamic>;
    expect(exitExtra['prevExit'], 'abnormal');
    expect(exitExtra['prevSessionId'], 'prev-session-1');
    final crumbs = (exitExtra['breadcrumbs'] as List).cast<Map>();
    expect(crumbs.map((e) => e['a']).toList(), ['chat_album', 'perm_request']);
    expect(crumbs.last['d'], '相册');

    final start = starts.single;
    expect(start['success'], isTrue);
    expect(start['sessionId'], isNot(equals('prev-session-1')));
    final startExtra =
        jsonDecode(start['extraJson'] as String) as Map<String, dynamic>;
    expect(startExtra['prevExit'], 'abnormal');
    expect(startExtra['breadcrumbs'], isNotEmpty);
  });

  test('正常退后台再启动：不上报 session_exit，app_start 记 graceful', () async {
    await SessionExitTracker.markActive(sessionId: 'sess-ok');
    UiBreadcrumb.add('chat_file');
    await SessionExitTracker.markBackground();

    await _simulateStartupReport(queue);

    final events = uploaded();
    expect(events.any((e) => e['eventType'] == 'session_exit'), isFalse);
    final start =
        events.singleWhere((e) => e['eventType'] == 'app_start');
    final extra =
        jsonDecode(start['extraJson'] as String) as Map<String, dynamic>;
    expect(extra['prevExit'], 'graceful');
    expect(extra['breadcrumbs'], isNotEmpty);
  });

  test('Dart 异常后即使又 paused，仍上报 dart_error', () async {
    await SessionExitTracker.markActive(sessionId: 'sess-err');
    UiBreadcrumb.add('rtc_call', detail: 'video');
    await SessionExitTracker.markDartError(
      error: Exception('widget build failed'),
      stack: StackTrace.current,
    );
    await SessionExitTracker.markBackground();

    await _simulateStartupReport(queue);

    final exit = uploaded().singleWhere((e) => e['eventType'] == 'session_exit');
    expect(exit['errorCategory'], 'dart_error');
    final extra =
        jsonDecode(exit['extraJson'] as String) as Map<String, dynamic>;
    expect(extra['prevExit'], 'dart_error');
    expect(extra['errorMessage'], contains('widget build failed'));
    expect(extra['stack'], isNotEmpty);
    final crumbs = (extra['breadcrumbs'] as List).cast<Map>();
    expect(crumbs.last['a'], 'rtc_call');
  });

  test('首次安装无标记：只有 app_start prevExit=none', () async {
    await _simulateStartupReport(queue);
    final events = uploaded();
    expect(events.any((e) => e['eventType'] == 'session_exit'), isFalse);
    final start =
        events.singleWhere((e) => e['eventType'] == 'app_start');
    final extra =
        jsonDecode(start['extraJson'] as String) as Map<String, dynamic>;
    expect(extra['prevExit'], 'none');
  });
}