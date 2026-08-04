import '../core/http/dio_client.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import 'api_helpers.dart';

/// 好友接口。对应后端 FriendController + FriendRequestController。
/// 注意：/friend/delete 与 /blacklist 服务端已关闭，故不在此封装。
class FriendApi {
  FriendApi(this._c);

  final DioClient _c;

  /// 好友列表。GET /friend/list。
  Future<List<Friend>> list() async {
    final data = await _c.get<dynamic>('/friend/list');
    return mapList(data, Friend.fromJson);
  }

  /// 查找好友。GET /friend/find/{friendId}。
  Future<Friend> find(int friendId) async {
    final data = await _c.get<Map<String, dynamic>>('/friend/find/$friendId');
    return Friend.fromJson(data);
  }

  /// 修改好友备注。PUT /friend/update/remark（body: {friendId, remarkNickName}）。
  Future<Friend> modifyRemark(int friendId, String remark) async {
    final data = await _c.put<Map<String, dynamic>>(
      '/friend/update/remark',
      data: {'friendId': friendId, 'remarkNickName': remark},
    );
    return Friend.fromJson(data);
  }

  /// 设置免打扰。PUT /friend/dnd（body: {friendId, isDnd}）。
  Future<void> setDnd(int friendId, bool isDnd) =>
      _c.put<dynamic>('/friend/dnd', data: {'friendId': friendId, 'isDnd': isDnd});

  /// 设置会话置顶。PUT /friend/top（body: {friendId, isTop}）。
  Future<void> setTop(int friendId, bool isTop) =>
      _c.put<dynamic>('/friend/top', data: {'friendId': friendId, 'isTop': isTop});

  /// 置顶私聊消息（双方可见）。POST /friend/setTopMessage/{friendId}?messageId=。
  Future<void> setTopMessage(int friendId, int messageId) => _c.post<dynamic>(
        '/friend/setTopMessage/$friendId',
        query: {'messageId': messageId},
      );

  /// 移除私聊置顶。DELETE /friend/removeTopMessage/{friendId}。
  Future<void> removeTopMessage(int friendId) =>
      _c.delete<dynamic>('/friend/removeTopMessage/$friendId');

  /// 隐藏私聊置顶（仅自己）。DELETE /friend/hideTopMessage/{friendId}。
  Future<void> hideTopMessage(int friendId) =>
      _c.delete<dynamic>('/friend/hideTopMessage/$friendId');

  // ---- 好友申请 ----

  /// 好友申请列表。GET /friend/request/list。
  Future<List<FriendRequest>> requestList() async {
    final data = await _c.get<dynamic>('/friend/request/list');
    return mapList(data, FriendRequest.fromJson);
  }

  /// 发起好友申请。POST /friend/request/apply（body: FriendRequestApplyDTO）。
  Future<FriendRequest> apply({required int friendId, String? remark}) async {
    final data = await _c.post<Map<String, dynamic>>(
      '/friend/request/apply',
      data: {'friendId': friendId, 'remark': ?remark},
    );
    return FriendRequest.fromJson(data);
  }

  /// 同意申请。POST /friend/request/approve?id=。
  Future<void> approve(int id) =>
      _c.post<dynamic>('/friend/request/approve', query: {'id': id});

  /// 拒绝申请。POST /friend/request/reject?id=。
  Future<void> reject(int id) =>
      _c.post<dynamic>('/friend/request/reject', query: {'id': id});

  /// 撤回申请。POST /friend/request/recall?id=。
  Future<void> recall(int id) =>
      _c.post<dynamic>('/friend/request/recall', query: {'id': id});
}
