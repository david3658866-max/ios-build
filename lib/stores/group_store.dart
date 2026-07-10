import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../core/enums/chat_type.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import '../models/group_message.dart';
import 'chat_store.dart';

class GroupStore extends Notifier<List<Group>> {
  final Map<int, List<GroupMember>> _members = {};

  @override
  List<Group> build() => const [];

  List<GroupMember> membersOf(int groupId) =>
      List.unmodifiable(_members[groupId] ?? const []);

  bool isGroup(int groupId) {
    final g = byId(groupId);
    return g != null && !g.quit;
  }

  /// 加载群列表。
  Future<void> loadGroups() async {
    final groups = await ref.read(groupApiProvider).list();
    state = groups;
  }

  Group? byId(int id) {
    for (final g in state) {
      if (g.id == id) return g;
    }
    return null;
  }

  Future<Group> loadGroupDetail(int groupId) async {
    final group = await ref.read(groupApiProvider).find(groupId);
    _upsertGroup(group, preserveMembers: true);
    return group;
  }

  Future<List<GroupMember>> loadMembers(int groupId, {int version = 0}) async {
    final current = _members[groupId] ?? [];
    final maxVersion = version > 0
        ? version
        : current.fold(0, (max, m) => m.version > max ? m.version : max);

    final fetched = await ref.read(groupApiProvider).members(
          groupId,
          version: maxVersion,
        );

    List<GroupMember> merged;
    if (current.isEmpty) {
      merged = List<GroupMember>.from(fetched);
    } else {
      merged = List<GroupMember>.from(current);
      for (final m1 in fetched) {
        final idx = merged.indexWhere((m2) => m2.userId == m1.userId);
        if (idx >= 0) {
          merged[idx] = m1;
        } else {
          merged.add(m1);
        }
      }
      try {
        final onlineIds =
            await ref.read(groupApiProvider).onlineMemberIds(groupId);
        merged = merged
            .map((m) => _withOnline(m, onlineIds.contains(m.userId)))
            .toList();
      } catch (e) {
        
      }
    }

    final group = byId(groupId);
    _sortMembers(merged, ownerId: group?.ownerId);
    _members[groupId] = merged.where((m) => !m.quit).toList();
    state = [...state];
    return _members[groupId]!;
  }

  Future<void> setDnd(int groupId, bool isDnd) async {
    _patchGroup(groupId, (g) => _copyGroup(g, isDnd: isDnd));
    await ref.read(chatStoreProvider).setDnd(ChatType.group, groupId, isDnd);
    try {
      await ref.read(groupApiProvider).setDnd(groupId, isDnd);
    } catch (e) {
      _patchGroup(groupId, (g) => _copyGroup(g, isDnd: !isDnd));
      await ref.read(chatStoreProvider).setDnd(ChatType.group, groupId, !isDnd);
      rethrow;
    }
  }

  Future<void> setTop(int groupId, bool isTop) async {
    _patchGroup(groupId, (g) => _copyGroup(g, isTop: isTop));
    await ref.read(chatStoreProvider).setTop(ChatType.group, groupId, isTop);
    try {
      await ref.read(groupApiProvider).setTop(groupId, isTop);
    } catch (e) {
      _patchGroup(groupId, (g) => _copyGroup(g, isTop: !isTop));
      await ref.read(chatStoreProvider).setTop(ChatType.group, groupId, !isTop);
      rethrow;
    }
  }

  void updateTopMessage(int groupId, GroupMessage? topMessage) {
    _patchGroup(
      groupId,
      (g) => _copyGroup(g, topMessage: topMessage, replaceTopMessage: true),
    );
  }

  Future<void> setAllMuted(int groupId, bool isAllMuted) async {
    await ref.read(groupApiProvider).setGroupMuted(groupId, isAllMuted);
    _patchGroup(groupId, (g) => _copyGroup(g, isAllMuted: isAllMuted));
  }

  Future<void> setAllowInvite(int groupId, bool isAllowInvite) async {
    await ref.read(groupApiProvider).setAllowInvite(groupId, isAllowInvite);
    _patchGroup(
      groupId,
      (g) => _copyGroup(g, isAllowInvite: isAllowInvite),
    );
  }

