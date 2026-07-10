import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../api/file_api.dart';
import '../core/utils/chat_media_util.dart';
import '../models/upload_image.dart';
import '../models/upload_video.dart';

/// 聊天附件上传。对齐 uniapp image/file/video-upload 组件。
class UploadService {
  UploadService(this._fileApi);

  final FileApi _fileApi;

  /// 聊天图片上传（非永久、缩略图 50px，与 uniapp 默认一致）。
  Future<UploadImage> uploadChatImage(String filePath) {
    return _fileApi.uploadImage(
      filePath,
      isPermanent: ChatMediaUtil.imageIsPermanent,
      thumbSize: ChatMediaUtil.imageThumbSize,
    );
  }

  Future<UploadVideo> uploadChatVideo(String filePath) =>
      _fileApi.uploadVideo(filePath);

  Future<String> uploadChatFile(String filePath) =>
      _fileApi.uploadFile(filePath);
}

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.read(fileApiProvider));
});
