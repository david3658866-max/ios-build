import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:vortek/core/config/app_constants.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/services/line_event_queue.dart';

/// 真连生产上报 connected（无需登录：/line/event/report 白名单）。
/// 验证：flush 成功后本地队列清空；打印 marker 供服务端查库。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'vortek',
      packageName: 'com.vortek.test',
      version: '9.9.9-ws-live',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('live: connected 上报成功且队列清空', () async {
    final marker = 'ws-live-${const Uuid().v4()}';
    final hiveDir = await Directory.systemTemp.createTemp('ws_live_');
    addTearDown(() async {
      if (hiveDir.existsSync()) {
        await hiveDir.delete(recursive: true);
      }
    });
    Hive.init(hiveDir.path);
    final kv = await KvStore.open();
    addTearDown(() async {
      await Hive.close();
    });
    await kv.set(StorageKeys.lineEventInstallId, marker);

    final line = kBuiltinProdLines.first;
    final queue = LineEventQueue(
      kv: kv,
      getLine: () => line,
      getBaseUrl: () => line.baseUrl,
      httpClientAdapter: IOHttpClientAdapter(
        createHttpClient: () => HttpClient(),
      ),
    );

    await queue.record(
      eventType: 'ws_state',
      triggerSource: 'ws_live_test',
      success: true,
      wsStatus: 'connected',
      extra: {'marker': marker, 'test': 'ws_connected_live_report'},
    );
    await queue.flush();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await queue.flush();

    final remainRaw = kv.get<String>(StorageKeys.lineEventQueue) ?? '[]';
    final remain = remainRaw.isEmpty
        ? <Map<String, dynamic>>[]
        : (jsonDecode(remainRaw) as List)
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
    final stillHasConnected = remain.any(
      (e) => e['eventType'] == 'ws_state' && e['wsStatus'] == 'connected',
    );
    expect(
      stillHasConnected,
      isFalse,
      reason: 'connected 不应还趴在本地队列 marker=$marker remain=$remainRaw',
    );

    // ignore: avoid_print
    print('WS_LIVE_MARKER=$marker host=${line.host}');
  }, timeout: const Timeout(Duration(minutes: 2)));
}
