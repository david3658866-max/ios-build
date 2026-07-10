import '../../models/group_member.dart';

/// 群聊导航标题。对齐 chat-box.vue `群名(N)`。
String groupChatNavTitle(String? showName, Iterable<GroupMember> members) {
  final title = showName ?? '聊天';
  if (members.isEmpty) return title;
  final size = members.where((m) => !m.quit).length;
  return '$title($size)';
}
