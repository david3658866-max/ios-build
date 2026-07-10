import 'dart:convert';

import '../../core/enums/message_status.dart';
import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../models/quote_message.dart';

/// 引用消息解析与预览文案。对齐 uniapp chat-box `quoteMessageText`。
abstract final class QuoteMessageUtil {
  static QuoteMessage? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return QuoteMessage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static QuoteMessage? fromMessage(Message msg) {
    if (msg.id == null) return null;
    return QuoteMessage(
      id: msg.id!,
      sendId: msg.sendId,
      content: msg.content,
      type: msg.type,
      status: msg.status,
    );
  }

  static bool isNormalType(int type) {
    return type == MessageType.text ||
        type == MessageType.image ||
        type == MessageType.file ||
        type == MessageType.audio ||
        type == MessageType.video ||
        type == MessageType.userCard ||
        type == MessageType.groupCard ||
        type == MessageType.contractCard ||
        type == MessageType.loanCard ||
        type == MessageType.productCard;
  }

  static String preview({
    required String showName,
    required int type,
    required String? content,
    int? status,
  }) {
    if (status == MessageStatus.recall) {
      return content ?? '消息已撤回';
    }
    var body = content ?? '';
    switch (type) {
      case MessageType.image:
        body = '[图片]';
      case MessageType.video:
        body = '[视频]';
      case MessageType.file:
        body = '[文件] ${_jsonField(content, 'name')}';
      case MessageType.audio:
        body = '[语音] ${_jsonField(content, 'duration')}"';
      case MessageType.userCard:
        body = '[个人名片] ${_jsonField(content, 'nickName')}';
      case MessageType.groupCard:
        body = '[群名片] ${_jsonField(content, 'groupName')}';
      case MessageType.contractCard:
        body = '[合同卡片] ${_jsonField(content, 'title')}';
      case MessageType.loanCard:
        body = '[借款卡片] ${_jsonField(content, 'title')}';
      case MessageType.productCard:
        body = '[产品卡片] ${_jsonField(content, 'title')}';
    }
    return '$showName: $body';
  }

  static String previewOfMessage(Message msg, String showName) => preview(
        showName: showName,
        type: msg.type,
        content: msg.content,
        status: msg.status,
      );

  static String previewOfQuote(QuoteMessage quote, String showName) => preview(
        showName: showName,
        type: quote.type,
        content: quote.content,
        status: quote.status,
      );

  static String _jsonField(String? raw, String key) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final map = jsonDecode(raw);
      if (map is Map && map[key] != null) return '${map[key]}';
    } catch (_) {}
    return '';
  }
}
