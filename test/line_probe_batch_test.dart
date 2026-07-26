import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';
import 'package:vortek/core/line/line_probe_outcome.dart';

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
  test('orderLinesForProbe: healthy > unknown > failed', () {
    final lines = [
      _line('a'),
      _line('b'),
      _line('c'),
      _line('d'),
      _line('e'),
    ];
    final prior = <String, LineProbeCacheEntry?>{
      'a': const LineProbeCacheEntry(ok: false, checkedAtMs: 1),
      'b': const LineProbeCacheEntry(ok: true, checkedAtMs: 1, latencyMs: 10),
      'c': null,
      'd': const LineProbeCacheEntry(ok: true, checkedAtMs: 1, latencyMs: 20),
      'e': const LineProbeCacheEntry(ok: false, checkedAtMs: 1),
    };
    final ordered = orderLinesForProbe(lines, prior, Random(1));
    final ids = ordered.map((e) => e.id).toList();
    expect(ids.take(2).toSet(), {'b', 'd'});
    expect(ids[2], 'c');
    expect(ids.skip(3).toSet(), {'a', 'e'});

    final other = orderLinesForProbe(lines, prior, Random(2));
    expect(other.take(2).map((e) => e.id).toSet(), {'b', 'd'});
  });

  test('failed lines demoted to end of order', () {
    final lines = [_line('ok1'), _line('bad1'), _line('new1')];
    final prior = <String, LineProbeCacheEntry?>{
      'ok1': const LineProbeCacheEntry(ok: true, checkedAtMs: 1, latencyMs: 5),
      'bad1': const LineProbeCacheEntry(ok: false, checkedAtMs: 1),
    };
    final ids =
        orderLinesForProbe(lines, prior, Random(0)).map((e) => e.id).toList();
    expect(ids.first, 'ok1');
    expect(ids[1], 'new1');
    expect(ids.last, 'bad1');
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
    final prior = <String, LineProbeCacheEntry?>{
      for (final id in ['L7', 'L8', 'L9'])
        id: const LineProbeCacheEntry(ok: true, checkedAtMs: 1, latencyMs: 1),
      for (final id in ['L1', 'L2', 'L3'])
        id: const LineProbeCacheEntry(ok: false, checkedAtMs: 1),
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
  });
}
