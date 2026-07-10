import '../../models/group_member.dart';

/// 群聊消息发送者角色。对齐 chat-message-item uni-tag。
enum GroupSenderRole { owner, manager }

/// 根据群信息与成员列表解析发送者角色标签。
Set<GroupSenderRole> groupSenderRoles({
  required int? ownerId,
  required int sendId,
  required Iterable<GroupMember> members,
}) {
  final roles = <GroupSenderRole>{};
  if (ownerId != null && ownerId == sendId) {
    roles.add(GroupSenderRole.owner);
  }
  for (final m in members) {
    if (m.userId == sendId && m.isManager) {
      roles.add(GroupSenderRole.manager);
      break;
    }
  }
  return roles;
}
