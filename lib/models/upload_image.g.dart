// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadImage _$UploadImageFromJson(Map<String, dynamic> json) => UploadImage(
  fileId: (json['fileId'] as num?)?.toInt(),
  originUrl: json['originUrl'] as String,
  thumbUrl: json['thumbUrl'] as String?,
  previewUrl: json['previewUrl'] as String?,
  width: (json['width'] as num?)?.toInt() ?? 0,
  height: (json['height'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UploadImageToJson(UploadImage instance) =>
    <String, dynamic>{
      'fileId': instance.fileId,
      'originUrl': instance.originUrl,
      'thumbUrl': instance.thumbUrl,
      'previewUrl': instance.previewUrl,
      'width': instance.width,
      'height': instance.height,
    };
