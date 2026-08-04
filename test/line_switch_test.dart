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

    test('orderLinesForPanel: 当前线→已通→未检测→不通', () {
      LineConfig line(String id) => LineConfig(
            id: id,
            name: '线路$id',
            label: id,
            host: '$id.test',
            baseUrl: 'https://$id.test/api',
            wsUrl: 'wss://$id.test/im',
            scanUrl: 'https://h5.test',
          );
      final lines = [
        line('1'),
        line('2'),
        line('3'),
        line('4'),
        line('5'),
      ];
      final cache = <String, LineProbeCacheEntry?>{
        '1': const LineProbeCacheEntry(ok: false, checkedAtMs: 1),
        '2': const LineProbeCacheEntry(
          ok: true,
          checkedAtMs: 1,
          latencyMs: 80,
        ),
        '3': null,
        '4': const LineProbeCacheEntry(
          ok: true,
          checkedAtMs: 1,
          latencyMs: 40,
        ),
        '5': const LineProbeCacheEntry(ok: false, checkedAtMs: 1),
      };
      final ordered = LineSwitchUtil.orderLinesForPanel(
        lines: lines,
        currentId: '4',
        probeCache: cache,
      );
      expect(ordered.map((e) => e.id).toList(), ['4', '2', '3', '1', '5']);
    });

    test('chipStatus 已登录且探活通则跟真实 WS', () {
      expect(
        LineSwitchUtil.chipStatus(
          isAuthenticated: true,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.disconnected,
        ),
        WsStatus.disconnected,
      );
      expect(
        LineSwitchUtil.chipStatus(
          isAuthenticated: true,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.connected,
        ),
        WsStatus.connected,
      );
      expect(
        LineSwitchUtil.chipStatus(
          isAuthenticated: true,
          lineStatus: WsStatus.disconnected,
          wsStatus: WsStatus.connected,
        ),
        WsStatus.disconnected,
      );
    });

    test('isMessageChannelDegraded 仅已登录+HTTP通+WS断', () {
      expect(
        LineSwitchUtil.isMessageChannelDegraded(
          isAuthenticated: true,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.disconnected,
        ),
        isTrue,
      );
      expect(
        LineSwitchUtil.isMessageChannelDegraded(
          isAuthenticated: false,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.disconnected,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.isMessageChannelDegraded(
          isAuthenticated: true,
          lineStatus: WsStatus.disconnected,
          wsStatus: WsStatus.disconnected,
        ),
        isFalse,
      );
      expect(LineSwitchUtil.messageChannelDegradedLabel, '消息异常');
    });

    test('shouldShowSwitcherEntry 健康隐藏；未登录连接中隐藏，失败才展示', () {
      expect(
        LineSwitchUtil.shouldShowSwitcherEntry(
          isAuthenticated: false,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.disconnected,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldShowSwitcherEntry(
          isAuthenticated: true,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.connected,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldShowSwitcherEntry(
          isAuthenticated: false,
          lineStatus: WsStatus.disconnected,
          wsStatus: WsStatus.disconnected,
        ),
        isTrue,
      );
      // 登录页探活中：不显示「连接中」芯片。
      expect(
        LineSwitchUtil.shouldShowSwitcherEntry(
          isAuthenticated: false,
          lineStatus: WsStatus.connecting,
          wsStatus: WsStatus.disconnected,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldShowSwitcherEntry(
          isAuthenticated: true,
          lineStatus: WsStatus.connected,
          wsStatus: WsStatus.disconnected,
        ),
        isTrue,
      );
      // 已登录探活中仍展示，便于手切。
      expect(
        LineSwitchUtil.shouldShowSwitcherEntry(
          isAuthenticated: true,
          lineStatus: WsStatus.connecting,
          wsStatus: WsStatus.disconnected,
        ),
        isTrue,
      );
    });

    test('shouldTriggerWsDisconnectFailover 连续 2 次且未冷却', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1_000_000);
      expect(
        LineSwitchUtil.shouldTriggerWsDisconnectFailover(
          consecutiveDisconnectsWithoutConnect: 1,
          deviceOffline: false,
          cooldownUntil: null,
          now: now,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldTriggerWsDisconnectFailover(
          consecutiveDisconnectsWithoutConnect: 2,
          deviceOffline: false,
          cooldownUntil: null,
          now: now,
        ),
        isTrue,
      );
      expect(
        LineSwitchUtil.shouldTriggerWsDisconnectFailover(
          consecutiveDisconnectsWithoutConnect: 2,
          deviceOffline: true,
          cooldownUntil: null,
          now: now,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldTriggerWsDisconnectFailover(
          consecutiveDisconnectsWithoutConnect: 2,
          deviceOffline: false,
          cooldownUntil: now.add(const Duration(seconds: 30)),
          now: now,
        ),
        isFalse,
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

    test('shouldSkipApiConnectionFailover 无网必跳过', () {
      expect(
        LineSwitchUtil.shouldSkipApiConnectionFailover(
          deviceOffline: true,
          hasTriedInWave: false,
          cooldownUntil: null,
        ),
        isTrue,
      );
      expect(
        LineSwitchUtil.shouldSkipApiConnectionFailover(
          deviceOffline: true,
          hasTriedInWave: true,
          cooldownUntil: null,
        ),
        isTrue,
      );
    });

    test('shouldSkipApiConnectionFailover 冷却仅拦新波', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1_000_000);
      final until = now.add(const Duration(seconds: 10));
      expect(
        LineSwitchUtil.shouldSkipApiConnectionFailover(
          deviceOffline: false,
          hasTriedInWave: false,
          cooldownUntil: until,
          now: now,
        ),
        isTrue,
      );
      expect(
        LineSwitchUtil.shouldSkipApiConnectionFailover(
          deviceOffline: false,
          hasTriedInWave: true,
          cooldownUntil: until,
          now: now,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.shouldSkipApiConnectionFailover(
          deviceOffline: false,
          hasTriedInWave: false,
          cooldownUntil: until,
          now: until.add(const Duration(seconds: 1)),
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.apiConnectionFailoverCooldown,
        const Duration(seconds: 30),
      );
    });

    test('isProbeFreshForApiFailover 过期或不通不可用', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1_000_000);
      expect(
        LineSwitchUtil.isProbeFreshForApiFailover(
          LineProbeCacheEntry(
            ok: true,
            latencyMs: 40,
            checkedAtMs: now.millisecondsSinceEpoch - 60_000,
          ),
          now: now,
        ),
        isTrue,
      );
      expect(
        LineSwitchUtil.isProbeFreshForApiFailover(
          LineProbeCacheEntry(
            ok: true,
            latencyMs: 40,
            checkedAtMs: now.millisecondsSinceEpoch -
                const Duration(minutes: 6).inMilliseconds,
          ),
          now: now,
        ),
        isFalse,
      );
      expect(
        LineSwitchUtil.isProbeFreshForApiFailover(
          LineProbeCacheEntry(
            ok: false,
            checkedAtMs: now.millisecondsSinceEpoch,
          ),
          now: now,
        ),
        isFalse,
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
      // upsertAll 会 unawaited 写 Hive；先让挂起的 persist 跑完再 close。
      await Future<void>.delayed(const Duration(milliseconds: 50));
      container.dispose();
      await db.close();
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('切换不同线路 forceReconnect 到新 wsUrl', () async {
      final target = kBuiltinProdLines.firstWhere((e) => e.id == 'line458');
      final outcome =
          await container.read(lineProvider.notifier).switchTo(target.id);
      expect(outcome.success, isTrue);
      expect(outcome.switched, isTrue);
      expect(container.read(lineProvider).id, target.id);
      expect(ws.reconnectCount, 1);
      expect(ws.lastWsUrl, target.wsUrl);
    });

    test('同线路且探活失败时触发 onLineSwitched', () async {
      await container.read(lineProvider.notifier).switchTo('line448');
      ws.reconnectCount = 0;
      container.read(configStoreProvider.notifier).setLineStatus(
            WsStatus.disconnected,
          );

      final outcome =
          await container.read(lineProvider.notifier).switchTo('line448');
      expect(outcome.success, isTrue);
      expect(outcome.switched, isFalse);
      expect(ws.reconnectCount, 1);
    });

    test('bestHealthyCandidate 排除失败线并按延迟选最快', () {
      container.read(lineProbeCacheProvider.notifier).upsertAll({
        'line448': const LineProbeCacheEntry(
          ok: true,
          latencyMs: 200,
          checkedAtMs: 1,
        ),
        'line458': const LineProbeCacheEntry(
          ok: true,
          latencyMs: 50,
          checkedAtMs: 1,
        ),
        'line49': const LineProbeCacheEntry(
          ok: false,
          checkedAtMs: 1,
        ),
      });
      final pick = container.read(lineProvider.notifier).bestHealthyCandidate(
            excludeId: 'line448',
          );
      expect(pick?.id, 'line458');
    });

    test('fallbackOnConnectionError 有探通候选时 adopt 并重连 WS', () async {
      // Debug 默认本地线；用生产线 id 模拟坏线。
      await container.read(lineProvider.notifier).switchTo('line448');
      ws.reconnectCount = 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      container.read(lineProbeCacheProvider.notifier).upsertAll({
        'line448': LineProbeCacheEntry(
          ok: false,
          checkedAtMs: nowMs,
        ),
        'line458': LineProbeCacheEntry(
          ok: true,
          latencyMs: 40,
          checkedAtMs: nowMs,
        ),
      });

      final switched =
          await container.read(lineProvider.notifier).fallbackOnConnectionError();
      expect(switched, isTrue);
      expect(container.read(lineProvider).id, 'line458');
      expect(ws.reconnectCount, 1);
    });

    test('fallbackOnConnectionError 过期探活不 adopt', () async {
      await container.read(lineProvider.notifier).switchTo('line448');
      final staleMs = DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch;
      container.read(lineProbeCacheProvider.notifier).upsertAll({
        'line458': LineProbeCacheEntry(
          ok: true,
          latencyMs: 40,
          checkedAtMs: staleMs,
        ),
      });
      final switched =
          await container.read(lineProvider.notifier).fallbackOnConnectionError();
      expect(switched, isFalse);
      expect(container.read(lineProvider).id, 'line448');
    });

    test('fallbackOnConnectionError 无候选时返回 false', () async {
      await container.read(lineProvider.notifier).switchTo('line448');
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      container.read(lineProbeCacheProvider.notifier).upsertAll({
        'line448': LineProbeCacheEntry(ok: false, checkedAtMs: nowMs),
        'line458': LineProbeCacheEntry(ok: false, checkedAtMs: nowMs),
      });
      final switched =
          await container.read(lineProvider.notifier).fallbackOnConnectionError();
      expect(switched, isFalse);
      expect(container.read(lineProvider).id, 'line448');
    });
  });

}
