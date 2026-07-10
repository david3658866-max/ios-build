import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/di/app_providers.dart';
import 'core/storage/kv_store.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/chat_media_util.dart';
import 'core/utils/device_file_log.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // 先保留闪屏，但任何一步超时都立刻 remove，避免永久白屏。
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // 硬兜底：8 秒后无论怎样都关掉原生闪屏。
  unawaited(
    Future<void>.delayed(const Duration(seconds: 8), () {
      FlutterNativeSplash.remove();
    }),
  );

  debugPrint('[main] binding ok');
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]).timeout(const Duration(seconds: 3));
  } catch (e) {
    debugPrint('[main] orient skip: $e');
  }

  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 8));
    debugPrint('[main] hive init ok');
  } catch (e) {
    debugPrint('[main] hive init retry: $e');
    try {
      await Hive.initFlutter().timeout(const Duration(seconds: 8));
      debugPrint('[main] hive init ok (retry)');
    } catch (e2) {
      debugPrint('[main] hive init give up: $e2');
    }
  }

  final kv = await KvStore.open()
      .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[main] kv open timeout, use memory fallback path');
          throw TimeoutException('KvStore.open');
        },
      )
      .catchError((e) async {
        debugPrint('[main] kv open failed: $e, reset box');
        try {
          await Hive.deleteBoxFromDisk(KvStore.boxName);
        } catch (_) {}
        return KvStore.open().timeout(const Duration(seconds: 8));
      });
  debugPrint('[main] kv ok');
  unawaited(DeviceFileLog.init());

  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (_isNoisyImage404(details)) {
      final message = details.exceptionAsString();
      _Image404NoiseGuard.logOnce(message);
      NetworkImageFailCache.markFailed(_extractImageUrl(message));
      return;
    }
    log.e('[FlutterError] ${details.exceptionAsString()}\n${details.stack}');
    if (previousOnError != null) {
      previousOnError(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  log.i('星语 IM 启动');
  debugPrint('[main] runApp');
  runApp(
    ProviderScope(
      overrides: [kvStoreProvider.overrideWithValue(kv)],
      child: const VortekApp(),
    ),
  );
  // runApp 后尽快去掉闪屏，由路由展示登录/主页。
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FlutterNativeSplash.remove();
  });
}

bool _isNoisyImage404(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  if (!message.contains('HttpException: Invalid statusCode: 404')) {
    return false;
  }
  return message.contains('/file/my-im/image/') ||
      message.contains('/downloads/') ||
      message.contains('/upload/');
}

String _extractImageUrl(String message) {
  const marker = 'uri = ';
  final idx = message.indexOf(marker);
  if (idx < 0) return '';
  return message.substring(idx + marker.length).trim();
}

class _Image404NoiseGuard {
  static const Duration _cooldown = Duration(seconds: 30);
  static final Map<String, int> _lastLogAtMs = <String, int>{};

  static void logOnce(String message) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = _extractImageUrl(message);
    final last = _lastLogAtMs[key];
    if (last != null && now - last < _cooldown.inMilliseconds) return;
    _lastLogAtMs[key] = now;
    log.w('[Image404] ignore noisy image 404: $key');
    if (_lastLogAtMs.length <= 256) return;
    final removeCount = _lastLogAtMs.length - 256;
    final keys = _lastLogAtMs.keys.take(removeCount).toList();
    for (final item in keys) {
      _lastLogAtMs.remove(item);
    }
  }
}
