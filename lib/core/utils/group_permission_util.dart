import '../../core/enums/message_status.dart';
import '../../core/enums/message_type.dart';
import '../../models/group.dart';
import '../../models/group_member.dart';

/// 群权限与成员选择规则。对齐 group-info.vue / group-setting.vue。
abstract final class GroupPermissionUtil {
  /// 群未退且未解散，可执行成员内操作。
  static bool isActiveGroup(Group group) => !group.quit && !group.dissolve;

  static bool isOwner({
    required int? mineId,
    required int? ownerId,
  }) =>
      mineId != null && ownerId != null && mineId == ownerId;

  static bool isManager({
    required int? mineId,
    required List<GroupMember> members,
  }) {
    if (mineId == null) return false;
    for (final m in members) {
      if (m.userId == mineId && m.isManager) return true;
    }
    return false;
  }

  static List<int> managerIds(List<GroupMember> members) =>
      members.where((m) => m.isManager).map((m) => m.userId).toList();

  /// 仅群主可管理群管理员（添加/移除）。
  static bool canManageManagers({
    required int? mineId,
    required int? ownerId,
  }) =>
      isOwner(mineId: mineId, ownerId: ownerId);

  /// 群主或管理员可进入群设置页。
  static bool canAccessGroupSetting({
    required Group group,
    required List<GroupMember> members,
    required int? mineId,
  }) =>
      isActiveGroup(group) &&
      showManagerTools(group: group, members: members, mineId: mineId);

  /// 群主可进入群管理员页。
  static bool canAccessGroupManager({
    required Group group,
    required int? mineId,
  }) =>
      isActiveGroup(group) &&
      canManageManagers(mineId: mineId, ownerId: group.ownerId);

  /// 在群内且具备邀请权限。
  static bool canInviteMembers({
    required Group group,
    required List<GroupMember> members,
    required int? mineId,
  }) =>
      isActiveGroup(group) &&
      canInvite(group: group, members: members, mineId: mineId);

  /// 移除成员选择器 hideIds（群主与自己；非群主额外隐藏管理员）。
  static List<int> removeMemberSelectorHideIds({
    required Group group,
    required List<GroupMember> members,
    required int mineId,
  }) =>
      muteSelectorHideIds(group: group, members: members, mineId: mineId);

  static bool canInvite({
    required Group group,
    required List<GroupMember> members,
    required int? mineId,
  }) =>
      isActiveGroup(group) &&
      (isOwner(mineId: mineId, ownerId: group.ownerId) ||
          isManager(mineId: mineId, members: members) ||
          group.isAllowInvite);

  static bool canShareCard({
    required Group group,
    required List<GroupMember> members,
    required int? mineId,
  }) =>
      isActiveGroup(group) &&
      (isOwner(mineId: mineId, ownerId: group.ownerId) ||
          isManager(mineId: mineId, members: members) ||
          group.isAllowShareCard);

  static bool showManagerTools({
    required Group group,
    required List<GroupMember> members,
    required int? mineId,
  }) =>
      isActiveGroup(group) &&
      (isOwner(mineId: mineId, ownerId: group.ownerId) ||
          isManager(mineId: mineId, members: members));

  /// 成员宫格默认展示数量（含工具格占位）。
  static int memberGridShowMax({
    required Group group,
    required List<GroupMember> members,
    required int? mineId,
  }) {
    var idx = 10;
    if (!group.quit && !group.dissolve && canInvite(group: group, members: members, mineId: mineId)) {
      idx--;
    }
    if (showManagerTools(group: group, members: members, mineId: mineId)) {
      idx -= 3;
    }
    return idx;
  }

  /// 禁言选择器 hideIds（群主与自己；非群主额外隐藏管理员）。
  static List<int> muteSelectorHideIds({
    required Group group,
    required List<GroupMember> members,
    required int mineId,
  }) {
    var hideIds = <int>[group.ownerId ?? -1, mineId];
    if (!isOwner(mineId: mineId, ownerId: group.ownerId)) {
      hideIds = [...hideIds, ...managerIds(members)];
    }
    return hideIds;
  }

  /// 已禁言成员 lockedIds。
  static List<int> mutedMemberLockedIds(List<GroupMember> members) =>
      members.where((m) => m.isMuted).map((m) => m.userId).toList();

  /// 过滤掉已是禁言状态的选中成员。
  static List<int> filterNewMuteTargets(
    List<int> selected,
    List<int> alreadyMuted,
  ) =>
      selected.where((id) => !alreadyMuted.contains(id)).toList();

  /// 取消禁言时仅保留当前处于禁言状态的成员。
  static List<int> filterUnmuteTargets(
    List<int> selected,
    List<GroupMember> members,
  ) {
    final muted = mutedMemberLockedIds(members).toSet();
    return selected.where(muted.contains).toList();
  }

  /// 取消禁言选择器 hideIds（未禁言成员；非群主额外隐藏管理员）。
  static List<int> unmuteSelectorHideIds({
    required Group group,
    required List<GroupMember> members,
    required int? mineId,
  }) {
    var hideIds =
        members.where((m) => !m.isMuted).map((m) => m.userId).toList();
    if (!isOwner(mineId: mineId, ownerId: group.ownerId)) {
      hideIds = [...hideIds, ...managerIds(members)];
    }
    return hideIds;
  }
}

/// 新消息提示音触发条件。对齐 message_dispatcher `_maybePlayTipForMessage`。
bool shouldPlayMessageTipSound({
  required bool audioTipEnabled,
  required bool selfSend,
  required bool isDnd,
  required int messageType,
  required int? status,
}) {
  if (!audioTipEnabled) return false;
  if (selfSend || isDnd) return false;
  if (!MessageType.isNormal(messageType)) return false;
  if (status == MessageStatus.readed) return false;
  return true;
}

/// 群设置 API 请求体（与 uniapp 字段名对齐，便于契约测）。
abstract final class GroupSettingApiBody {
  static Map<String, dynamic> allMuted({
    required int groupId,
    required bool isMuted,
  }) =>
      {'id': groupId, 'isMuted': isMuted};

  static Map<String, dynamic> allowInvite({
    required int groupId,
    required bool isAllowInvite,
  }) =>
      {'groupId': groupId, 'isAllowInvite': isAllowInvite};

  static Map<String, dynamic> allowShareCard({
    required int groupId,
    required bool isAllowShareCard,
  }) =>
      {'groupId': groupId, 'isAllowShareCard': isAllowShareCard};

  static Map<String, dynamic> memberMuted({
    required int groupId,
    required List<int> userIds,
    required bool isMuted,
  }) =>
      {'groupId': groupId, 'userIds': userIds, 'isMuted': isMuted};
}
