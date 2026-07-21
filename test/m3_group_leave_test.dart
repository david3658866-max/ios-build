import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/constants/ui_timing.dart';
import 'package:vortek/core/utils/group_leave_util.dart';

void main() {
  group('GroupLeaveUtil', () {
    test('默认清除聊天记录为 true', () {
      expect(GroupLeaveUtil.defaultCleanOnLeave, isTrue);
    });

    test('退群确认文案', () {
      final c = GroupLeaveUtil.quitConfirm();
      expect(c.title, '确认退出');
      expect(c.content, '退出群聊后将不再接受群里的消息，确认退出吗?');
      expect(c.showCleanSwitch, isTrue);
      expect(c.confirmText, '退出');
    });

    test('解散确认文案含群名', () {
      final c = GroupLeaveUtil.dissolveConfirm('测试群');
      expect(c.title, '确认解散');
      expect(c.content, "确认要解散群聊'测试群'吗?");
      expect(c.showCleanSwitch, isTrue);
      expect(c.confirmText, '解散');
    });

    test('成功提示文案', () {
      expect(
        GroupLeaveUtil.quitSuccessMessage('ABC'),
        "您退出了群聊'ABC'",
      );
      expect(
        GroupLeaveUtil.dissolveSuccessMessage('ABC'),
        "您解散了群聊'ABC'",
      );
    });

    test('退群/解散后 1.5s 再跳转群列表', () {
      expect(UiTiming.groupLeaveRedirect, const Duration(milliseconds: 1500));
    });

    test('API 路径与 group_api 一致', () {
      expect(GroupLeaveUtil.quitApiPath(100), '/group/quit/100');
      expect(GroupLeaveUtil.dissolveApiPath(100), '/group/delete/100');
    });

    test('shouldRemoveLocalChat 跟随开关', () {
      expect(GroupLeaveUtil.shouldRemoveLocalChat(true), isTrue);
      expect(GroupLeaveUtil.shouldRemoveLocalChat(false), isFalse);
    });
  });
  group('GroupLeaveDeviceChecks', () {
    test('真机项非空', () {
      expect(GroupLeaveDeviceChecks.quit, isNotEmpty);
      expect(GroupLeaveDeviceChecks.dissolve, isNotEmpty);
    });
  });
}
