import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vortek/core/config/app_constants.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/services/diagnostics/session_exit_tracker.dart';
import 'package:vortek/services/diagnostics/ui_breadcrumb.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  late KvStore kv;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('session_exit_');
    Hive.init(hiveDir.path);
    kv = await KvStore.open();
    UiBreadcrumb.bind(kv);
    SessionExitTracker.bind(kv);
    UiBreadcrumb.clear();
    await kv.set(StorageKeys.sessionExitMarker, '');
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('active then consume => abnormal session_exit', () async {
    await kv.set(StorageKeys.lineEventSessionId, 'sess-a');
    await SessionExitTracker.markActive(sessionId: 'sess-a');
    UiBreadcrumb.add('chat_album');
    final prev = await SessionExitTracker.consumePreviousForReport();
    expect(prev, isNotNull);
    expect(prev!.exitKind, 'abnormal');
    expect(prev.shouldReportSessionExit, isTrue);
    expect(prev.sessionId, 'sess-a');
    expect(prev.breadcrumbs, isNotEmpty);
    expect(prev.breadcrumbs.first['a'], 'chat_album');
    expect(prev.toExtra()['prevExit'], 'abnormal');
  });

  test('paused/background then consume => graceful, no session_exit', () async {
    await SessionExitTracker.markActive(sessionId: 'sess-b');
    await SessionExitTracker.markBackground();
    final prev = await SessionExitTracker.consumePreviousForReport();
    expect(prev, isNotNull);
    expect(prev!.exitKind, 'graceful');
    expect(prev.shouldReportSessionExit, isFalse);
  });

  test('dart_error is sticky against later background', () async {
    await SessionExitTracker.markActive(sessionId: 'sess-c');
    await SessionExitTracker.markDartError(
      error: StateError('boom'),
      stack: StackTrace.current,
    );
    await SessionExitTracker.markBackground();
    final prev = await SessionExitTracker.consumePreviousForReport();
    expect(prev, isNotNull);
    expect(prev!.exitKind, 'dart_error');
    expect(prev.errorCategory, 'dart_error');
    expect(prev.errorMessage, contains('boom'));
    expect(prev.shouldReportSessionExit, isTrue);
  });

  test('breadcrumb ring keeps last 30', () {
    for (var i = 0; i < 40; i++) {
      UiBreadcrumb.add('act_$i');
    }
    final snap = UiBreadcrumb.snapshot();
    expect(snap.length, 30);
    expect(snap.first['a'], 'act_10');
    expect(snap.last['a'], 'act_39');
  });

  test('no marker => null prev (avoid false abnormal on upgrade)', () async {
    final prev = await SessionExitTracker.consumePreviousForReport();
    expect(prev, isNull);
  });
}