import 'dart:convert';

import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';

/// 系统通知展示字段解析。content 存 JSON（title/coverUrl/intro），兼容旧纯文本。
class SystemMessageView {
  const SystemMessageView({
    this.title,
    this.coverUrl,
    this.intro,
  });

  final String? title;
  final String? coverUrl;
  final String? intro;

  static SystemMessageView? fromMessage(Message msg) {
    if (msg.type != MessageType.systemMessage) return null;
    final raw = msg.content;
    if (raw == null || raw.isEmpty) {
      return const SystemMessageView();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SystemMessageView(
        title: map['title'] as String?,
        coverUrl: map['coverUrl'] as String?,
        intro: map['intro'] as String? ?? map['content'] as String?,
      );
    } catch (_) {
      return SystemMessageView(intro: raw, title: raw);
    }
  }
}
