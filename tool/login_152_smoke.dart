import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vortek/api/auth_api.dart';
import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/http/dio_client.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/core/utils/device_id_util.dart';
import 'package:vortek/core/utils/device_info_util.dart';
import 'package:vortek/core/utils/device_integrity_util.dart';
import 'package:vortek/models/login_dto.dart';

Future<T> withAuthLineFailover<T>(
  ProviderContainer c,
  Future<T> Function() action,
) async {
  await c.read(lineProvider.notifier).checkCurrentLineStatus(allowFallback: true);
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
      print('[info] network on ${line.id}, failover #${attempt + 1}');
      final next = await c
          .read(lineProvider.notifier)
          .failoverToNextHealthyLine(triedIds: tried);
      if (next == null) rethrow;
      print('[info] switched -> ${next.id}');
    }
  }
  throw lastError ?? ApiException.network();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final kv = await KvStore.open();
  final container = ProviderContainer(overrides: [
    kvStoreProvider.overrideWithValue(kv),
  ]);
  print('[login] line probe...');
  await container.read(lineProvider.notifier).checkCurrentLineStatus(allowFallback: true);
  final line = container.read(lineProvider);
  print('[login] line=${line.id} ${line.host}');

  final device = await DeviceInfoUtil.load();
  final rawHardwareId = await DeviceIdUtil.readRawHardwareId();
  print('[login] hw=${rawHardwareId.isEmpty ? "EMPTY" : rawHardwareId.substring(0, rawHardwareId.length > 16 ? 16 : rawHardwareId.length)}...');
  if (rawHardwareId.isEmpty) {
    throw StateError('no hardware id');
  }
  final integrity = await DeviceIntegrityUtil.probe();
  final deviceCheckToken = await DeviceIdUtil.readDeviceCheckToken();

  final dto = LoginDTO(
    mode: 'username',
    terminal: 1,
    userName: '15222222222',
    phone: '15222222222',
    email: '',
    code: '',
    password: '123456',
    loginType: device.loginType,
    platform: device.loginType,
    rawHardwareId: rawHardwareId,
    isPhysicalDevice: integrity.isPhysicalDevice,
    emulatorSuspect: integrity.emulatorSuspect,
    deviceCheckToken: deviceCheckToken.isEmpty ? null : deviceCheckToken,
    deviceInfo: device.deviceInfo,
    clientVersion: device.clientVersion,
  );

  final dio = DioClient(
    kv: kv,
    getBaseUrl: () => container.read(lineProvider).baseUrl,
    onAuthFail: () {},
  );
  final authApi = AuthApi(dio);

  try {
    final info = await withAuthLineFailover(container, () => authApi.login(dto));
    if (info.deviceId != null && info.deviceId!.isNotEmpty) {
      await kv.setDevId(info.deviceId!);
    }
    await kv.setLoginInfo(info);
    await kv.setLoginPhone('15222222222');
    print('[login] OK userId=${info.userId} deviceId=${info.deviceId}');
    print('[login] tokenLen=${info.accessToken.length}');
    print('[SUITE] LOGIN_OK');
  } catch (e) {
    final api = asApiException(e);
    print('[login] FAIL code=${api.code} msg=${api.message}');
    print('[SUITE] LOGIN_FAIL');
    rethrow;
  } finally {
    container.dispose();
  }
}