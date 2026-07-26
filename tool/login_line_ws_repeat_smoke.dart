import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:vortek/core/di/app_providers.dart";
import "package:vortek/core/storage/kv_store.dart";
import "package:vortek/core/utils/line_switch_util.dart";
import "package:vortek/core/ws/ws_event.dart";
import "package:vortek/models/login_info.dart";
import "package:vortek/stores/config_store.dart";

/// Inject token from host login, then repeat HTTP+WS checks.
const _rounds = 4;
const _wsWait = Duration(seconds: 20);
const _token = String.fromEnvironment("SMOKE_TOKEN", defaultValue: "");
const _refresh = String.fromEnvironment("SMOKE_REFRESH", defaultValue: "");
const _deviceId = String.fromEnvironment("SMOKE_DEVICE_ID", defaultValue: "smoke-device");
const _userId = int.fromEnvironment("SMOKE_USER_ID", defaultValue: 66882580);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final kv = await KvStore.open();
  final container = ProviderContainer(overrides: [
    kvStoreProvider.overrideWithValue(kv),
  ]);

  try {
    if (_token.isEmpty) {
      throw StateError("missing --dart-define=SMOKE_TOKEN");
    }
    await kv.clearLoginInfo();
    await kv.setDevId(_deviceId);
    await kv.setLoginInfo(LoginInfo(
      accessToken: _token,
      refreshToken: _refresh.isEmpty ? _token : _refresh,
      userId: _userId,
      deviceId: _deviceId,
    ));
    await kv.setLoginPhone("15222222222");
    print("[suite] token injected userId=$_userId deviceId=$_deviceId");

    final lineNotifier = container.read(lineProvider.notifier);
    print("[suite] probeAll...");
    await lineNotifier.refreshHealthyLines(triggerSource: "smoke_post_login");
    final httpOk = await lineNotifier.checkCurrentLineStatus(allowFallback: true);
    final line = container.read(lineProvider);
    print(
      "[suite] line=${line.id} ${line.name} host=${line.host} httpOk=$httpOk "
      "lineStatus=${container.read(configStoreProvider).lineStatus.name}",
    );
    if (!httpOk) throw StateError("http probe failed before rounds");

    var okRounds = 0;
    for (var i = 1; i <= _rounds; i++) {
      print("");
      print("========== ROUND $i/$_rounds ==========");
      final ok = await _checkLineAndWs(container, kv, i);
      if (ok) okRounds++;
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    print("");
    print("[SUITE] DONE ok=$okRounds/$_rounds");
    if (okRounds < _rounds) {
      throw StateError("line/ws smoke failed: $okRounds/$_rounds");
    }
  } finally {
    container.read(wsManagerProvider).close();
    await kv.clearLoginInfo();
    container.dispose();
  }
}

Future<bool> _checkLineAndWs(ProviderContainer c, KvStore kv, int round) async {
  final lineNotifier = c.read(lineProvider.notifier);
  final config = c.read(configStoreProvider.notifier);
  final ws = c.read(wsManagerProvider);
  final token = kv.accessToken;
  if (token == null || token.isEmpty) {
    print("[r$round] FAIL no token");
    return false;
  }

  ws.close();
  config.setWsStatus(WsStatus.disconnected);

  final httpOk = await lineNotifier.checkCurrentLineStatus(allowFallback: false);
  final line = c.read(lineProvider);
  final lineStatus = c.read(configStoreProvider).lineStatus;
  print(
    "[r$round] httpOk=$httpOk line=${line.id} ${line.name} "
    "host=${line.host} lineStatus=${lineStatus.name}",
  );

  final completer = Completer<WsStatus>();
  late final StreamSubscription<WsStatus> sub;
  sub = ws.statusStream.listen((s) {
    print("[r$round] ws -> ${s.name}");
    if (s == WsStatus.connected || s == WsStatus.disconnected) {
      if (!completer.isCompleted) completer.complete(s);
    }
  });

  ws.connect(wsUrl: line.wsUrl, token: token, devId: kv.effectiveDevId);

  WsStatus finalWs;
  try {
    finalWs = await completer.future.timeout(_wsWait, onTimeout: () => ws.status);
  } finally {
    await sub.cancel();
  }
  if (finalWs != WsStatus.connected) {
    await Future<void>.delayed(const Duration(seconds: 3));
    finalWs = ws.status;
  }

  final cfg = c.read(configStoreProvider);
  config.setWsStatus(finalWs);
  final chip = LineSwitchUtil.chipStatus(
    isAuthenticated: true,
    lineStatus: cfg.lineStatus,
    wsStatus: finalWs,
  );
  final degraded = LineSwitchUtil.isMessageChannelDegraded(
    isAuthenticated: true,
    lineStatus: cfg.lineStatus,
    wsStatus: finalWs,
  );
  final label = degraded
      ? "message_abnormal"
      : (chip == WsStatus.disconnected ? "connect_fail" : "ok");
  print(
    "[r$round] RESULT http=${cfg.lineStatus.name} ws=${finalWs.name} "
    "chip=${chip.name} degraded=$degraded label=$label",
  );

  final ok = httpOk && finalWs == WsStatus.connected && !degraded;
  print(ok ? "[r$round] PASS" : "[r$round] FAIL");
  return ok;
}