  Future<void> setAllowShareCard(int groupId, bool isAllowShareCard) async {
    await ref.read(groupApiProvider).setAllowShareCard(
          groupId,
          isAllowShareCard,
        );
    _patchGroup(
      groupId,
      (g) => _copyGroup(g, isAllowShareCard: isAllowShareCard),
    );
  }

  /// 标记已退出群聊。
  void markQuit(int groupId) {
    _patchGroup(groupId, (g) => _copyGroup(g, quit: true));
  }

  void addGroup(Group group) {
    _upsertGroup(group);
  }

  void updateGroup(Group group) {
    _upsertGroup(group, preserveMembers: true);
  }

  void removeGroup(int groupId) => markQuit(groupId);

  void setDndLocal(int groupId, bool isDnd) {
    _patchGroup(groupId, (g) => _copyGroup(g, isDnd: isDnd));
  }

  void setTopLocal(int groupId, bool isTop) {
    _patchGroup(groupId, (g) => _copyGroup(g, isTop: isTop));
  }

  void setAllMutedLocal(int groupId, bool isAllMuted) {
    _patchGroup(groupId, (g) => _copyGroup(g, isAllMuted: isAllMuted));
  }

  void setMutedLocal(int groupId, bool isMuted) {
    _patchGroup(groupId, (g) => _copyGroup(g, isMuted: isMuted));
  }

  void _upsertGroup(Group group, {bool preserveMembers = false}) {
    final idx = state.indexWhere((g) => g.id == group.id);
    if (idx >= 0) {
      final next = [...state];
      next[idx] = group;
      state = next;
    } else {
      state = [...state, group];
      if (!preserveMembers) {
        _members.putIfAbsent(group.id, () => []);
      }
    }
  }

  void _patchGroup(int id, Group Function(Group g) patch) {
    final idx = state.indexWhere((g) => g.id == id);
    if (idx < 0) return;
    final next = [...state];
    next[idx] = patch(next[idx]);
    state = next;
  }

  void _sortMembers(List<GroupMember> members, {int? ownerId}) {
    members.sort((m1, m2) {
      if (m1.online != m2.online) return m1.online ? -1 : 1;
      if (ownerId != null) {
        if (m1.userId == ownerId) return -1;
        if (m2.userId == ownerId) return 1;
      }
      if (m1.isManager != m2.isManager) return m1.isManager ? -1 : 1;
      return 0;
    });
  }

  GroupMember _withOnline(GroupMember m, bool online) => GroupMember(
        userId: m.userId,
        showNickName: m.showNickName,
        remarkNickName: m.remarkNickName,
        headImage: m.headImage,
        companyName: m.companyName,
        isManager: m.isManager,
        isMuted: m.isMuted,
        quit: m.quit,
        online: online,
        showGroupName: m.showGroupName,
        remarkGroupName: m.remarkGroupName,
        version: m.version,
      );

  Group _copyGroup(
    Group g, {
    bool? isDnd,
    bool? isTop,
    bool? quit,
    bool? isAllMuted,
    bool? isAllowInvite,
    bool? isAllowShareCard,
    bool? isMuted,
    GroupMessage? topMessage,
    bool replaceTopMessage = false,
  }) =>
      Group(
        id: g.id,
        name: g.name,
        ownerId: g.ownerId,
        headImage: g.headImage,
        headImageThumb: g.headImageThumb,
        notice: g.notice,
        remarkNickName: g.remarkNickName,
        showNickName: g.showNickName,
        showGroupName: g.showGroupName,
        remarkGroupName: g.remarkGroupName,
        isAllMuted: isAllMuted ?? g.isAllMuted,
        isAllowInvite: isAllowInvite ?? g.isAllowInvite,
        isAllowShareCard: isAllowShareCard ?? g.isAllowShareCard,
        dissolve: g.dissolve,
        quit: quit ?? g.quit,
        isMuted: isMuted ?? g.isMuted,
        isBanned: g.isBanned,
        reason: g.reason,
        isDnd: isDnd ?? g.isDnd,
        isTop: isTop ?? g.isTop,
        topMessage: replaceTopMessage ? topMessage : g.topMessage,
      );
}

final groupStoreProvider =
    NotifierProvider<GroupStore, List<Group>>(GroupStore.new);

