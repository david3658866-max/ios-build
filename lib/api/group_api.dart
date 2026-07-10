import '../core/http/dio_client.dart';
import '../models/group.dart';
import '../models/group_member.dart';
import 'api_helpers.dart';

/// 群组接口。对应后端 GroupController。
class GroupApi {
  GroupApi(this._c);

  final DioClient _c;

  /// 群列表。GET /group/list。
  Future<List<Group>> list() async {
    final data = await _c.get<dynamic>('/group/list');
    return mapList(data, Group.fromJson);
  }

  /// 群详情。GET /group/find/{id}。
  Future<Group> find(int id) async {
    final data = await _c.get<Map<String, dynamic>>('/group/find/$id');
    return Group.fromJson(data);
  }

  /// 创建群。POST /group/create（body: GroupVO）→ Group。
  Future<Group> create(Map<String, dynamic> body) async {
    final data = await _c.post<Map<String, dynamic>>('/group/create', data: body);
    return Group.fromJson(data);
  }

  /// 修改群。PUT /group/modify（body: GroupVO）→ Group。
  Future<Group> modify(Map<String, dynamic> body) async {
    final data = await _c.put<Map<String, dynamic>>('/group/modify', data: body);
    return Group.fromJson(data);
  }

  /// 群成员（带版本增量）。GET /group/members/{id}?version=。
  Future<List<GroupMember>> members(int groupId, {int version = 0}) async {
    final data = await _c.get<dynamic>('/group/members/$groupId',
        query: {'version': version});
    return mapList(data, GroupMember.fromJson);
  }

  /// 在线成员 id。GET /group/members/online/{id}。
  Future<List<int>> onlineMemberIds(int groupId) async {
    final data = await _c.get<dynamic>('/group/members/online/$groupId');
    return asIntList(data);
  }

  /// 邀请入群。POST /group/invite（body: GroupInviteDTO）。
  Future<void> invite(Map<String, dynamic> body) =>
      _c.post<dynamic>('/group/invite', data: body);

  /// 移除成员。DELETE /group/members/remove（body: GroupMemberRemoveDTO）。
  Future<void> removeMembers(Map<String, dynamic> body) =>
      _c.delete<dynamic>('/group/members/remove', data: body);

  /// 加入群。POST /group/join/{id} → Group。
  Future<Group> join(int groupId) async {
    final data = await _c.post<Map<String, dynamic>>('/group/join/$groupId');
    return Group.fromJson(data);
  }

  /// 退群。DELETE /group/quit/{id}。
  Future<void> quit(int groupId) => _c.delete<dynamic>('/group/quit/$groupId');

  /// 解散群。DELETE /group/delete/{id}。
  Future<void> dissolve(int groupId) =>
      _c.delete<dynamic>('/group/delete/$groupId');

  /// 群免打扰。PUT /group/dnd（body: {groupId, isDnd}）。
  Future<void> setDnd(int groupId, bool isDnd) =>
      _c.put<dynamic>('/group/dnd', data: {'groupId': groupId, 'isDnd': isDnd});

  /// 群会话置顶。PUT /group/top（body: {groupId, isTop}）。
  Future<void> setTop(int groupId, bool isTop) =>
      _c.put<dynamic>('/group/top', data: {'groupId': groupId, 'isTop': isTop});

  /// 全员禁言。PUT /group/muted（body: {id, isMuted}，对齐 uniapp group-setting）。
  Future<void> setGroupMuted(int groupId, bool isMuted) =>
      _c.put<dynamic>('/group/muted', data: {'id': groupId, 'isMuted': isMuted});

  /// 允许普通成员邀请。PUT /group/allowInvite。
  Future<void> setAllowInvite(int groupId, bool isAllowInvite) => _c.put<dynamic>(
        '/group/allowInvite',
        data: {'groupId': groupId, 'isAllowInvite': isAllowInvite},
      );

  /// 允许普通成员分享名片。PUT /group/allowShareCard。
  Future<void> setAllowShareCard(int groupId, bool isAllowShareCard) =>
      _c.put<dynamic>(
        '/group/allowShareCard',
        data: {'groupId': groupId, 'isAllowShareCard': isAllowShareCard},
      );

  /// 全员禁言（Map 形式，兼容旧调用）。
  Future<void> setGroupMutedMap(Map<String, dynamic> body) =>
      _c.put<dynamic>('/group/muted', data: body);

  /// 成员禁言。PUT /group/members/muted（body: GroupMemberMutedDTO）。
  Future<void> setMemberMuted(Map<String, dynamic> body) =>
      _c.put<dynamic>('/group/members/muted', data: body);

  /// 设置群置顶消息。POST /group/setTopMessage/{groupId}?messageId=。
  Future<void> setTopMessage(int groupId, int messageId) => _c.post<dynamic>(
      '/group/setTopMessage/$groupId', query: {'messageId': messageId});

  /// 移除群置顶消息。DELETE /group/removeTopMessage/{groupId}。
  Future<void> removeTopMessage(int groupId) =>
      _c.delete<dynamic>('/group/removeTopMessage/$groupId');

  /// 隐藏群置顶消息（普通成员）。DELETE /group/hideTopMessage/{groupId}。
  Future<void> hideTopMessage(int groupId) =>
      _c.delete<dynamic>('/group/hideTopMessage/$groupId');

  /// 添加管理员。POST /group/manager/add（body: GroupManagerDTO）。
  Future<void> addManager(Map<String, dynamic> body) =>
      _c.post<dynamic>('/group/manager/add', data: body);

  /// 移除管理员。DELETE /group/manager/remove（body: GroupManagerDTO）。
  Future<void> removeManager(Map<String, dynamic> body) =>
      _c.delete<dynamic>('/group/manager/remove', data: body);
}
