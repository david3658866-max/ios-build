import 'package:flutter/material.dart';

import '../../core/enums/message_status.dart';
import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/quote_message_util.dart';
import '../im_long_press_menu.dart';

/// 长按消息菜单项。
class ChatMessageMenuItem {
  const ChatMessageMenuItem({
    required this.key,
    required this.label,
    this.danger = false,
  });

  final String key;
  final String label;
  final bool danger;
}

/// 构建长按菜单项。对齐 chat-message-item.vue `menuItems` / `quoteItems`。
abstract final class ChatMessageMenuBuilder {
  ChatMessageMenuBuilder._();

  static List<ChatMessageMenuItem> forMessage({
    required Message msg,
    required bool canRecall,
    required bool canTop,
  }) {
    if (msg.type == MessageType.tipTime || msg.type == MessageType.tipText) {
      return const [];
    }
    if (msg.status == MessageStatus.recall) return const [];

    final items = <ChatMessageMenuItem>[];
    if (msg.type == MessageType.text) {
      items.add(const ChatMessageMenuItem(key: 'COPY', label: '复制'));
    }
    if (msg.status == MessageStatus.failed && msg.type == MessageType.text) {
      items.add(const ChatMessageMenuItem(key: 'RESEND', label: '重发'));
      items.add(const ChatMessageMenuItem(key: 'EDIT_RESEND', label: '编辑后重发'));
    }
    if (msg.id != null) {
      if (canRecall) {
        items.add(const ChatMessageMenuItem(key: 'RECALL', label: '撤回'));
      }
      if (QuoteMessageUtil.isNormalType(msg.type)) {
        items.add(const ChatMessageMenuItem(key: 'QUOTE', label: '引用'));
        items.add(const ChatMessageMenuItem(key: 'FORWARD', label: '转发'));
      }
      if (canTop) {
        items.add(const ChatMessageMenuItem(key: 'TOP', label: '置顶'));
      }
    }

    items.add(
      const ChatMessageMenuItem(key: 'DELETE', label: '删除', danger: true),
    );

    if (msg.type == MessageType.file) {
      items.add(const ChatMessageMenuItem(key: 'DOWNLOAD', label: '下载并打开'));
    }

    return items;
  }

  static List<ChatMessageMenuItem> forQuote(Message msg) {
    final quote = QuoteMessageUtil.parse(msg.quoteMessage);

    if (quote == null || quote.status == MessageStatus.recall) {
      return const [];
    }

    return const [ChatMessageMenuItem(key: 'LOCATE_QUOTE', label: '定位到原消息')];
  }

  static List<ImLongPressMenuItem> toLongPressItems(
    List<ChatMessageMenuItem> items,
  ) => items
      .map(
        (item) => ImLongPressMenuItem(
          key: item.key,

          name: item.label,

          danger: item.danger,
        ),
      )
      .toList();
}

/// 长按消息弹出菜单。对齐 long-press-menu.vue。

abstract final class ChatMessageMenu {
  ChatMessageMenu._();

  static Future<String?> show(
    BuildContext context, {

    required List<ChatMessageMenuItem> items,

    required Offset anchor,
  }) {
    if (items.isEmpty) return Future.value(null);

    return ImLongPressMenu.show(
      context,

      anchor: anchor,

      items: ChatMessageMenuBuilder.toLongPressItems(items),
    );
  }
}
