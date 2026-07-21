import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';
import 'package:vortek/core/utils/line_switch_util.dart';

void pass(String n) => print('[CASE OK] $n');
void fail(String n, String d) { print('[CASE FAIL] $n :: $d'); throw StateError(n); }

Future<void> main() async {
  print('[suite] feature2 failover candidates');
  final mgr = LineManager();
  final results = await mgr.probeAll(lines: kLines);
  final healthy = results
      .where((r) => r.outcome.latencyMs != null)
      .map((r) => r.line)
      .toList();
  // reorder by latency like production
  final sorted = <({LineConfig line, int ms})>[];
  for (final r in results) {
    if (r.outcome.latencyMs != null) sorted.add((line: r.line, ms: r.outcome.latencyMs!));
  }
  sorted.sort((a, b) => a.ms.compareTo(b.ms));
  final healthySorted = sorted.map((e) => e.line).toList();
  print('[info] healthy=${healthySorted.map((e) => e.id).join(",")}');

  if (healthySorted.isEmpty) fail('need healthy', 'none');

  final tried = <String>{healthySorted.first.id};
  final next = LineSwitchUtil.nextHealthyCandidate(
    healthySortedByLatency: healthySorted,
    triedIds: tried,
  );
  if (next == null) {
    if (healthySorted.length == 1) {
      pass('F2-1 only one healthy, no next (ok)');
    } else {
      fail('F2-1 next after first', 'null');
    }
  } else if (next.id != healthySorted.first.id) {
    pass('F2-1 after trying ${tried.first} -> ${next.id}');
  } else {
    fail('F2-1', 'same as tried');
  }

  final allTried = healthySorted.map((e) => e.id).toSet();
  final none = LineSwitchUtil.nextHealthyCandidate(
    healthySortedByLatency: healthySorted,
    triedIds: allTried,
  );
  if (none == null) {
    pass('F2-2 all tried -> null');
  } else {
    fail('F2-2', 'got ${none.id}');
  }

  // simulate register path: fail on line1, pick next
  final afterMain = LineSwitchUtil.nextHealthyCandidate(
    healthySortedByLatency: healthySorted,
    triedIds: {'line1'},
  );
  if (healthySorted.any((e) => e.id == 'line1') && healthySorted.length > 1) {
    if (afterMain != null && afterMain.id != 'line1') {
      pass('F2-3 fail line1 -> ${afterMain.id}');
    } else {
      fail('F2-3', 'got ${afterMain?.id}');
    }
  } else {
    pass('F2-3 skip (line1 not in healthy or sole)');
  }

  print('[suite] ALL PASSED healthy_n=${healthy.length}');
}