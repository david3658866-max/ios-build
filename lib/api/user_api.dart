import '../core/http/dio_client.dart';
import '../models/user.dart';
import 'api_helpers.dart';

/// 用户接口。对应后端 UserController。
class UserApi {
  UserApi(this._c);

  final DioClient _c;

  /// 当前用户信息。GET /user/self。
  Future<User> self() async {
    final data = await _c.get<Map<String, dynamic>>('/user/self');
    return User.fromJson(data);
  }

  /// 查用户。GET /user/find/{id}。
  Future<User> find(int id) async {
    final data = await _c.get<Map<String, dynamic>>('/user/find/$id');
    return User.fromJson(data);
  }

  /// 搜索用户（用户名/昵称/手机/邮箱）。GET /user/search?name=。
  Future<List<User>> search(String name) async {
    final data = await _c.get<dynamic>('/user/search', query: {'name': name});
    return mapList(data, User.fromJson);
  }

  /// 更新资料。PUT /user/update（body: UserVO）。
  Future<void> update(User user) =>
      _c.put<dynamic>('/user/update', data: user.toJson());

  /// 加好友需验证开关。PUT /user/manualApprove?enabled=。
  Future<void> setManualApprove(bool enabled) =>
      _c.put<dynamic>('/user/manualApprove', query: {'enabled': enabled});

  /// 新消息提示音开关。PUT /user/audioTip?enabled=。
  Future<void> setAudioTip(bool enabled) =>
      _c.put<dynamic>('/user/audioTip', query: {'enabled': enabled});

  /// 绑定手机。PUT /user/bindPhone（body: BindPhoneDTO）。
  Future<void> bindPhone(Map<String, dynamic> body) =>
      _c.put<dynamic>('/user/bindPhone', data: body);

  /// 绑定邮箱。PUT /user/bindEmail（body: BindEmailDTO）。
  Future<void> bindEmail(Map<String, dynamic> body) =>
      _c.put<dynamic>('/user/bindEmail', data: body);
}
