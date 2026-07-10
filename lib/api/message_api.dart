import '../core/http/dio_client.dart';
import '../core/utils/chat_message_window_util.dart';
import '../models/chat_session_summary.dart';
import '../models/group_message.dart';
import '../models/group_message_dto.dart';
import '../models/private_message.dart';
import '../models/private_message_dto.dart';
import '../models/system_message.dart';
import 'api_helpers.dart';

/// 消息接口。对应后端 Private/Group/System/OfflineMessageController。
class MessageApi {
  MessageApi(this._c);

  final DioClient _c;

  // ---- 发送 ----

  /// 发私聊消息。POST /message/private/send → PrivateMessage。
  Future<PrivateMessage> sendPrivate(PrivateMessageDTO dto) async {
    final data = await _c.post<Map<String, dynamic>>('/message/private/send',
        data: dto.toJson());
    return PrivateMessage.fromJson(data);
  }

  /// 发群聊消息。POST /message/group/send → GroupMessage。
  Future<GroupMessage> sendGroup(GroupMessageDTO dto) async {
    final data = await _c.post<Map<String, dynamic>>('/message/group/send',
        data: dto.toJson());
    return GroupMessage.fromJson(data);
  }

  // ---- 撤回 ----

  /// 撤回私聊。DELETE /message/private/recall/{id} → PrivateMessage。
  Future<PrivateMessage> recallPrivate(int id) async {
    final data =
        await _c.delete<Map<String, dynamic>>('/message/private/recall/$id');
    return PrivateMessage.fromJson(data);
  }

  /// 撤回群聊。DELETE /message/group/recall/{id} → GroupMessage。
  Future<GroupMessage> recallGroup(int id) async {
    final data =
        await _c.delete<Map<String, dynamic>>('/message/group/recall/$id');
    return GroupMessage.fromJson(data);
  }

  // ---- 已读 ----

  /// 标记私聊已读。PUT /message/private/readed?friendId=。
  Future<void> readedPrivate(int friendId) =>
      _c.put<dynamic>('/message/private/readed', query: {'friendId': friendId});

  /// 标记群聊已读。PUT /message/group/readed?groupId=。
  Future<void> readedGroup(int groupId) =>
      _c.put<dynamic>('/message/group/readed', query: {'groupId': groupId});

  /// 标记系统消息已读。PUT /message/system/readed?maxSeqNo=。
  Future<void> readedSystem(int maxSeqNo) =>
      _c.put<dynamic>('/message/system/readed', query: {'maxSeqNo': maxSeqNo});

  /// 私聊最大已读 id。GET /message/private/maxReadedId?friendId=。
  Future<int> maxReadedId(int friendId) async {
    final data = await _c
        .get<dynamic>('/message/private/maxReadedId', query: {'friendId': friendId});
    return asInt(data);
  }

  /// 群消息已读用户 id 列表。GET /message/group/findReadedUsers。
  Future<List<int>> findReadedUsers(int groupId, int messageId) async {
    final data = await _c.get<dynamic>('/message/group/findReadedUsers',
        query: {'groupId': groupId, 'messageId': messageId});
    return asIntList(data);
  }

  /// 群聊天记录分页。GET /message/group/history?groupId=&page=&size=。
  Future<List<GroupMessage>> groupHistory(
      int groupId, int page, int size) async {
    final data = await _c.get<dynamic>('/message/group/history',
        query: {'groupId': groupId, 'page': page, 'size': size});
    return mapList(data, GroupMessage.fromJson);
  }

  // ---- 离线 ----

  /// 离线会话摘要（首选）。GET /message/offline/sessionSummary。
  Future<List<ChatSessionSummary>> sessionSummary() async {
    final data = await _c.get<dynamic>('/message/offline/sessionSummary');
    return mapList(data, ChatSessionSummary.fromJson);
  }

  /// 全量私聊离线（降级）。GET /message/private/loadOfflineMessage?minId=。
  Future<List<PrivateMessage>> loadOfflinePrivate(int minId) async {
    final data = await _c
        .get<dynamic>('/message/private/loadOfflineMessage', query: {'minId': minId});
    return mapList(data, PrivateMessage.fromJson);
  }

  /// 全量群聊离线（降级）。GET /message/group/loadOfflineMessage?minId=。
  Future<List<GroupMessage>> loadOfflineGroup(int minId) async {
    final data = await _c
        .get<dynamic>('/message/group/loadOfflineMessage', query: {'minId': minId});
    return mapList(data, GroupMessage.fromJson);
  }

  /// 系统离线消息。GET /message/system/loadOfflineMessage?minSeqNo=。
  Future<List<SystemMessage>> loadOfflineSystem(int minSeqNo) async {
    final data = await _c.get<dynamic>('/message/system/loadOfflineMessage',
        query: {'minSeqNo': minSeqNo});
    return mapList(data, SystemMessage.fromJson);
  }

  /// 按会话拉私聊离线。GET /message/private/loadOfflineMessageByChat。
  Future<List<PrivateMessage>> loadOfflinePrivateByChat(
    int friendId,
    int minId, {
    int size = ChatMessageWindowConfig.initialPullSize,
  }) async {
    final data = await _c.get<dynamic>('/message/private/loadOfflineMessageByChat',
        query: {'friendId': friendId, 'minId': minId, 'size': size});
    return mapList(data, PrivateMessage.fromJson);
  }

  /// 私聊更早历史。GET /message/private/history。
  Future<List<PrivateMessage>> privateHistoryByChat(
    int friendId,
    int maxId, {
    int size = ChatMessageWindowConfig.preloadStep,
  }) async {
    final data = await _c.get<dynamic>('/message/private/history',
        query: {'friendId': friendId, 'maxId': maxId, 'size': size});
    return mapList(data, PrivateMessage.fromJson);
  }

  /// 按会话拉群聊离线。GET /message/group/loadOfflineMessageByChat。
  Future<List<GroupMessage>> loadOfflineGroupByChat(
    int groupId,
    int minId, {
    int size = ChatMessageWindowConfig.initialPullSize,
  }) async {
    final data = await _c.get<dynamic>('/message/group/loadOfflineMessageByChat',
        query: {'groupId': groupId, 'minId': minId, 'size': size});
    return mapList(data, GroupMessage.fromJson);
  }

  /// 群聊更早历史。GET /message/group/historyByChat。
  Future<List<GroupMessage>> groupHistoryByChat(
    int groupId,
    int maxId, {
    int size = ChatMessageWindowConfig.preloadStep,
  }) async {
    final data = await _c.get<dynamic>('/message/group/historyByChat',
        query: {'groupId': groupId, 'maxId': maxId, 'size': size});
    return mapList(data, GroupMessage.fromJson);
  }

  /// 系统消息内容。GET /message/system/content?id=。
  Future<Map<String, dynamic>> systemContent(int id) =>
      _c.get<Map<String, dynamic>>('/message/system/content', query: {'id': id});
}
