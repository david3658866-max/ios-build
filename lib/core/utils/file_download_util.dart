import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// 下载远程文件并尝试用系统应用打开。对齐 chat-message-item onDownloadFile。
abstract final class FileDownloadUtil {
  /// 构建鉴权代理 URL（`/file/download`）。
  /// [role]：origin|thumb|preview|cover。
  /// img/video 可将 [accessToken] 放进 query（服务端对 `/file/download` 特判）。
  static String buildDownloadUrl({
    required String apiBaseUrl,
    String? fileId,
    String? fileUrl,
    String role = 'origin',
    String? accessToken,
  }) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    final params = <String, String>{};
    if (fileId != null && fileId.isNotEmpty) {
      params['fileId'] = fileId;
    } else if (fileUrl != null && fileUrl.isNotEmpty) {
      params['fileUrl'] = fileUrl;
    } else {
      return '';
    }
    if (role.isNotEmpty) {
      params['role'] = role;
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      params['accessToken'] = accessToken;
    }
    final qs = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$base/file/download?$qs';
  }

  /// 聊天媒体展示用：优先代理；[preferDirect]/true` 或无法拼代理时回退直链。
  /// 头像/静态路径不改写。
  static String toAuthedMediaUrl({
    required String apiBaseUrl,
    String? accessToken,
    String? fileId,
    String? fileUrl,
    String role = 'origin',
    bool preferDirect = false,
  }) {
    final raw = (fileUrl ?? '').trim();
    if (preferDirect && raw.isNotEmpty) {
      return raw;
    }
    if (_shouldSkipProxy(raw) && (fileId == null || fileId.isEmpty)) {
      return raw;
    }
    final proxied = buildDownloadUrl(
      apiBaseUrl: apiBaseUrl,
      fileId: fileId,
      fileUrl: raw.isEmpty ? null : raw,
      role: role,
      accessToken: accessToken,
    );
    if (proxied.isNotEmpty) {
      return proxied;
    }
    return raw;
  }

  static bool _shouldSkipProxy(String url) {
    if (url.isEmpty) return true;
    if (url.contains('/file/download')) return true;
    if (url.contains('/static/avatar') ||
        url.contains('/api/avatar') ||
        url.contains('/avatar/')) {
      return true;
    }
    return false;
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
      role: 'origin',
      accessToken: accessToken,
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
