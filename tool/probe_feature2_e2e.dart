import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vortek/api/auth_api.dart';
import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/http/dio_client.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/line/line_manager.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/core/utils/line_switch_util.dart';
import 'package:vortek/models/register_dto.dart';

void ok(String n) => print('[CASE OK] $n');
void bad(String n, String d) {
  print('[CASE FAIL] $n :: $d');
  throw StateError('$n: $d');
}

Future<T> withAuthLineFailover<T>(
  ProviderContainer c,
  Future<T> Function() action, {
  required String apiPath,
  bool initialProbe = true,
}) async {
  if (initialProbe) {
    await c.read(lineProvider.notifier).checkCurrentLineStatus(allowFallback: true);
  }
  final tried = <String>{};
  Object? lastError;
  for (var attempt = 0; attempt < 3; attempt++) {
    final line = c.read(lineProvider);
    tried.add(line.id);
    try {
      return await action();
    } catch (e) {
      lastError = e;
      final api = asApiException(e);
      if (!isNetworkApiError(api)) rethrow;
      print('[info] $apiPath network on ${line.id}/${line.host}, failover #${attempt + 1}');
      final next = await c
          .read(lineProvider.notifier)
          .failoverToNextHealthyLine(triedIds: tried);
      if (next == null) rethrow;
      print('[info] switched -> ${next.id} ${next.host}');
    }
  }
  throw lastError ?? ApiException.network();
}

Future<void> refreshHealthyWithoutSelecting(LineNotifier notifier) async {
  final mgr = LineManager();
  final results = await mgr.probeAll(lines: kLines);
  final sorted = results
      .where((r) => r.outcome.latencyMs != null)
      .map((r) => (line: r.line, ms: r.outcome.latencyMs!))
      .toList()
    ..sort((a, b) => a.ms.compareTo(b.ms));
  notifier.lastHealthyLines = sorted.map((e) => e.line).toList(growable: false);
  print('[info] healthy cache=${notifier.lastHealthyLines.map((e) => "${e.id}:${e.host}").join(", ")}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final kv = await KvStore.open();
  print('[suite] feature2 e2e start');

  final container = ProviderContainer(
    overrides: [kvStoreProvider.overrideWithValue(kv)],
  );
  final lineNotifier = container.read(lineProvider.notifier);
  final dio = DioClient(
    kv: kv,
    getBaseUrl: () => container.read(lineProvider).baseUrl,
    onAuthFail: () {},
  );
  final authApi = AuthApi(dio);
  var failed = 0;

  Future<void> runCase(String name, Future<void> Function() body) async {
    try {
      await body();
    } catch (e, st) {
      failed++;
      print('[CASE FAIL] $name :: $e');
      print(st);
    }
  }

  await runCase('E1', () async {
    final probeOk =
        await lineNotifier.checkCurrentLineStatus(allowFallback: true);
    final line = container.read(lineProvider);
    final healthy = lineNotifier.lastHealthyLines;
    print(
      '[info] E1 probeOk=$probeOk current=${line.id}/${line.host} healthy=${healthy.map((e) => e.id).join(",")}',
    );
    if (!probeOk || healthy.isEmpty) bad('E1', 'no healthy');
    ok('E1 probeAll + select (${line.id})');
  });

  await runCase('E2', () async {
    final dto = RegisterDTO(
      mode: 'phone',
      phone: '13800138000',
      password: 'Test1234',
      inviteCode: '000000',
      registerTerminal: 1,
      loginType: 'android',
      deviceInfo: 'smoke',
      clientVersion: '1.0.1-smoke',
    );
    try {
      await authApi.register(dto);
      bad('E2', 'register succeeded');
    } catch (e) {
      final api = asApiException(e);
      print('[info] E2 code=${api.code} msg=${api.message}');
      if (isNetworkApiError(api)) bad('E2', 'network ${api.message}');
      ok('E2 business error on healthy line (${api.message})');
    }
  });

  await runCase('E3', () async {
    final before = container.read(lineProvider).id;
    final dto = RegisterDTO(
      mode: 'phone',
      phone: '13800138001',
      password: 'Test1234',
      inviteCode: '111111',
      registerTerminal: 1,
      loginType: 'android',
      deviceInfo: 'smoke',
      clientVersion: '1.0.1-smoke',
    );
    try {
      await withAuthLineFailover(
        container,
        () => authApi.register(dto),
        apiPath: '/register',
      );
      bad('E3', 'succeeded');
    } catch (e) {
      final api = asApiException(e);
      final after = container.read(lineProvider).id;
      print('[info] E3 before=$before after=$after code=${api.code}');
      if (isNetworkApiError(api)) bad('E3', 'network');
      if (before != after) bad('E3', 'line changed $before->$after');
      ok('E3 business error does not switch line ($before)');
    }
  });

  await runCase('E4', () async {
    await refreshHealthyWithoutSelecting(lineNotifier);
    final healthy = lineNotifier.lastHealthyLines;
    final drakoHealthy = healthy.any((e) => e.id == 'line2');
    if (drakoHealthy) {
      ok('E4 skipped (drako healthy on this network)');
      return;
    }
    if (healthy.isEmpty) bad('E4', 'no backup healthy');

    await lineNotifier.switchTo('line2');
    if (container.read(lineProvider).id != 'line2') {
      bad('E4', 'failed to stay on line2');
    }
    // 去掉 drako，只保留其它通线，供 failover 使用
    lineNotifier.lastHealthyLines =
        healthy.where((e) => e.id != 'line2').toList(growable: false);

    final dto = RegisterDTO(
      mode: 'phone',
      phone: '13800138002',
      password: 'Test1234',
      inviteCode: '222222',
      registerTerminal: 1,
      loginType: 'android',
      deviceInfo: 'smoke',
      clientVersion: '1.0.1-smoke',
    );

    final before = container.read(lineProvider).id;
    try {
      await withAuthLineFailover(
        container,
        () => authApi.register(dto),
        apiPath: '/register',
        initialProbe: false, // 保留坏线，才能测到第一次网络失败
      );
      bad('E4', 'unexpected success');
    } catch (e) {
      final api = asApiException(e);
      final after = container.read(lineProvider).id;
      print(
        '[info] E4 before=$before after=$after code=${api.code} msg=${api.message}',
      );
      if (after == 'line2') bad('E4', 'still on drako');
      if (isNetworkApiError(api)) bad('E4', 'still network: ${api.message}');
      ok('E4 dead line network fail -> failover -> business ($after)');
    }
  });

  await runCase('E5', () async {
    await refreshHealthyWithoutSelecting(lineNotifier);
    final healthy = lineNotifier.lastHealthyLines;
    final next = LineSwitchUtil.nextHealthyCandidate(
      healthySortedByLatency: healthy,
      triedIds: {if (healthy.isNotEmpty) healthy.first.id},
    );
    if (healthy.length <= 1) {
      ok('E5 sole healthy (${healthy.length})');
    } else if (next != null && next.id != healthy.first.id) {
      ok('E5 next=${next.id}');
    } else {
      bad('E5', 'next=${next?.id}');
    }
  });

  print('[suite] done failed=$failed current=${container.read(lineProvider).id}');
  container.dispose();
  if (failed > 0) throw StateError('e2e failed=$failed');
  print('[suite] ALL PASSED');
}