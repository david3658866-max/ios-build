import 'package:dio/dio.dart';
import 'package:vortek/core/utils/message_tmp_id.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/models/group_message_dto.dart';
import 'package:vortek/models/login_dto.dart';
import 'package:vortek/models/login_info.dart';
import 'package:vortek/models/private_message_dto.dart';

Future<void> main() async {
  final dio = Dio(BaseOptions(
    baseUrl: kDefaultLine.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
  ));
  final loginRes = await dio.post<Map<String, dynamic>>(
    '/login',
    data: LoginDTO(
      mode: 'username',
      terminal: 1,
      userName: '15222222222',
      phone: '15222222222',
      email: '',
      code: '',
      password: '123456',
      deviceId: 'probe-group-send',
      loginType: 'android',
      deviceInfo: 'Probe|Android|Test',
      clientVersion: '1.0.0',
    ).toJson(),
  );
  final loginApi = ApiResponse.fromBody(loginRes.data);
  if (!loginApi.isOk) {
    print('login failed: ${loginApi.code} ${loginApi.message}');
    return;
  }
  final login =
      LoginInfo.fromJson((loginApi.data as Map).cast<String, dynamic>());
  final h = Options(headers: {'accessToken': login.accessToken});

  final groupsRes = await dio.get<dynamic>('/group/list', options: h);
  final groups = (ApiResponse.fromBody(groupsRes.data).data as List);
  print('groups count=${groups.length}');
  for (final g in groups) {
    final m = (g as Map).cast<String, dynamic>();
    print('  id=${m['id']} name=${m['name']}');
  }

  for (final g in groups) {
    final m = (g as Map).cast<String, dynamic>();
    final gid = (m['id'] as num).toInt();
    try {
      final res = await dio.post<Map<String, dynamic>>(
        '/message/group/send',
        data: GroupMessageDTO(
          tmpId: MessageTmpId.next(),
          groupId: gid,
          content: 'probe-${DateTime.now().millisecondsSinceEpoch}',
        ).toJson(),
        options: h,
      );
      final api = ApiResponse.fromBody(res.data);
      print('group $gid (${m['name']}) => code=${api.code} msg=${api.message}');
    } on DioException catch (e) {
      print('group $gid dio => ${e.response?.data}');
    }
  }

  // private: 取好友列表第一个
  try {
    final friendsRes = await dio.get<dynamic>('/friend/list', options: h);
    final friends = (ApiResponse.fromBody(friendsRes.data).data as List);
    if (friends.isEmpty) {
      print('private => skip (no friends)');
    } else {
      final fid = ((friends.first as Map)['id'] as num).toInt();
      final res = await dio.post<Map<String, dynamic>>(
        '/message/private/send',
        data: PrivateMessageDTO(
          tmpId: MessageTmpId.next(),
          recvId: fid,
          content: 'probe-private-${DateTime.now().millisecondsSinceEpoch}',
        ).toJson(),
        options: h,
      );
      final api = ApiResponse.fromBody(res.data);
      print('private recvId=$fid => code=${api.code} msg=${api.message}');
    }
  } on DioException catch (e) {
    print('private dio => ${e.response?.data}');
  }
}
