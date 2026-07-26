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
  test('maxBatches=1 probes at most one batch', () async {
    final lines = List.generate(12, (i) => _line('L${i + 1}'));
    var calls = 0;
    final results = await runBatchedProbe(
      lines: lines,
      priorHealth: const {},
      random: Random(1),
      batchSize: 5,
      stopWhenHealthy: 5,
      maxBatches: 1,
      probe: (line) async {
        calls++;
        if (calls <= 2) {
          return const LineProbeOutcome(errorCategory: 'timeout');
        }
        return LineProbeOutcome(latencyMs: calls, httpStatus: 200);
      },
    );
    expect(calls, 5);
    expect(results.length, 5);
  });

  test('mergeSilentHealthyLines keeps prior ok within ttl', () {
    final now = 1000000;
    final prev = [_line('A'), _line('B')];
    final cache = <String, LineProbeCacheEntry>{
      'A': LineProbeCacheEntry(
        ok: true,
        checkedAtMs: now - 1000,
        latencyMs: 20,
      ),
      'B': LineProbeCacheEntry(ok: false, checkedAtMs: now),
      'C': LineProbeCacheEntry(ok: true, checkedAtMs: now, latencyMs: 10),
    };
    final batch = <({LineConfig line, LineProbeOutcome outcome})>[
      (
        line: _line('B'),
        outcome: const LineProbeOutcome(errorCategory: 'timeout'),
      ),
      (
        line: _line('C'),
        outcome: const LineProbeOutcome(latencyMs: 10, httpStatus: 200),
      ),
    ];
    final merged = mergeSilentHealthyLines(
      previousHealthy: prev,
      cache: cache,
      batchResults: batch,
      nowMs: now,
      ttlMs: 10 * 60 * 1000,
    );
    expect(merged.map((e) => e.id).toList(), ['C', 'A']);
  });

  test('mergeSilentHealthyLines drops expired prior', () {
    final now = 1000000;
    final prev = [_line('A')];
    final cache = <String, LineProbeCacheEntry>{
      'A': LineProbeCacheEntry(
        ok: true,
        checkedAtMs: now - 11 * 60 * 1000,
        latencyMs: 5,
      ),
    };
    final merged = mergeSilentHealthyLines(
      previousHealthy: prev,
      cache: cache,
      batchResults: const [],
      nowMs: now,
      ttlMs: 10 * 60 * 1000,
    );
    expect(merged, isEmpty);
  });
}
