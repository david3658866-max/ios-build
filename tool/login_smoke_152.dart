import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/services/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final kv = await KvStore.open();
  final container = ProviderContainer(overrides: [
    kvStoreProvider.overrideWithValue(kv),
  ]);
  print('[login-smoke] start 15222222222');
  try {
    await container.read(authControllerProvider.notifier).loginWithPassword(
          userName: '15222222222',
          password: '123456',
        );
    print('[login-smoke] SUCCESS status=${container.read(authControllerProvider)}');
  } catch (e) {
    final api = asApiException(e);
    print('[login-smoke] FAIL code=${api.code}');
    print('[login-smoke] msg=${api.message}');
    final useDialog = api.code == 10031 ||
        api.code == 10032 ||
        api.message.contains('解绑') ||
        api.message.contains('卸载') ||
        api.message.contains('换机') ||
        api.message.contains('设备标识');
    print('[login-smoke] shouldConfirmDialog=$useDialog');
  }
  container.dispose();
  print('[login-smoke] done');
}