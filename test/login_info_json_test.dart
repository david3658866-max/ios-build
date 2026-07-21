import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/models/login_info.dart';

void main() {
  test('LoginInfo.fromJson 兼容字符串 userId 与 expiresIn', () {
    final info = LoginInfo.fromJson({
      'accessToken': 'at',
      'refreshToken': 'rt',
      'userId': '68710772',
      'accessTokenExpiresIn': '7200',
      'refreshTokenExpiresIn': '2592000',
    });

    expect(info.accessToken, 'at');
    expect(info.refreshToken, 'rt');
    expect(info.userId, 68710772);
    expect(info.accessTokenExpiresIn, 7200);
    expect(info.refreshTokenExpiresIn, 2592000);
  });

  test('LoginInfo.fromJson userId 为 null 时降级为 0', () {
    final info = LoginInfo.fromJson({
      'accessToken': 'at',
      'refreshToken': 'rt',
      'userId': null,
    });

    expect(info.userId, 0);
  });
}
