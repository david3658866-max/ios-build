/// File upload result. Matches backend UploadFileVO.
class UploadFile {
  const UploadFile({
    required this.url,
    this.fileId,
  });

  final String url;
  final int? fileId;

  factory UploadFile.fromJson(Map<String, dynamic> json) {
    return UploadFile(
      url: (json['url'] ?? '').toString(),
      fileId: (json['fileId'] as num?)?.toInt(),
    );
  }

  /// Compatible with legacy API that returned a raw url string in `data`.
  factory UploadFile.fromResponse(dynamic data) {
    if (data is String) {
      return UploadFile(url: data);
    }
    if (data is Map<String, dynamic>) {
      return UploadFile.fromJson(data);
    }
    if (data is Map) {
      return UploadFile.fromJson(Map<String, dynamic>.from(data));
    }
    throw ArgumentError('Unexpected file upload response: $data');
  }
}