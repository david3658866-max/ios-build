import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/chat_media_util.dart';
import 'package:vortek/core/utils/file_download_util.dart';

void main() {
  group('FileDownloadUtil', () {
    test('buildDownloadUrl 优先 fileId', () {
      expect(
        FileDownloadUtil.buildDownloadUrl(
          apiBaseUrl: 'https://example.com/api',
          fileId: '42',
          fileUrl: 'https://cdn/a.pdf',
        ),
        'https://example.com/api/file/download?fileId=42',
      );
    });

    test('buildDownloadUrl 回退 fileUrl 编码', () {
      expect(
        FileDownloadUtil.buildDownloadUrl(
          apiBaseUrl: 'https://example.com/api/',
          fileUrl: 'https://cdn/x y.pdf',
        ),
        'https://example.com/api/file/download?fileUrl=${Uri.encodeComponent('https://cdn/x y.pdf')}',
      );
    });

    test('buildDownloadUrl 无参数返回空', () {
      expect(
        FileDownloadUtil.buildDownloadUrl(apiBaseUrl: 'https://example.com/api'),
        '',
      );
    });
  });

  group('ChatMediaUtil', () {
    test('相册多选上限 9', () {
      expect(ChatMediaUtil.maxAlbumImageCount, 9);
    });
    test('文件多选上限 9', () {
      expect(ChatMediaUtil.maxFileCount, 9);
    });
    test('媒体大小限制对齐 uniapp', () {
      expect(ChatMediaUtil.maxImageBytes, 10 * 1024 * 1024);
      expect(ChatMediaUtil.maxFileBytes, 10 * 1024 * 1024);
      expect(ChatMediaUtil.maxVideoBytes, 50 * 1024 * 1024);
    });
    test('上传参数对齐 image-upload 默认', () {
      expect(ChatMediaUtil.imageThumbSize, 50);
      expect(ChatMediaUtil.imageIsPermanent, isFalse);
    });
  });
}
