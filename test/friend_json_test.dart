import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/friend_request.dart';

void main() {
  group('Friend.fromJson', () {
    test('解析字符串 id 与整型布尔字段', () {
      final friend = Friend.fromJson({
        'id': '10001',
        'nickName': '张三',
        'showNickName': '老张',
        'isDnd': 1,
        'isTop': 0,
        'deleted': 'false',
        'online': 1,
        'onlineWeb': 0,
        'onlineApp': 1,
      });

      expect(friend.id, 10001);
      expect(friend.nickName, '张三');
      expect(friend.showNickName, '老张');
      expect(friend.isDnd, isTrue);
      expect(friend.isTop, isFalse);
      expect(friend.deleted, isFalse);
      expect(friend.online, isTrue);
      expect(friend.onlineApp, isTrue);
    });

    test('缺省布尔字段回落为 false', () {
      final friend = Friend.fromJson({'id': 2});
      expect(friend.isDnd, isFalse);
      expect(friend.deleted, isFalse);
      expect(friend.online, isFalse);
    });
  });

  group('FriendRequest.fromJson', () {
    test('解析 ISO applyTime 与字符串 status', () {
      final request = FriendRequest.fromJson({
        'id': '88',
        'sendId': '1',
        'recvId': '2',
        'sendNickName': 'A',
        'recvNickName': 'B',
        'remark': '你好',
        'status': '1',
        'applyTime': '2026-07-01T06:06:29.000+00:00',
      });

      expect(request.id, 88);
      expect(request.sendId, 1);
      expect(request.recvId, 2);
      expect(request.status, 1);
      expect(request.applyTime, isNotNull);
    });

    test('缺省 status 为待处理', () {
      final request = FriendRequest.fromJson({'id': 1});
      expect(request.status, 1);
    });
  });
}
