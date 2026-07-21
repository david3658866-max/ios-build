import 'package:dio/dio.dart';

import 'package:path/path.dart' as p;

import '../core/http/dio_client.dart';
import '../models/upload_file.dart';
import '../models/upload_image.dart';
import '../models/upload_video.dart';

/// 文件/图片上传。对应 FileController + image-upload.vue。
class FileApi {
  FileApi(this._c);

  final DioClient _c;

  /// POST /image/upload?isPermanent=&thumbSize=
  /// 对齐 uniapp `/image/upload?isPermanent=${isPermanent}&thumbSize=${thumbSize}`。
  Future<UploadImage> uploadImage(
    String filePath, {
    bool isPermanent = false,
    int thumbSize = 50,
  }) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    // FormData 须让 Dio 自动带 boundary；同时拉长 sendTimeout 适配大图。
    final data = await _c.post<Map<String, dynamic>>(
      '/image/upload',
      data: form,
      query: {
        'isPermanent': isPermanent,
        'thumbSize': thumbSize,
      },
      options: Options(sendTimeout: const Duration(seconds: 60)),
    );
    return UploadImage.fromJson(data);
  }

  /// POST /video/upload。对齐 video-upload.vue。
  Future<UploadVideo> uploadVideo(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final data = await _c.post<Map<String, dynamic>>(
      '/video/upload',
      data: form,
      options: Options(sendTimeout: const Duration(minutes: 3)),
    );
    return UploadVideo.fromJson(data);
  }

  /// POST /file/upload。带 X-File-Upload:v2 取 {fileId,url}；无该头时服务端仍可能返回 url 字符串。
  Future<UploadFile> uploadFile(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: p.basename(filePath),
      ),
    });
    final data = await _c.post<dynamic>(
      '/file/upload',
      data: form,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        headers: const {'X-File-Upload': 'v2'},
      ),
    );
    return UploadFile.fromResponse(data);
  }
}
