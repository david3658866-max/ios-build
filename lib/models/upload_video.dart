import 'package:json_annotation/json_annotation.dart';

part 'upload_video.g.dart';

/// 视频上传结果。对应后端 UploadVideoVO。
@JsonSerializable()
class UploadVideo {
  const UploadVideo({
    required this.videoUrl,
    this.coverUrl,
    this.width = 0,
    this.height = 0,
  });

  final String videoUrl;
  final String? coverUrl;
  final int width;
  final int height;

  factory UploadVideo.fromJson(Map<String, dynamic> json) =>
      _$UploadVideoFromJson(json);

  Map<String, dynamic> toJson() => _$UploadVideoToJson(this);
}
