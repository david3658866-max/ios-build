import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';
import 'package:vortek/core/line/line_probe_outcome.dart';
import 'package:vortek/core/utils/line_switch_util.dart';

LineConfig _line(String id) => LineConfig(
      id: id,
      name: id,
      label: id,
      host: '$id.test',
      baseUrl: 'https://$id.test/api',
      wsUrl: 'wss://$id.test/im',
      scanUrl: 'https://h5.test',
    );

void main() {
  final now = DateTime(2026, 7, 31, 12);
  final nowMs = now.millisecondsSinceEpoch;

  test('orderLinesForProbe: healthy > unknown > failed', () {
    final lines = [
      _line('a'),
      _line('b'),
      _line('c'),
      _line('d'),
      _line('e'),
    ];
    final prior = <String, LineProbeCacheEntry?>{
      'a': LineProbeCacheEntry(ok: false, checkedAtMs: nowMs),
      'b': LineProbeCacheEntry(ok: true, checkedAtMs: nowMs, latencyMs: 10),
      'c': null,
      'd': LineProbeCacheEntry(ok: true, checkedAtMs: nowMs, latencyMs: 20),
      'e': LineProbeCacheEntry(ok: false, checkedAtMs: nowMs),
    };
    final ordered = orderLinesForProbe(lines, prior, Random(1), now: now);
    final ids = ordered.map((e) => e.id).toList();
    expect(ids.take(2).toSet(), {'b', 'd'});
    expect(ids[2], 'c');
    expect(ids.skip(3).toSet(), {'a', 'e'});

    final other = orderLinesForProbe(lines, prior, Random(2), now: now);
    expect(other.take(2).map((e) => e.id).toSet(), {'b', 'd'});
  });

  test('failed lines demoted to end of order', () {
    final lines = [_line('ok1'), _line('bad1'), _line('new1')];
    final prior = <String, LineProbeCacheEntry?>{
      'ok1': LineProbeCacheEntry(ok: true, checkedAtMs: nowMs, latencyMs: 5),
      'bad1': LineProbeCacheEntry(ok: false, checkedAtMs: nowMs),
    };
    final ids = orderLinesForProbe(lines, prior, Random(0), now: now)
        .map((e) => e.id)
        .toList();
    expect(ids.first, 'ok1');
    expect(ids[1], 'new1');
    expect(ids.last, 'bad1');
  });

  test('stale failure becomes unknown; stale healthy expires', () {
    final lines = [_line('staleOk'), _line('staleBad'), _line('freshBad')];
    final prior = <String, LineProbeCacheEntry?>{
      'staleOk': LineProbeCacheEntry(
        ok: true,
        checkedAtMs: nowMs - const Duration(hours: 2).inMilliseconds,
        latencyMs: 8,
      ),
      'staleBad': LineProbeCacheEntry(
        ok: false,
        checkedAtMs: nowMs - const Duration(hours: 1).inMilliseconds,
      ),
      'freshBad': LineProbeCacheEntry(ok: false, checkedAtMs: nowMs),
    };
    final ids = orderLinesForProbe(lines, prior, Random(0), now: now)
        .map((e) => e.id)
        .toList();
    // 过期通/过期失败都当未知，排在新鲜失败之前。
    expect(ids.last, 'freshBad');
    expect(ids.take(2).toSet(), {'staleOk', 'staleBad'});
  });

  test('runBatchedProbe stops after 5 healthy with batch size 5', () async {
    final lines = List.generate(12, (i) => _line('L${i + 1}'));
    var calls = 0;
    final results = await runBatchedProbe(
      lines: lines,
      priorHealth: const {},
      random: Random(7),
      batchSize: 5,
      stopWhenHealthy: 5,
      probe: (line) async {
        calls++;
        return LineProbeOutcome(latencyMs: calls * 10, httpStatus: 200);
      },
    );
    expect(calls, 5);
    expect(results.length, 5);
    expect(results.where((r) => r.outcome.ok).length, 5);
  });

  test('runBatchedProbe prefers prior healthy ids first', () async {
    final lines = List.generate(9, (i) => _line('L${i + 1}'));
    final freshMs = DateTime.now().millisecondsSinceEpoch;
    final prior = <String, LineProbeCacheEntry?>{
      for (final id in ['L7', 'L8', 'L9'])
        id: LineProbeCacheEntry(ok: true, checkedAtMs: freshMs, latencyMs: 1),
      for (final id in ['L1', 'L2', 'L3'])
        id: LineProbeCacheEntry(ok: false, checkedAtMs: freshMs),
    };
    final hit = <String>[];
    await runBatchedProbe(
      lines: lines,
      priorHealth: prior,
      random: Random(1),
      batchSize: 5,
      stopWhenHealthy: 3,
      probe: (line) async {
        hit.add(line.id);
        return const LineProbeOutcome(latencyMs: 5, httpStatus: 200);
      },
    );
    expect(hit.length, 5);
    expect(hit.take(3).toSet(), {'L7', 'L8', 'L9'});
  });

  test('batch constants match plan', () {
    expect(LineManager.batchProbeSize, 5);
    expect(LineManager.batchProbeStopWhenHealthy, 5);
    expect(LineManager.authBatchProbeStopWhenHealthy, 1);
    expect(LineManager.authBatchProbeMaxAttempts, 1);
    expect(LineManager.authBatchProbeSize, 6);
    expect(LineManager.authBatchProbeTimeout.inMilliseconds, 1500);
    expect(LineManager.authPreferredMaxBatches, 2);
    expect(LineManager.authFallbackMaxBatches, 3);
  });

  test('lineHostFamily extracts registrable suffix', () {
    expect(lineHostFamily('zenty.dvdda.com'), 'dvdda.com');
    expect(lineHostFamily('zenty.bgznp.com'), 'bgznp.com');
    expect(lineHostFamily('Castle.Scnjrm.COM'), 'scnjrm.com');
  });

  test('diversifyByHostFamily round-robins domain families', () {
    LineConfig familyLine(String id, String host) => LineConfig(
          id: id,
          name: id,
          label: id,
          host: host,
          baseUrl: 'https://$host/api',
          wsUrl: 'wss://$host/im',
          scanUrl: 'https://h5.test',
        );
    final lines = [
      familyLine('a1', 'a.dvdda.com'),
      familyLine('a2', 'b.dvdda.com'),
      familyLine('b1', 'a.bgznp.com'),
      familyLine('b2', 'b.bgznp.com'),
      familyLine('c1', 'a.scnjrm.com'),
    ];
    final ordered = diversifyByHostFamily(lines, Random(1));
    expect(ordered.length, 5);
    // 前 3 条应分属三个域名族，避免首批全撞同一族。
    final firstFamilies =
        ordered.take(3).map((e) => lineHostFamily(e.host)).toSet();
    expect(firstFamilies.length, 3);
  });

  test('runBatchedProbe auth mode stops after 1 healthy', () async {
    final lines = List.generate(12, (i) => _line('L${i + 1}'));
    var calls = 0;
    final results = await runBatchedProbe(
      lines: lines,
      priorHealth: const {},
      random: Random(3),
      batchSize: LineManager.authBatchProbeSize,
      stopWhenHealthy: LineManager.authBatchProbeStopWhenHealthy,
      probe: (line) async {
        calls++;
        // 仅第 2 条通，模拟首批部分失败。
        if (calls == 2) {
          return const LineProbeOutcome(latencyMs: 40, httpStatus: 200);
        }
        return const LineProbeOutcome(errorCategory: 'dns');
      },
    );
    expect(calls, LineManager.authBatchProbeSize);
    expect(results.where((r) => r.outcome.ok).length, 1);
  });

  test('orderLinesForProbe: preferred unknown before other unknown', () {
    expect(kPreferredBuiltinLineIds, isNotEmpty);
    final preferredId = kPreferredBuiltinLineIds.first;
    final lines = [
      _line('fallbackA'),
      _line(preferredId),
      _line('fallbackB'),
    ];
    final ids = orderLinesForProbe(lines, const {}, Random(1))
        .map((e) => e.id)
        .toList();
    expect(ids.first, preferredId);
    expect(ids.skip(1).toSet(), {'fallbackA', 'fallbackB'});
  });

  test('preferred builtin pool matches enabled seed count', () {
    expect(kPreferredBuiltinLineIds.length, 40);
    expect(isPreferredBuiltinLine('line46'), isTrue);
    expect(isPreferredBuiltinLine('line45'), isFalse);
    expect(isPreferredBuiltinLine('line447'), isFalse);
  });

  test('auth two-phase: preferred ok skips fallback probes', () async {
    final preferredId = kPreferredBuiltinLineIds.first;
    final lines = [
      _line(preferredId),
      _line('fallback1'),
      _line('fallback2'),
    ];
    final hit = <String>[];
    final results = await runAuthTwoPhaseBatchedProbe(
      lines: lines,
      priorHealth: const {},
      random: Random(1),
      probe: (line) async {
        hit.add(line.id);
        if (line.id == preferredId) {
          return const LineProbeOutcome(latencyMs: 20, httpStatus: 200);
        }
        return const LineProbeOutcome(errorCategory: 'dns');
      },
    );
    expect(hit, [preferredId]);
    expect(results.single.line.id, preferredId);
    expect(results.single.outcome.ok, isTrue);
  });

  test('auth two-phase: preferred all fail expands to fallbacks', () async {
    final preferredId = kPreferredBuiltinLineIds.first;
    final lines = [
      _line(preferredId),
      _line('fallback1'),
      _line('fallback2'),
    ];
    final hit = <String>[];
    final results = await runAuthTwoPhaseBatchedProbe(
      lines: lines,
      priorHealth: const {},
      random: Random(2),
      probe: (line) async {
        hit.add(line.id);
        if (line.id == 'fallback2') {
          return const LineProbeOutcome(latencyMs: 30, httpStatus: 200);
        }
        return const LineProbeOutcome(errorCategory: 'dns');
      },
    );
    expect(hit.first, preferredId);
    expect(hit, contains('fallback1'));
    expect(hit, contains('fallback2'));
    expect(results.where((r) => r.outcome.ok).single.line.id, 'fallback2');
  });

  test('shouldReuseAuthWarmup only when fresh success with healthy lines', () {
    final now = DateTime(2026, 7, 31, 12);
    expect(
      LineSwitchUtil.shouldReuseAuthWarmup(
        lastOk: true,
        completedAt: now.subtract(const Duration(seconds: 30)),
        hasHealthyLines: true,
        now: now,
      ),
      isTrue,
    );
    expect(
      LineSwitchUtil.shouldReuseAuthWarmup(
        lastOk: false,
        completedAt: now,
        hasHealthyLines: true,
        now: now,
      ),
      isFalse,
    );
    expect(
      LineSwitchUtil.shouldReuseAuthWarmup(
        lastOk: true,
        completedAt: now.subtract(const Duration(minutes: 3)),
        hasHealthyLines: true,
        now: now,
      ),
      isFalse,
    );
    expect(
      LineSwitchUtil.shouldReuseAuthWarmup(
        lastOk: true,
        completedAt: now,
        hasHealthyLines: false,
        now: now,
      ),
      isFalse,
    );
    expect(LineSwitchUtil.authWarmupSplashWait.inMilliseconds, 2500);
  });

  test('auth two-phase: preferred phase respects maxBatches cap', () async {
    final preferredIds = kPreferredBuiltinLineIds.take(30).toList();
    final lines = [
      ...preferredIds.map(_line),
      _line('fallbackOk'),
    ];
    final hit = <String>[];
    final results = await runAuthTwoPhaseBatchedProbe(
      lines: lines,
      priorHealth: const {},
      random: Random(4),
      isPreferred: preferredIds.contains,
      probe: (line) async {
        hit.add(line.id);
        if (line.id == 'fallbackOk') {
          return const LineProbeOutcome(latencyMs: 25, httpStatus: 200);
        }
        return const LineProbeOutcome(errorCategory: 'dns');
      },
    );
    final preferredHits = hit.where(preferredIds.contains).length;
    final maxPreferredProbes = LineManager.authBatchProbeSize *
        LineManager.authPreferredMaxBatches;
    expect(preferredHits, maxPreferredProbes);
    expect(preferredHits < preferredIds.length, isTrue);
    expect(hit, contains('fallbackOk'));
    expect(results.where((r) => r.outcome.ok).single.line.id, 'fallbackOk');
  });

  test('linesForSwitcherPanel caps huge builtin list to preferred/current/ok', () {
    final preferredId = kPreferredBuiltinLineIds.first;
    final lines = [
      _line(preferredId),
      ...List.generate(80, (i) => _line('seed$i')),
      _line('cur'),
    ];
    final panel = LineSwitchUtil.linesForSwitcherPanel(
      runtimeLines: lines,
      currentId: 'cur',
      probeCache: {
        'seed3': LineProbeCacheEntry(ok: true, checkedAtMs: nowMs, latencyMs: 9),
      },
      softCap: 48,
    );
    final ids = panel.map((e) => e.id).toSet();
    expect(ids.contains(preferredId), isTrue);
    expect(ids.contains('cur'), isTrue);
    expect(ids.contains('seed3'), isTrue);
    expect(panel.length <= 48, isTrue);
    expect(ids.contains('seed10'), isFalse);
  });

  test('pickProbeSelectTarget prefers production healthy over seed', () {
    final current = _line('seedX');
    final selected = LineSwitchUtil.pickProbeSelectTarget(
      current: current,
      healthySortedByLatency: [_line('seedX'), _line('line46')],
      productionIds: {'line46'},
    );
    expect(selected.id, 'line46');
  });

  test('shouldKeepSeedBridgeLine only when fresh ok', () {
    expect(
      LineSwitchUtil.shouldKeepSeedBridgeLine(
        probe: LineProbeCacheEntry(ok: true, checkedAtMs: nowMs, latencyMs: 1),
        now: now,
      ),
      isTrue,
    );
    expect(
      LineSwitchUtil.shouldKeepSeedBridgeLine(
        probe: LineProbeCacheEntry(
          ok: true,
          checkedAtMs: nowMs - const Duration(minutes: 20).inMilliseconds,
          latencyMs: 1,
        ),
        now: now,
      ),
      isFalse,
    );
  });
}
