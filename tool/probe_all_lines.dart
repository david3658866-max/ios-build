import 'package:flutter/foundation.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';

/// 真机冒烟：并发探活 + 选线逻辑（与功能1一致）。
/// flutter run -d <device> -t tool/probe_all_lines.dart --dart-define=APP_ENV=prod
Future<void> main() async {
  // ignore: avoid_print
  print('[smoke] APP_ENV=$kAppEnv debug=$kDebugMode');
  final mgr = LineManager();
  final sw = Stopwatch()..start();
  final results = await mgr.probeAll(lines: kLines);
  sw.stop();
  // ignore: avoid_print
  print('[smoke] probeAll done in ${sw.elapsedMilliseconds}ms');
  final healthy = <({LineConfig line, int ms})>[];
  for (final r in results) {
    final ms = r.outcome.latencyMs;
    // ignore: avoid_print
    print('[smoke] ${r.line.id} ${r.line.name} ${r.line.host}: ${ms == null ? "FAIL" : "${ms}ms"}');
    if (ms != null) healthy.add((line: r.line, ms: ms));
  }
  healthy.sort((a, b) => a.ms.compareTo(b.ms));
  if (healthy.isEmpty) {
    // ignore: avoid_print
    print('[smoke] RESULT: none available');
    return;
  }
  final current = kDefaultLine;
  final currentOk = healthy.any((e) => e.line.id == current.id);
  final selected = currentOk ? current : healthy.first.line;
  // ignore: avoid_print
  print('[smoke] current=${current.id} ok=$currentOk');
  // ignore: avoid_print
  print('[smoke] SELECT=${selected.id} ${selected.name} ${selected.host}');
}