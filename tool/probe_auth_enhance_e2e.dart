import 'package:flutter/foundation.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';
import 'package:vortek/core/utils/line_switch_util.dart';

void pass(String name) => print('[CASE OK] $name');
void fail(String name, String detail) => print('[CASE FAIL] $name :: $detail');

LineConfig selectLine({
  required LineConfig current,
  required List<({LineConfig line, int ms})> healthy,
}) {
  if (healthy.isEmpty) return current;
  final currentOk = healthy.any((e) => e.line.id == current.id);
  return currentOk ? current : healthy.first.line;
}

Future<void> main() async {
  print('[suite] auth enhance start APP_ENV=$kAppEnv debug=$kDebugMode');
  final mgr = LineManager();
  var failed = 0;

  void markFail(String name, String detail) {
    failed++;
    fail(name, detail);
  }

  const dead = LineConfig(
    id: 'dead_retry',
    name: 'dead-retry',
    label: 'dead',
    host: 'invalid-line-probe-retry.invalid',
    baseUrl: 'https://invalid-line-probe-retry.invalid/api',
    wsUrl: 'wss://invalid-line-probe-retry.invalid/im',
    scanUrl: 'https://invalid-line-probe-retry.invalid',
  );
  final retrySw = Stopwatch()..start();
  final deadMs = await mgr.probe(
    dead,
    timeout: const Duration(seconds: 2),
    maxAttempts: 3,
    retryDelay: const Duration(seconds: 1),
  );
  retrySw.stop();
  print('[info] R1 dead probe ms=${deadMs ?? "FAIL"} elapsed=${retrySw.elapsedMilliseconds}ms');
  if (deadMs != null) {
    markFail('R1 dead host retries then fails', 'unexpected ok ${deadMs}ms');
  } else if (retrySw.elapsedMilliseconds < 1800) {
    markFail('R1 dead host retries then fails', 'too fast ${retrySw.elapsedMilliseconds}ms');
  } else {
    pass('R1 dead host retries then fails (${retrySw.elapsedMilliseconds}ms)');
  }

  final line1 = kLines.firstWhere((l) => l.id == 'line1');
  final okSw = Stopwatch()..start();
  final line1Ms = await mgr.probe(
    line1,
    timeout: const Duration(seconds: 8),
    maxAttempts: 3,
    retryDelay: const Duration(seconds: 1),
  );
  okSw.stop();
  print('[info] R2 line1 ms=${line1Ms ?? "FAIL"} elapsed=${okSw.elapsedMilliseconds}ms');
  if (line1Ms == null) {
    markFail('R2 healthy line fast path', 'line1 FAIL');
  } else if (okSw.elapsedMilliseconds > 5000) {
    markFail('R2 healthy line fast path', 'too slow ${okSw.elapsedMilliseconds}ms');
  } else {
    pass('R2 healthy line fast path (${okSw.elapsedMilliseconds}ms / ${line1Ms}ms rtt)');
  }

  final allSw = Stopwatch()..start();
  final results = await mgr.probeAll(
    lines: kLines,
    timeout: const Duration(seconds: 5),
    maxAttempts: 2,
    retryDelay: const Duration(seconds: 1),
  );
  allSw.stop();
  for (final r in results) {
    print('[info]  ${r.line.id} ${r.line.host}: ${r.outcome.latencyMs ?? "FAIL"}');
  }
  final healthy = results
      .where((r) => r.outcome.latencyMs != null)
      .map((r) => (line: r.line, ms: r.outcome.latencyMs!))
      .toList()
    ..sort((a, b) => a.ms.compareTo(b.ms));
  print('[info] R3 probeAll ${allSw.elapsedMilliseconds}ms healthy=${healthy.length}');
  if (healthy.isEmpty) {
    markFail('R3 probeAll has healthy', 'all failed');
  } else if (allSw.elapsedMilliseconds > 15000) {
    markFail('R3 probeAll has healthy', 'too slow ${allSw.elapsedMilliseconds}ms');
  } else {
    pass('R3 probeAll has healthy n=${healthy.length} (${allSw.elapsedMilliseconds}ms)');
  }

  final autoToast = LineSwitchUtil.autoSwitchToast('backup-2');
  if (autoToast.endsWith('backup-2') && autoToast.length > 'backup-2'.length) {
    pass('T1 autoSwitchToast ($autoToast)');
  } else {
    markFail('T1 autoSwitchToast', autoToast);
  }
  final allFailToast = LineSwitchUtil.allLinesFailedToast;
  if (allFailToast.isNotEmpty && allFailToast.length >= 8) {
    pass('T2 allLinesFailedToast len=${allFailToast.length}');
  } else {
    markFail('T2 allLinesFailedToast', allFailToast);
  }

  if (healthy.isEmpty) {
    print('[CASE SKIP] A1 auto switch toast (no healthy)');
  } else {
    final fromDead = kLines.firstWhere((l) => l.id == 'line2');
    final selected = selectLine(current: fromDead, healthy: healthy);
    final switched = selected.id != fromDead.id;
    final toast = !switched
        ? '(keep ${selected.name}, no toast)'
        : LineSwitchUtil.autoSwitchToast(selected.name);
    print('[info] A1 from=${fromDead.id} -> ${selected.id} switched=$switched toast=$toast');
    if (!healthy.any((e) => e.line.id == fromDead.id) && !switched) {
      markFail('A1 auto switch from dead', 'should switch');
    } else {
      pass('A1 auto switch from dead -> ${selected.id}');
    }
  }

  final keep = selectLine(current: line1, healthy: const []);
  if (keep.id == line1.id) {
    pass('A2 all dead keeps current');
  } else {
    markFail('A2 all dead keeps current', 'got ${keep.id}');
  }

  print('[suite] done failed=$failed');
  if (failed > 0) {
    throw StateError('auth enhance smoke failed: $failed');
  }
  print('[suite] ALL PASSED');
}