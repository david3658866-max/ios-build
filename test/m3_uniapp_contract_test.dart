import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/emotion_util.dart';
import 'package:vortek/router/app_router.dart';

/// 与 uniapp 约定的静态契约（路由、表情协议等），不依赖真机。
void main() {
  group('群路由不与成员/资料串页', () {
    const gid = 99;
    final paths = <String>{
      AppRoutes.groupInfoPath(gid),
      AppRoutes.groupMemberPath(gid),
      AppRoutes.groupInvitePath(gid),
      AppRoutes.groupSettingPath(gid),
      AppRoutes.groupManagerPath(gid),
      AppRoutes.groupQrcodePath(gid, isAllowInvite: true),
      AppRoutes.groupEditPath(gid),
    };

    test('各子路径互不相同', () {
      expect(paths.length, paths.toSet().length);
    });

    test('邀请路径含 invite 段而非 member', () {
      final invite = AppRoutes.groupInvitePath(gid);
      expect(invite, contains('/invite/'));
      expect(invite, isNot(contains('/member/')));
    });
  });

  group('表情协议对齐 emotion.js', () {
    test('#憨笑; 可识别', () {
      expect(EmotionUtil.hasEmotion('#憨笑;'), isTrue);
      expect(EmotionUtil.extract('#憨笑;'), ['憨笑']);
      expect(EmotionUtil.indexOfWord('憨笑'), isNotNull);
    });

    test('兼容旧 [憨笑] 格式', () {
      expect(EmotionUtil.hasEmotion('[憨笑]'), isTrue);
      expect(EmotionUtil.extract('[憨笑]'), ['憨笑']);
    });

    test('emoji 列表数量与 uniapp emoTextList 一致（57）', () {
      expect(EmotionUtil.emoTextList.length, 57);
    });

    test('wrap 输出 #词;', () {
      expect(EmotionUtil.wrap('憨笑'), '#憨笑;');
    });

    test('输入框 token 与发送编码', () {
      final token = EmotionUtil.inputTokenForWord('头晕');
      expect(token.length, 1);
      expect(EmotionUtil.wordFromInputToken(token), '头晕');
      expect(
        EmotionUtil.encodeForWire('你好$token'),
        '你好#头晕;',
      );
    });
  });

  group('好友路由', () {
    test('申请/资料/备注/添加/通讯录/申请列表路径', () {
      expect(AppRoutes.friendApplyPath(5), '/friend/apply/5');
      expect(AppRoutes.friendUserPath(5), '/friend/user/5');
      expect(AppRoutes.friendRemarkPath(5), '/friend/remark/5');
      expect(
        AppRoutes.friendAddKeywordPath('13800138000'),
        contains('/friend/add?keyword='),
      );
      expect(AppRoutes.friendContact, '/friend/contact');
      expect(AppRoutes.friendRequests, '/friend/requests');
    });
  });
}
