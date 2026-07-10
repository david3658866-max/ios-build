import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'chat_media_util.dart';

/// 聊天文件选取结果。
class ChatPickedFile {
  const ChatPickedFile({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;
}

/// 聊天文件选取。对齐 uniapp `file-upload` + lsj-upload（多选最多 9、10MB）。
abstract final class ChatFilePickerUtil {
  ChatFilePickerUtil._();

  /// 打开系统文件选择器，返回可上传的本地路径。
  static Future<List<ChatPickedFile>> pickChatFiles({
    void Function(String message)? onToast,
  }) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
      withData: true,
      dialogTitle: '选择文件',
    );
    if (result == null || result.files.isEmpty) return const [];

    final picked = <ChatPickedFile>[];
    for (final file in result.files.take(ChatMediaUtil.maxFileCount)) {
      final resolved = await _resolvePlatformFile(file);
      if (resolved == null) {
        final label = file.name.isNotEmpty ? file.name : '文件';
        onToast?.call('未能读取文件: $label');
        continue;
      }
      if (resolved.size > ChatMediaUtil.maxFileBytes) {
        onToast?.call('附件大小请勿超过10M');
        continue;
      }
      if (resolved.size <= 0) {
        onToast?.call('文件为空');
        continue;
      }
      picked.add(resolved);
    }

    if (result.files.isNotEmpty && picked.isEmpty) {
      onToast?.call('未能发送所选文件');
    }
    return picked;
  }

  static Future<ChatPickedFile?> _resolvePlatformFile(PlatformFile file) async {
    final name = _safeFileName(file.name);

    final path = file.path;
    if (path != null && path.isNotEmpty) {
      final local = File(path);
      if (await local.exists()) {
        final size = await local.length();
        return ChatPickedFile(path: path, name: name, size: size);
      }
    }

    if (file.bytes != null && file.bytes!.isNotEmpty) {
      final dir = await getTemporaryDirectory();
      final dest = File(
        p.join(
          dir.path,
          'chat_file_${DateTime.now().millisecondsSinceEpoch}_$name',
        ),
      );
      await dest.parent.create(recursive: true);
      await dest.writeAsBytes(file.bytes!, flush: true);
      return ChatPickedFile(
        path: dest.path,
        name: name,
        size: file.bytes!.length,
      );
    }

    if (file.readStream != null) {
      final dir = await getTemporaryDirectory();
      final dest = File(
        p.join(
          dir.path,
          'chat_file_${DateTime.now().millisecondsSinceEpoch}_$name',
        ),
      );
      await dest.parent.create(recursive: true);
      final sink = dest.openWrite();
      await file.readStream!.pipe(sink);
      await sink.flush();
      await sink.close();
      final size = await dest.length();
      if (size <= 0) return null;
      return ChatPickedFile(path: dest.path, name: name, size: size);
    }

    return null;
  }

  static String _safeFileName(String raw) {
    var name = raw.trim();
    if (name.isEmpty) return 'file';
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return name;
  }
}
