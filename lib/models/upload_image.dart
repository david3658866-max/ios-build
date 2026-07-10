import 'package:json_annotation/json_annotation.dart';

part 'upload_image.g.dart';

/// 图片上传结果。对应后端 UploadImageVO。
@JsonSerializable()
class UploadImage {
  const UploadImage({
    this.fileId,
    required this.originUrl,
    this.thumbUrl,
    this.previewUrl,
    this.width = 0,
    this.height = 0,
  });

  final int? fileId;
  final String originUrl;
  final String? thumbUrl;
  final String? previewUrl;
  final int width;
  final int height;

  /// 即时显示用缩略/预览，对齐 uniapp previewUrl || thumbUrl。
  String? get displayUrl => previewUrl ?? thumbUrl;

  factory UploadImage.fromJson(Map<String, dynamic> json) =>
      _$UploadImageFromJson(json);

  Map<String, dynamic> toJson() => _$UploadImageToJson(this);
}
