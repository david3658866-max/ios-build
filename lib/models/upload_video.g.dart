// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_video.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadVideo _$UploadVideoFromJson(Map<String, dynamic> json) => UploadVideo(
  videoUrl: json['videoUrl'] as String,
  coverUrl: json['coverUrl'] as String?,
  width: (json['width'] as num?)?.toInt() ?? 0,
  height: (json['height'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$UploadVideoToJson(UploadVideo instance) =>
    <String, dynamic>{
      'videoUrl': instance.videoUrl,
      'coverUrl': instance.coverUrl,
      'width': instance.width,
      'height': instance.height,
    };
