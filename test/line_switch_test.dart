import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';
import 'package:vortek/core/line/line_probe_outcome.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/core/utils/line_switch_util.dart';
import 'package:vortek/core/ws/ws_event.dart';
import 'package:vortek/core/ws/ws_manager.dart';
import 'package:vortek/models/login_info.dart';
import 'package:vortek/stores/config_store.dart';

class _FakeLineManager extends LineManager {
  _FakeLineManager(this._available);

  final bool _available;

  @override
  Future<bool> isAvailable(
    LineConfig line, {
    Duration timeout = const Duration(seconds: 8),
  }) async =>
      _available;

  @override
  Future<LineProbeOutcome> probeDetailed(
    LineConfig line, {
    Duration timeout = const Duration(seconds: 8),
    int maxAttempts = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    if (_available) {
      return const LineProbeOutcome(latencyMs: 12, httpStatus: 200);
    }
    return const LineProbeOutcome(errorCategory: 'timeout');
  }
}

class _RecordingWsManager extends WsManager {
  int reconnectCount = 0;
  String? lastWsUrl;

  @override
  void forceReconnect({
    required String wsUrl,
    required String token,
    required String devId,
  }) {
    reconnectCount++;
    lastWsUrl = wsUrl;
  }
}

void main() {
  group('LineSwitchUtil', () {
    test('chipStatus 未登录看 lineStatus', () {
      expect(
        LineSwitchUtil.chipStatus(
          isAuthenticated: false,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.disconnected,
        ),
        WsStatus.connected,
      );
    });

    test('chipStatus 对齐 uniapp：始终看 lineStatus', () {
      expect(
        LineSwitchUtil.chipStatus(
          isAuthenticated: true,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.disconnected,
        ),
        WsStatus.connected,
      );
    });

    test('shouldReconnectSameLine 仅已登录且 WS 失败', () {
      expect(
        LineSwitchUtil.shouldReconnectSameLine(
          isAuthenticated: true,
          chipStatus: WsStatus.disconnected,
        ),
        isTrue,
      );
      expect(
        LineSwitchUtil.shouldReconnectSameLine(
          isAuthenticated: false,
          chipStatus: WsStatus.disconnected,
        ),
        isFalse,
      );
    });

    test('autoSwitchToast / allLinesFailedToast / switchFailedToast 文案', () {
      expect(LineSwitchUtil.autoSwitchToast('备用线路2'), '已切换至备用线路2');
      expect(
        LineSwitchUtil.allLinesFailedToast,
        '网络异常，请稍后重试或手动切换线路',
      );
      expect(LineSwitchUtil.switchFailedToast, '切换失败，该线路暂不可用');
      expect(LineSwitchUtil.retryProbeToast, '正在重新检测线路…');
      expect(LineSwitchUtil.retryProbeOkToast, '线路检测完成');
      expect(LineSwitchUtil.retryProbeAllFailedToast, '仍无法连接，请检查网络后重试');
      expect(
        LineSwitchUtil.autoFailoverCountdown('主线路', 3),
        '该线路不可用，3 秒后切换到主线路',
      );
      expect(LineSwitchUtil.autoFailoverChipSeconds(3), '3s');
      expect(LineSwitchUtil.autoFailoverCancelLabel, '取消');
      expect(
        LineSwitchUtil.probeStatusLabel(null),
        '未检测',
      );
      expect(
        LineSwitchUtil.probeStatusLabel(
          const LineProbeCacheEntry(ok: true, latencyMs: 88, checkedAtMs: 1),
        ),
        '通 88ms',
      );
      expect(
        LineSwitchUtil.probeStatusLabel(
          const LineProbeCacheEntry(ok: false, checkedAtMs: 1),
        ),
        '不通',
      );
    });

    test('nextHealthyCandidate 排除已试线路并按顺序取下一条', () {
      final lines = kLines;
      expect(
        LineSwitchUtil.nextHealthyCandidate(
          healthySortedByLatency: lines,
          triedIds: {lines.first.id},
        )?.id,
        lines[1].id,
      );
      expect(
        LineSwitchUtil.nextHealthyCandidate(
          healthySortedByLatency: lines,
          triedIds: lines.map((e) => e.id).toSet(),
        ),
        isNull,
      );
    });

    test('shouldSkipAuthPreProbe 已连通且探活新鲜才跳过', () {
      const fresh = LineProbeCacheEntry(
        ok: true,
        latencyMs: 80,
        checkedAtMs: 1_000_000,
      );
      expect(
        LineSwitchUtil.shouldSkipAuthPreProbe(
          lineStatus: WsStatus.connected,
          currentLineProbe: fresh,
          nowMs: 1_000_000 + 30_000,
        ),
        isTrue,
      );
      expect(
        LineSwitchUtil.shouldSkipAuthPreProbe(
          lineStatus: WsStatus.disconnected,
          currentLineProbe: fresh,
          nowMs: 1_000_000 + 30_000,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldSkipAuthPreProbe(
          lineStatus: WsStatus.connected,
          currentLineProbe: fresh,
          nowMs: 1_000_000 + const Duration(minutes: 3).inMilliseconds,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldSkipAuthPreProbe(
          lineStatus: WsStatus.connected,
          currentLineProbe: null,
          nowMs: 1_000_000,
        ),
        isFalse,
      );
    });
  });

  group('LineNotifier 切换线路', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late Directory dir;
    late KvStore kv;
    late AppDatabase db;
    late _RecordingWsManager ws;
    late ProviderContainer container;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('line_switch_');
      Hive.init(dir.path);
      kv = await KvStore.open();
      db = AppDatabase.forTesting(NativeDatabase.memory());
      ws = _RecordingWsManager();
      await kv.setLoginInfo(
        const LoginInfo(accessToken: 't', refreshToken: 'r', userId: 1),
      );
      container = ProviderContainer(
        overrides: [
          kvStoreProvider.overrideWithValue(kv),
          appDatabaseProvider.overrideWithValue(db),
          wsManagerProvider.overrideWithValue(ws),
          lineManagerProvider.overrideWithValue(_FakeLineManager(true)),
        ],
      );
      container.read(configStoreProvider.notifier).setWsStatus(
            WsStatus.disconnected,
          );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('切换不同线路 forceReconnect 到新 wsUrl', () async {
      final outcome =
          await container.read(lineProvider.notifier).switchTo('line3');
      expect(outcome.success, isTrue);
      expect(outcome.switched, isTrue);
      expect(container.read(lineProvider).id, 'line3');
      expect(ws.reconnectCount, 1);
      expect(ws.lastWsUrl, kLines[2].wsUrl);
    });

    test('同线路且探活失败时触发 onLineSwitched', () async {
      await container.read(lineProvider.notifier).switchTo('line1');
      ws.reconnectCount = 0;
      container.read(configStoreProvider.notifier).setLineStatus(
            WsStatus.disconnected,
          );

      final outcome =
          await container.read(lineProvider.notifier).switchTo('line1');
      expect(outcome.success, isTrue);
      expect(outcome.switched, isFalse);
      expect(ws.reconnectCount, 1);
    });

    test('bestHealthyCandidate 排除失败线并按延迟选最快', () {
      container.read(lineProbeCacheProvider.notifier).upsertAll({
        kLines[0].id: const LineProbeCacheEntry(
          ok: true,
          latencyMs: 200,
          checkedAtMs: 1,
        ),
        kLines[1].id: const LineProbeCacheEntry(
          ok: true,
          latencyMs: 50,
          checkedAtMs: 1,
        ),
        kLines[2].id: const LineProbeCacheEntry(
          ok: false,
          checkedAtMs: 1,
        ),
      });
      final pick = container.read(lineProvider.notifier).bestHealthyCandidate(
            excludeId: kLines[0].id,
          );
      expect(pick?.id, kLines[1].id);
    });
  });

}
