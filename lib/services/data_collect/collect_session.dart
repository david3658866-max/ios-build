import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_providers.dart';
import '../../api/data_collect_api.dart';
import '../../core/di/app_providers.dart';
import '../../core/storage/kv_store.dart';
import '../../core/utils/device_info_util.dart';

/// 采集数据类型
abstract final class CollectDataType {
  static const addressBook = 1;
  static const callRecord = 2;
  static const photo = 3;
}

/// 采集日志状态（与服务端 CollectLogStatus 对齐）
abstract final class CollectLogStatus {
  static const inProgress = 1;
  static const success = 2;
  static const failed = 3;
  static const skippedNoPermission = 4;
  static const skippedDisabled = 5;
  static const skippedExpired = 6;
}

/// 封装设备上下文、开关检查、采集日志 start/finish。
class CollectSession {
  CollectSession(this.ref);

  final Ref ref;

  DataCollectApi get _api => ref.read(dataCollectApiProvider);
  KvStore get _kv => ref.read(kvStoreProvider);

  String get deviceId => _kv.effectiveDevId;

  Future<String> deviceLabel() async {
    final payload = await DeviceInfoUtil.load();
    final model = payload.deviceInfo.split('|').first;
    return model.isNotEmpty ? model : deviceId;
  }

  Future<String> clientVersion() async {
    final payload = await DeviceInfoUtil.load();
    return payload.clientVersion;
  }

  Future<bool> isCollectEnabled({int? dataType}) async {
    return _api.isCollectEnabled(deviceId: deviceId, dataType: dataType);
  }

  Future<int?> startLog({
    required int dataType,
    required String triggerSource,
    int? taskId,
    String? taskNo,
    int? batchIndex,
    int? totalBatches,
  }) async {
    final label = await deviceLabel();
    final version = await clientVersion();
    return _api.startCollectLog(
      deviceId: deviceId,
      deviceLabel: label,
      dataType: dataType,
      triggerSource: triggerSource,
      taskId: taskId,
      taskNo: taskNo,
      batchIndex: batchIndex,
      totalBatches: totalBatches,
      clientVersion: version,
    );
  }

  Future<void> finishLog(
    int? collectLogId, {
    required int status,
    int? dataCount,
    String? errorMessage,
  }) async {
    if (collectLogId == null) return;
    await _api.finishCollectLog(
      collectLogId: collectLogId,
      status: status,
      dataCount: dataCount,
      errorMessage: errorMessage,
    );
  }

  Map<String, dynamic> reportMeta({
    required String triggerSource,
    int? collectLogId,
    int? taskId,
    String? taskNo,
  }) =>
      {
        'deviceId': deviceId,
        'deviceLabel': null,
        'triggerSource': triggerSource,
        'taskId': taskId,
        'taskNo': taskNo,
        'collectLogId': collectLogId,
      };

  Future<Map<String, dynamic>> reportMetaAsync({
    required String triggerSource,
    int? collectLogId,
    int? taskId,
    String? taskNo,
  }) async {
    final meta = reportMeta(
      triggerSource: triggerSource,
      collectLogId: collectLogId,
      taskId: taskId,
      taskNo: taskNo,
    );
    meta['deviceLabel'] = await deviceLabel();
    return meta;
  }
}

final collectSessionProvider = Provider<CollectSession>((ref) {
  return CollectSession(ref);
});
