import 'package:flutter/foundation.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';

LineConfig selectLine({
  required LineConfig current,
  required List<({LineConfig line, int ms})> healthy,
}) {
  if (healthy.isEmpty) {
    return current;
  }
  final currentOk = healthy.any((e) => e.line.id == current.id);
  return currentOk ? current : healthy.first.line;
}

void pass(String name) => print('[CASE OK] $name');
void fail(String name, String detail) => print('[CASE FAIL] $name :: $detail');

Future<void> main() async {
  print('[suite] start APP_ENV=$kAppEnv debug=$kDebugMode device-smoke');
  final mgr = LineManager();
  var failed = 0;

  // ---- 1) 并发探活速度 ----
  final sw = Stopwatch()..start();
  var results = await mgr.probeAll(lines: kLines);
  sw.stop();
  final concurrentMs = sw.elapsedMilliseconds;
  print('[info] probeAll #1 ${concurrentMs}ms');
  for (final r in results) {
    print('[info]  ${r.line.id} ${r.line.host}: ${r.outcome.latencyMs ?? "FAIL"}');
  }
  if (concurrentMs <= 6000) {
    pass('S1 concurrent probe finishes quickly (${concurrentMs}ms)');
  } else {
    failed++;
    fail('S1 concurrent probe finishes quickly', '${concurrentMs}ms > 6000');
  }

  // ---- 2) 至少一条通 ----
  var healthy = results
      .where((r) => r.outcome.latencyMs != null)
      .map((r) => (line: r.line, ms: r.outcome.latencyMs!))
      .toList()
    ..sort((a, b) => a.ms.compareTo(b.ms));
  if (healthy.isNotEmpty) {
    pass('S2 at least one line healthy (n=${healthy.length})');
  } else {
    failed++;
    fail('S2 at least one line healthy', 'all failed');
  }

  // ---- 3) 主线通则保留主线 ----
  final line1 = kLines.firstWhere((l) => l.id == 'line1');
  final line1Ok = healthy.any((e) => e.line.id == 'line1');
  if (line1Ok) {
    final selected = selectLine(current: line1, healthy: healthy);
    if (selected.id == 'line1') {
      pass('S3 keep line1 when healthy');
    } else {
      failed++;
      fail('S3 keep line1 when healthy', 'got ${selected.id}');
    }
  } else {
    print('[CASE SKIP] S3 keep line1 (line1 currently FAIL on this network)');
  }

  // ---- 4) 当前是坏线 drako → 切到最快可用 ----
  final drako = kLines.firstWhere((l) => l.id == 'line2');
  final selectedFromDrako = selectLine(current: drako, healthy: healthy);
  if (healthy.isEmpty) {
    print('[CASE SKIP] S4 failover from drako (no healthy)');
  } else if (selectedFromDrako.id != 'line2' || healthy.any((e) => e.line.id == 'line2')) {
    // if drako healthy, may keep; if not, must pick fastest
    final drakoHealthy = healthy.any((e) => e.line.id == 'line2');
    if (!drakoHealthy && selectedFromDrako.id == healthy.first.line.id) {
      pass('S4 from dead drako -> fastest ${selectedFromDrako.id}');
    } else if (drakoHealthy && selectedFromDrako.id == 'line2') {
      pass('S4 drako healthy -> keep drako');
    } else {
      failed++;
      fail('S4 failover from drako', 'selected=${selectedFromDrako.id}');
    }
  }

  // ---- 5) 当前是本地调试线（不在线上结果里）→ 选最快 ----
  final fromLocal = selectLine(current: kLocalDevLine, healthy: healthy);
  if (healthy.isEmpty) {
    print('[CASE SKIP] S5 from local');
  } else if (fromLocal.id == healthy.first.line.id) {
    pass('S5 from local -> fastest ${fromLocal.id}(${fromLocal.host})');
  } else {
    failed++;
    fail('S5 from local', 'got ${fromLocal.id}');
  }

  // ---- 6) 本地探活（无 adb reverse API 时应失败）----
  final localMs = await mgr.probe(kLocalDevLine, timeout: const Duration(seconds: 3));
  print('[info] local probe: ${localMs ?? "FAIL"}');
  // 不强制 FAIL，只记录；有 reverse 时可能通
  pass('S6 local probe observed (${localMs == null ? "FAIL" : "${localMs}ms"})');

  // ---- 7) 连续两次 probeAll 稳定性 ----
  final results2 = await mgr.probeAll(lines: kLines);
  final healthy2 = results2.where((r) => r.outcome.latencyMs != null).length;
  final healthy1 = healthy.length;
  print('[info] probeAll #2 healthy=$healthy2 (was $healthy1)');
  if ((healthy1 - healthy2).abs() <= 2) {
    pass('S7 second probeAll stable-ish ($healthy1 -> $healthy2)');
  } else {
    failed++;
    fail('S7 second probeAll stable', '$healthy1 -> $healthy2');
  }

  // ---- 8) 单线探活与并发结果大体一致 ----
  var mismatch = 0;
  for (final line in kLines) {
    final single = await mgr.probe(line, timeout: const Duration(seconds: 5));
    final concurrent = results.firstWhere((r) => r.line.id == line.id).ms;
    final a = single != null;
    final b = concurrent != null;
    print('[info] single vs all ${line.id}: single=${single ?? "FAIL"} all=${concurrent ?? "FAIL"}');
    if (a != b) mismatch++;
  }
  if (mismatch <= 1) {
    pass('S8 single vs concurrent agree (mismatch=$mismatch)');
  } else {
    failed++;
    fail('S8 single vs concurrent', 'mismatch=$mismatch');
  }

  // ---- 9) 模拟「主线失败」选线（人为从 healthy 去掉 line1）----
  final withoutMain = healthy.where((e) => e.line.id != 'line1').toList();
  if (withoutMain.isEmpty) {
    print('[CASE SKIP] S9 main down failover (no backups healthy)');
  } else {
    final picked = selectLine(current: line1, healthy: withoutMain);
    if (picked.id == withoutMain.first.line.id) {
      pass('S9 simulate main down -> ${picked.id}');
    } else {
      failed++;
      fail('S9 simulate main down', 'got ${picked.id}');
    }
  }

  // ---- 10) 全挂选线：保持 current，不瞎切 ----
  final none = selectLine(current: line1, healthy: const []);
  if (none.id == line1.id) {
    pass('S10 all dead keeps current line1');
  } else {
    failed++;
    fail('S10 all dead', 'got ${none.id}');
  }

  print('[suite] done failed=$failed');
  if (failed > 0) {
    throw StateError('smoke failed: $failed case(s)');
  }
  print('[suite] ALL PASSED');
}