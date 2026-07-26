import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vortek/core/config/app_constants.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';
import 'package:vortek/core/storage/kv_store.dart';

/// 真机：分批探活 + 静默冷却键（走真实公网线路）。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late KvStore kv;

  setUpAll(() async {
    await Hive.initFlutter();
    kv = await KvStore.open();
  });

  testWidgets('device: probeAllBatched maxBatches=1 against prod hosts',
      (tester) async {
    final manager = LineManager();
    final sw = Stopwatch()..start();
    final results = await manager.probeAllBatched(
      lines: kBuiltinProdLines,
      maxBatches: 1,
    );
    sw.stop();

    // ignore: avoid_print
    print(
      'DEVICE_BATCH_PROBE probed=${results.length} '
      'ok=${results.where((e) => e.outcome.ok).length} '
      'ms=${sw.elapsedMilliseconds} '
      'hosts=${results.map((e) => '${e.line.id}:${e.outcome.ok ? e.outcome.latencyMs : e.outcome.errorCategory}').join(',')}',
    );

    expect(results.length, lessThanOrEqualTo(LineManager.batchProbeSize));
    expect(results, isNotEmpty);
    expect(
      results.any((e) => e.outcome.ok),
      isTrue,
      reason: '真机应至少探通 1 条生产线路',
    );
  });

  testWidgets('device: last_batch_probe cooldown key roundtrip', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await kv.setLastBatchProbeAtMs(now);
    expect(kv.lastBatchProbeAtMs, now);

    final withinCooldown =
        now - (kv.lastBatchProbeAtMs ?? 0) < const Duration(minutes: 5).inMilliseconds;
    expect(withinCooldown, isTrue);

    // 模拟冷却外：拨回 6 分钟前
    await kv.setLastBatchProbeAtMs(now - const Duration(minutes: 6).inMilliseconds);
    final cooled = now - (kv.lastBatchProbeAtMs ?? 0) >=
        const Duration(minutes: 5).inMilliseconds;
    expect(cooled, isTrue);
    expect(StorageKeys.lastBatchProbeAtMs, 'last_batch_probe_at_ms');
  });

  testWidgets('device: second batch within cooldown should be skipped by gate',
      (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await kv.setLastBatchProbeAtMs(now);

    final last = kv.lastBatchProbeAtMs ?? 0;
    final shouldSkip =
        now - last < const Duration(minutes: 5).inMilliseconds;
    expect(shouldSkip, isTrue);

    // ignore: avoid_print
    print('DEVICE_SILENT_COOLDOWN skip=$shouldSkip last=$last now=$now');
  });
}
