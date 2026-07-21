import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/message_status.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/utils/group_permission_util.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_member.dart';

Group _group({
  int id = 100,
  int? ownerId = 1,
  bool quit = false,
  bool dissolve = false,
  bool isAllowInvite = false,
  bool isAllowShareCard = false,
}) =>
    Group(
      id: id,
      name: 'G',
      ownerId: ownerId,
      quit: quit,
      dissolve: dissolve,
      isAllowInvite: isAllowInvite,
      isAllowShareCard: isAllowShareCard,
    );

const _members = [
  GroupMember(userId: 1, showNickName: '群主', isManager: false, isMuted: false),
  GroupMember(userId: 2, showNickName: '管理员', isManager: true, isMuted: false),
  GroupMember(userId: 3, showNickName: '成员A', isManager: false, isMuted: true),
  GroupMember(userId: 4, showNickName: '成员B', isManager: false, isMuted: false),
];

void main() {
  group('GroupPermissionUtil', () {
    test('群主可邀请；普通成员看 isAllowInvite', () {
      expect(
        GroupPermissionUtil.canInvite(
          group: _group(isAllowInvite: false),
          members: _members,
          mineId: 1,
        ),
        isTrue,
      );
      expect(
        GroupPermissionUtil.canInvite(
          group: _group(isAllowInvite: true),
          members: _members,
          mineId: 4,
        ),
        isTrue,
      );
      expect(
        GroupPermissionUtil.canInvite(
          group: _group(isAllowInvite: false),
          members: _members,
          mineId: 4,
        ),
        isFalse,
      );
    });

    test('禁言 hideIds 非群主含管理员', () {
      final hide = GroupPermissionUtil.muteSelectorHideIds(
        group: _group(),
        members: _members,
        mineId: 2,
      );
      expect(hide, containsAll([1, 2]));
      expect(hide, contains(2)); // 管理员 id 也在 hide 里（另一管理员）
    });

    test('移除成员 hideIds 与禁言规则一致', () {
      final hide = GroupPermissionUtil.removeMemberSelectorHideIds(
        group: _group(),
        members: _members,
        mineId: 2,
      );
      expect(
        hide,
        GroupPermissionUtil.muteSelectorHideIds(
          group: _group(),
          members: _members,
          mineId: 2,
        ),
      );
    });

    test('仅群主可管理群管理员', () {
      expect(
        GroupPermissionUtil.canManageManagers(mineId: 1, ownerId: 1),
        isTrue,
      );
      expect(
        GroupPermissionUtil.canManageManagers(mineId: 2, ownerId: 1),
        isFalse,
      );
    });

    test('群主或管理员可进入群设置', () {
      final group = _group();
      expect(
        GroupPermissionUtil.canAccessGroupSetting(
          group: group,
          members: _members,
          mineId: 1,
        ),
        isTrue,
      );
      expect(
        GroupPermissionUtil.canAccessGroupSetting(
          group: group,
          members: _members,
          mineId: 2,
        ),
        isTrue,
      );
      expect(
        GroupPermissionUtil.canAccessGroupSetting(
          group: group,
          members: _members,
          mineId: 4,
        ),
        isFalse,
      );
      expect(
        GroupPermissionUtil.canAccessGroupSetting(
          group: _group(quit: true),
          members: _members,
          mineId: 1,
        ),
        isFalse,
      );
    });

    test('禁言 lockedIds 与 filterNewMuteTargets', () {
      final locked = GroupPermissionUtil.mutedMemberLockedIds(_members);
      expect(locked, [3]);
      expect(
        GroupPermissionUtil.filterNewMuteTargets([3, 4], locked),
        [4],
      );
    });

    test('取消禁言 filterUnmuteTargets 仅保留已禁言成员', () {
      expect(
        GroupPermissionUtil.filterUnmuteTargets([3, 4], _members),
        [3],
      );
    });

    test('取消禁言 hideIds 隐藏未禁言成员', () {
      final hide = GroupPermissionUtil.unmuteSelectorHideIds(
        group: _group(),
        members: _members,
        mineId: 1,
      );
      expect(hide, containsAll([1, 2, 4]));
      expect(hide, isNot(contains(3)));
    });

    test('取消禁言 hideIds 非群主额外隐藏管理员', () {
      final hide = GroupPermissionUtil.unmuteSelectorHideIds(
        group: _group(),
        members: _members,
        mineId: 2,
      );
      expect(hide, containsAll([1, 2, 4]));
      expect(hide, isNot(contains(3)));
    });

    test('已解散群不可邀请/管理', () {
      final dissolved = _group(dissolve: true);
      expect(
        GroupPermissionUtil.canInvite(
          group: dissolved,
          members: _members,
          mineId: 1,
        ),
        isFalse,
      );
      expect(
        GroupPermissionUtil.canAccessGroupManager(group: dissolved, mineId: 1),
        isFalse,
      );
    });

    test('memberGridShowMax 工具格占位', () {
      expect(
        GroupPermissionUtil.memberGridShowMax(
          group: _group(isAllowInvite: true),
          members: _members,
          mineId: 1,
        ),
        6,
      );
    });
  });

  group('GroupSettingApiBody', () {
    test('全员禁言 body 字段 id/isMuted', () {
      expect(
        GroupSettingApiBody.allMuted(groupId: 100, isMuted: true),
        {'id': 100, 'isMuted': true},
      );
    });

    test('成员禁言 body', () {
      expect(
        GroupSettingApiBody.memberMuted(
          groupId: 100,
          userIds: [4],
          isMuted: true,
        ),
        {'groupId': 100, 'userIds': [4], 'isMuted': true},
      );
    });
  });

  group('shouldPlayMessageTipSound', () {
    test('开启且普通消息播放', () {
      expect(
        shouldPlayMessageTipSound(
          audioTipEnabled: true,
          selfSend: false,
          isDnd: false,
          messageType: MessageType.text,
          status: MessageStatus.delivered,
        ),
        isTrue,
      );
    });

    test('自己发送/免打扰/非普通消息不播放', () {
      expect(
        shouldPlayMessageTipSound(
          audioTipEnabled: true,
          selfSend: true,
          isDnd: false,
          messageType: MessageType.text,
          status: MessageStatus.delivered,
        ),
        isFalse,
      );
      expect(
        shouldPlayMessageTipSound(
          audioTipEnabled: true,
          selfSend: false,
          isDnd: true,
          messageType: MessageType.text,
          status: MessageStatus.delivered,
        ),
        isFalse,
      );
      expect(
        shouldPlayMessageTipSound(
          audioTipEnabled: true,
          selfSend: false,
          isDnd: false,
          messageType: MessageType.tipText,
          status: MessageStatus.delivered,
        ),
        isFalse,
      );
    });
  });
}
