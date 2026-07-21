import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_message.dart';
import 'package:vortek/models/private_message.dart';
import 'package:vortek/models/system_message.dart';

import 'helpers/integration_auth.dart';

/// M4 只读 API 冒烟：覆盖 MessageApi/SystemApi 中尚未在 m3 测到的 GET 端点。
/// 不写库、不发送消息，降低对测试环境影响。
void main() {
  late Dio dio;
  late String token;

  setUpAll(() async {
    dio = IntegrationAuth.dio();
    final login = await IntegrationAuth.login(dio);
    token = login.accessToken;
  });

  Options h() => IntegrationAuth.authedOptions(token);

  Future<ApiResponse> getApi(String path, {Map<String, dynamic>? query}) async {
    return IntegrationAuth.withNetworkRetry(() async {
      final res = await dio.get<dynamic>(path, queryParameters: query, options: h());
      return ApiResponse.fromBody(res.data);
    });
  }

  test('GET /system/checkVersion 可解析', () async {
    final api = await getApi('/system/checkVersion', query: {'version': '1.0.0'});
    expect(api.isOk, isTrue, reason: api.message);
  });

  test('GET /message/system/loadOfflineMessage 可解析', () async {
    final api = await getApi('/message/system/loadOfflineMessage', query: {'minSeqNo': 0});
    expect(api.isOk, isTrue, reason: api.message);
    if (api.data is List) {
      for (final raw in api.data as List) {
        SystemMessage.fromJson((raw as Map).cast<String, dynamic>());
      }
    }
  });

  test('GET /friend/find/{id} 可解析', () async {
    final listApi = await getApi('/friend/list');
    expect(listApi.isOk, isTrue, reason: listApi.message);
    final friends = (listApi.data as List)
        .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    if (friends.isEmpty) return;

    final api = await getApi('/friend/find/${friends.first.id}');
    expect(api.isOk, isTrue, reason: api.message);
    Friend.fromJson((api.data as Map).cast<String, dynamic>());
  });

  test('私聊离线链路：maxReadedId + loadOfflineMessageByChat', () async {
    final listApi = await getApi('/friend/list');
    expect(listApi.isOk, isTrue);
    final friends = (listApi.data as List)
        .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    if (friends.isEmpty) return;

    final fid = friends.first.id;
    final maxApi = await getApi('/message/private/maxReadedId', query: {'friendId': fid});
    expect(maxApi.isOk, isTrue, reason: maxApi.message);

    final offApi = await getApi(
      '/message/private/loadOfflineMessageByChat',
      query: {'friendId': fid, 'minId': 0},
    );
    expect(offApi.isOk, isTrue, reason: offApi.message);
    if (offApi.data is List) {
      for (final raw in offApi.data as List) {
        PrivateMessage.fromJson((raw as Map).cast<String, dynamic>());
      }
    }
  });

  test('群聊离线链路：history + loadOfflineMessageByChat + webrtc/info', () async {
    final listApi = await getApi('/group/list');
    expect(listApi.isOk, isTrue);
    final groups = (listApi.data as List)
        .map((e) => Group.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    if (groups.isEmpty) return;

    final gid = groups.first.id;

    final histApi = await getApi(
      '/message/group/history',
      query: {'groupId': gid, 'page': 1, 'size': 20},
    );
    expect(histApi.isOk, isTrue, reason: histApi.message);
    if (histApi.data is List) {
      for (final raw in histApi.data as List) {
        GroupMessage.fromJson((raw as Map).cast<String, dynamic>());
      }
    }

    final offApi = await getApi(
      '/message/group/loadOfflineMessageByChat',
      query: {'groupId': gid, 'minId': 0},
    );
    expect(offApi.isOk, isTrue, reason: offApi.message);

    final rtcApi = await getApi('/webrtc/group/info', query: {'groupId': gid});
    expect(rtcApi.isOk, isTrue, reason: rtcApi.message);
  });

  test('GET /webrtc/private/info 可解析', () async {
    final listApi = await getApi('/friend/list');
    expect(listApi.isOk, isTrue);
    final friends = (listApi.data as List);
    if (friends.isEmpty) return;

    final fid = ((friends.first as Map)['id'] as num).toInt();
    final api = await getApi('/webrtc/private/info', query: {'uid': fid});
    expect(api.isOk, isTrue, reason: api.message);
  });
}
