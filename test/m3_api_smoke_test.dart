import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/http/api_result.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/friend_request.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_member.dart';
import 'package:vortek/models/user.dart';

import 'helpers/integration_auth.dart';

/// M3 群组/好友 API 冒烟：登录后拉真实数据并验证 fromJson 不抛错。
/// 对照 uniapp 常用接口，无需真机 UI。
void main() {
  late Dio dio;
  late String token;

  setUpAll(() async {
    dio = IntegrationAuth.dio();
    final login = await IntegrationAuth.login(dio);
    token = login.accessToken;
  });

  Options authHeaders() => IntegrationAuth.authedOptions(token);

  test('GET /friend/list 可解析', () async {
    final res = await dio.get<dynamic>('/friend/list', options: authHeaders());
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: api.message);
    final list = (api.data as List)
        .map((e) => Friend.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(list, isA<List<Friend>>());
  });

  test('GET /friend/request/list 可解析', () async {
    final res =
        await dio.get<dynamic>('/friend/request/list', options: authHeaders());
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: api.message);
    final list = (api.data as List)
        .map((e) => FriendRequest.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(list, isA<List<FriendRequest>>());
  });

  test('GET /user/search?name=15333333333 可解析（曾报 type 错误）', () async {
    final res = await dio.get<dynamic>(
      '/user/search',
      queryParameters: {'name': '15333333333'},
      options: authHeaders(),
    );
    final api = ApiResponse.fromBody(res.data);
    expect(api.isOk, isTrue, reason: api.message);
    if (api.data is List && (api.data as List).isNotEmpty) {
      for (final raw in api.data as List) {
        final user = User.fromJson((raw as Map).cast<String, dynamic>());
        expect(user.id, greaterThan(0));
      }
    }
  });

  test('群链路：list → find → members 可解析', () async {
    final listRes = await dio.get<dynamic>('/group/list', options: authHeaders());
    final listApi = ApiResponse.fromBody(listRes.data);
    expect(listApi.isOk, isTrue, reason: listApi.message);
    final groups = (listApi.data as List)
        .map((e) => Group.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(groups, isA<List<Group>>());

    if (groups.isEmpty) return;

    final groupId = groups.first.id;
    final findRes =
        await dio.get<Map<String, dynamic>>('/group/find/$groupId', options: authHeaders());
    final findApi = ApiResponse.fromBody(findRes.data);
    expect(findApi.isOk, isTrue, reason: findApi.message);
    final detail =
        Group.fromJson((findApi.data as Map).cast<String, dynamic>());
    expect(detail.id, groupId);

    final memRes = await dio.get<dynamic>(
      '/group/members/$groupId',
      options: authHeaders(),
    );
    final memApi = ApiResponse.fromBody(memRes.data);
    expect(memApi.isOk, isTrue, reason: memApi.message);
    final members = (memApi.data as List)
        .map((e) => GroupMember.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    expect(members, isA<List<GroupMember>>());
  });
}
