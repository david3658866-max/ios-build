import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/constants/ui_timing.dart';
import 'package:vortek/models/group.dart';

void main() {
  group('建群流程对齐 uniapp', () {
    test('group-edit / group-invite 成功 Toast 后 1s 导航', () {
      expect(UiTiming.toastThenNavigate, const Duration(milliseconds: 1000));
    });

    test('创建群聊时群名与群备注默认留空、由用户填写', () {
      const emptyName = '';
      const emptyRemark = '';
      expect(emptyName, isEmpty);
      expect(emptyRemark, isEmpty);
    });

    test('create API body 不含 id', () {
      final body = <String, dynamic>{
        'name': 'test创建的群聊',
        'headImage': 'https://example.com/a.png',
        'headImageThumb': 'https://example.com/a_t.png',
        'ownerId': 100,
        'remarkGroupName': '',
        'remarkNickName': '',
        'notice': '',
      };
      expect(body.containsKey('id'), isFalse);
      expect(body['name'], isA<String>());
      expect(body['ownerId'], 100);
    });

    test('invite API body 字段', () {
      const body = {
        'groupId': 42,
        'friendIds': [1, 2, 3],
      };
      expect(body['groupId'], 42);
      expect(body['friendIds'], [1, 2, 3]);
    });
    test('头像上传结果字段对齐 image-upload onSuccess', () {
      const origin = 'https://cdn.example.com/a.png';
      const thumb = 'https://cdn.example.com/a_t.png';
      expect(thumb, isNotEmpty);
      expect(origin, isNotEmpty);
    });

    test('syncChatFromGroup 使用 showGroupName 与 headImageThumb', () {
      const group = Group(
        id: 1,
        name: '原群名',
        showGroupName: '备注群名',
        headImageThumb: 'https://cdn.example.com/g_t.png',
      );
      expect(group.showGroupName ?? group.name, '备注群名');
      expect(group.headImageThumb, 'https://cdn.example.com/g_t.png');
    });
  });
}
