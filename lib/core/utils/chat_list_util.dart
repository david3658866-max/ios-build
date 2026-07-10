import '../../core/storage/app_database.dart';
import '../../core/ws/ws_event.dart';

/// 会话列表展示过滤。对齐 chat.vue isShowChat + showChats。
bool matchesChatSearch(Chat chat, String searchText) {
  if (searchText.isEmpty) return true;
  return (chat.showName ?? '').contains(searchText);
}

List<Chat> filterChatsForDisplay(
  List<Chat> chats,
  String searchText, {
  int limit = 30,
}) {
  return chats
      .where((c) => matchesChatSearch(c, searchText))
      .take(limit)
      .toList();
}

/// 消息 Tab 顶部状态条：仅离线同步时显示同步进度。
/// 已登录/本地有会话时不显示「正在初始化」（与线路 chip 探活解耦）。
String? messagesTabStatusMessage({
  required bool chatSyncLoading,
  bool isAuthenticated = false,
  // 保留参数供调用方传入，便于日志诊断；不再用于展示「正在初始化」。
  bool appInit = true,
  WsStatus? wsStatus,
  WsStatus? lineStatus,
}) {
  if (chatSyncLoading) return '正在同步最近消息…';
  return null;
}
