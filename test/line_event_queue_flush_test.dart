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
import 'package:vortek/services/line_event_queue.dart';

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.delayMs = 0});

  final int delayMs;
  final receivedBatches = <List<dynamic>>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
    }
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  late KvStore kv;

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
    hiveDir = await Directory.systemTemp.createTemp('line_event_queue_');
    Hive.init(hiveDir.path);
    kv = await KvStore.open();
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      await hiveDir.delete(recursive: true);
    }
  });

  test('队列满时优先保留 ws connected，而不是挤掉它', () async {
    final q = LineEventQueue(
      kv: kv,
      getLine: () => kDefaultLine,
      getBaseUrl: () => 'http://127.0.0.1',
    );
    for (var i = 0; i < 1000; i++) {
      await q.record(
        eventType: 'line_probe_result',
        success: true,
        latencyMs: 10,
      );
    }
    await q.record(
      eventType: 'ws_state',
      success: true,
      wsStatus: 'connected',
    );
    for (var i = 0; i < 50; i++) {
      await q.record(
        eventType: 'line_probe_result',
        success: false,
        errorCategory: 'dns',
      );
    }

    final raw = kv.get<String>(StorageKeys.lineEventQueue);
    expect(raw, isNotNull);
    final list = (jsonDecode(raw!) as List).cast<Map>();
    final hasConnected = list.any(
      (e) =>
          e['eventType'] == 'ws_state' &&
          e['wsStatus'] == 'connected' &&
          e['success'] == true,
    );
    expect(hasConnected, isTrue);
  });

  test('flush 进行中再次 flush，仍会带上后写入的 connected', () async {
    final adapter = _CapturingAdapter(delayMs: 400);
    final q = LineEventQueue(
      kv: kv,
      getLine: () => kDefaultLine,
      getBaseUrl: () => 'http://127.0.0.1',
      httpClientAdapter: adapter,
    );

    await q.record(
      eventType: 'line_probe_result',
      success: true,
      latencyMs: 8,
    );

    final first = q.flush();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await q.record(
      eventType: 'ws_state',
      success: true,
      wsStatus: 'connected',
    );
    final second = q.flush();
    await Future.wait([first, second]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await q.flush();

    final allEvents = adapter.receivedBatches.expand((b) => b).toList();
    final hasConnected = allEvents.any((e) {
      final m = (e as Map).cast<String, dynamic>();
      return m['eventType'] == 'ws_state' && m['wsStatus'] == 'connected';
    });
    expect(adapter.receivedBatches, isNotEmpty);
    expect(hasConnected, isTrue);
  });
}
