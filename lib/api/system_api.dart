import '../core/http/dio_client.dart';

/// 系统 / 音视频信息接口。对应后端 SystemController + Webrtc*Controller。
/// 这些返回结构（SystemConfigVO/WebrtcInfoVO）暂以 Map 暴露，按需再建模型。
class SystemApi {
  SystemApi(this._c);

  final DioClient _c;

  /// 系统配置。GET /system/config。
  Future<Map<String, dynamic>> config() =>
      _c.get<Map<String, dynamic>>('/system/config');

  /// 版本检测。GET /system/checkVersion?version=。
  Future<Map<String, dynamic>> checkVersion(String version) =>
      _c.get<Map<String, dynamic>>('/system/checkVersion',
          query: {'version': version});

  /// 单聊通话信息（含 isChating）。GET /webrtc/private/info?uid=。
  Future<Map<String, dynamic>> webrtcPrivateInfo(int uid) =>
      _c.get<Map<String, dynamic>>('/webrtc/private/info', query: {'uid': uid});

  /// 群聊通话信息（含 userInfos）。GET /webrtc/group/info?groupId=。
  Future<Map<String, dynamic>> webrtcGroupInfo(int groupId) =>
      _c.get<Map<String, dynamic>>('/webrtc/group/info',
          query: {'groupId': groupId});
}
