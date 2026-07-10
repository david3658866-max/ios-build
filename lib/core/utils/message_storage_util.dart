import '../storage/daos/message_dao.dart';

/// 本地消息容量策略。对齐 uniapp `chatStore.fliterMessage`（H5 约 5MB 上限）。
abstract final class MessageStorageConfig {
  /// 全库消息总条数上限。
  static const int maxTotalMessages = 5000;

  /// 单会话保留的最新消息条数（首轮）。
  static const int maxPerChatMessages = 1000;
}

/// 裁剪超量历史消息，保留最新记录。
abstract final class MessageStorageUtil {
  /// 对齐 `fliterMessage(chats, 5000, 1000)` 递归减半策略。
  static Future<void> pruneMessages(
    MessageDao dao, {
    int maxTotalSize = MessageStorageConfig.maxTotalMessages,
    int maxPerChatSize = MessageStorageConfig.maxPerChatMessages,
  }) async {
    if (maxTotalSize <= 0 || maxPerChatSize <= 0) return;

    final chats = await dao.listDistinctChats();
    var remainTotal = 0;
    for (final chat in chats) {
      final count = await dao.countMessages(chat.type, chat.targetId);
      if (count > maxPerChatSize) {
        await dao.deleteOldestMessages(
          chatType: chat.type,
          targetId: chat.targetId,
          deleteCount: count - maxPerChatSize,
        );
        remainTotal += maxPerChatSize;
      } else {
        remainTotal += count;
      }
    }

    if (remainTotal > maxTotalSize && maxPerChatSize > 1) {
      await pruneMessages(
        dao,
        maxTotalSize: maxTotalSize,
        maxPerChatSize: maxPerChatSize ~/ 2,
      );
    }
  }
}
