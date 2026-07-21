import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/models/user.dart';

void main() {
  test('User.fromJson 解析 search 返回的 ISO lastLoginTime', () {
    final user = User.fromJson({
      'id': 68710772,
      'userName': '15333333333',
      'phone': '15333333333',
      'nickName': '15333333333',
      'sex': 0,
      'type': 0,
      'isBanned': false,
      'isManualApprove': true,
      'status': 0,
      'online': false,
      'lastLoginTime': '2026-07-01T06:06:29.000+00:00',
      'userIdentity': 1,
      'totpEnabled': false,
    });

    expect(user.id, 68710772);
    expect(user.phone, '15333333333');
    expect(user.lastLoginTime, isNotNull);
  });
}
