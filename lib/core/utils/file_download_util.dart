import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// 下载远程文件并尝试用系统应用打开。对齐 chat-message-item onDownloadFile。
abstract final class FileDownloadUtil {
  /// 构建代理下载 URL（对齐 uniapp `/file/download?fileId|fileUrl`）。
  static String buildDownloadUrl({
    required String apiBaseUrl,
    String? fileId,
    String? fileUrl,
  }) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    if (fileId != null && fileId.isNotEmpty) {
      return '$base/file/download?fileId=$fileId';
    }
    if (fileUrl != null && fileUrl.isNotEmpty) {
      return '$base/file/download?fileUrl=${Uri.encodeComponent(fileUrl)}';
    }
    return '';
  }

  static Future<String?> downloadAndOpen({
    required String apiBaseUrl,
    String? fileId,
    String? fileUrl,
    String? fileName,
    String? accessToken,
    void Function(int progress)? onProgress,
  }) async {
    final downloadUrl = buildDownloadUrl(
      apiBaseUrl: apiBaseUrl,
      fileId: fileId,
      fileUrl: fileUrl,
    );
    if (downloadUrl.isEmpty) return '文件信息不完整';

    try {
      final dir = await getTemporaryDirectory();
      final name = fileName ?? _nameFromUrl(fileUrl ?? downloadUrl);
      final path = '${dir.path}/$name';
      final headers = <String, dynamic>{};
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['accessToken'] = accessToken;
      }
      await Dio().download(
        downloadUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total <= 0 || onProgress == null) return;
          onProgress((received * 100 / total).round().clamp(0, 100));
        },
        options: Options(headers: headers),
      );
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        return result.message;
      }
      return null;
    } catch (e) {
      return '文件下载失败';
    }
  }

  static String _nameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'download';
    final seg = uri.pathSegments;
    if (seg.isEmpty) return 'download';
    return seg.last;
  }
}
