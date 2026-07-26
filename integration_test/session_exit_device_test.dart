import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vortek/core/config/app_constants.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/services/diagnostics/session_exit_tracker.dart';
import 'package:vortek/services/diagnostics/ui_breadcrumb.dart';
import 'package:vortek/services/line_event_queue.dart';

/// 真机：在真实 Android 存储上跑异常退出上报链路。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late KvStore kv;
  late LineEventQueue queue;

  setUpAll(() async {
    await Hive.initFlutter();
    kv = await KvStore.open();
    UiBreadcrumb.bind(kv);
    SessionExitTracker.bind(kv);
    PackageInfo.setMockInitialValues(
      appName: 'vortek',
      packageName: 'com.cyberis.vortek',
      version: '1.0.6',
      buildNumber: '7',
      buildSignature: '',
    );
    queue = LineEventQueue(
      kv: kv,
      getLine: () => kDefaultLine,
      getBaseUrl: () => 'http://127.0.0.1:27418',
    );
  });

  testWidgets('device: foreground crash path reports session_exit with crumbs',
      (tester) async {
    UiBreadcrumb.clear();
    await kv.set(StorageKeys.sessionExitMarker, '');
    await kv.set(StorageKeys.lineEventSessionId, 'device-prev-sess');
    await kv.set(StorageKeys.lineEventQueue, '[]');

    await SessionExitTracker.markActive(sessionId: 'device-prev-sess');
    UiBreadcrumb.add('chat_album');
    UiBreadcrumb.add('perm_request', detail: '相册');
    // 不 markBackground：等同前台被杀

    final prev = await SessionExitTracker.consumePreviousForReport();
    expect(prev, isNotNull);
    expect(prev!.exitKind, 'abnormal');

    final newId = await queue.beginNewSession();
    await SessionExitTracker.markActive(sessionId: newId);

    await queue.record(
      eventType: 'session_exit',
      triggerSource: 'startup',
      success: false,
      errorCategory: prev.errorCategory,
      errorMessage: prev.errorMessage ?? prev.exitKind,
      sessionIdOverride: prev.sessionId,
      extra: prev.toExtra(),
    );
    await queue.record(
      eventType: 'app_start',
      triggerSource: 'bootstrap',
      success: true,
      extra: prev.toExtra(),
    );

    final raw = kv.get<String>(StorageKeys.lineEventQueue);
    expect(raw, isNotNull);
    final list = (jsonDecode(raw!) as List).cast<Map>();
    final exit = list.firstWhere((e) => e['eventType'] == 'session_exit');
    final extra =
        jsonDecode(exit['extraJson'] as String) as Map<String, dynamic>;
    expect(extra['prevExit'], 'abnormal');
    expect(
      (extra['breadcrumbs'] as List).map((e) => (e as Map)['a']).toList(),
      ['chat_album', 'perm_request'],
    );
  });
}