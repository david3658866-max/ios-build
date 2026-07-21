import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/friend_contact_util.dart';
import 'package:vortek/core/utils/friend_list_util.dart';
import 'package:vortek/core/utils/permission_guide_util.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/pages/friend/friend_apply_page.dart';
import 'package:vortek/pages/friend/friend_contact_page.dart';
import 'package:vortek/pages/friend/friend_remark_page.dart';
import 'package:vortek/pages/friend/user_info_page.dart';
import 'package:vortek/pages/main/tabs/contacts_tab.dart';
import 'package:vortek/widgets/im_action_sheet.dart';
import 'package:vortek/router/app_router.dart';

import 'helpers/page_test_harness.dart';

void _useTallPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1624);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('好友路由契约', () {
    test('添加好友 keyword / 通讯录 / 申请列表', () {
      expect(
        AppRoutes.friendAddKeywordPath('13800138000'),
        '/friend/add?keyword=13800138000',
      );
      expect(AppRoutes.friendContact, '/friend/contact');
      expect(AppRoutes.friendRequests, '/friend/requests');
    });
  });

  group('好友拼音分组', () {
    test('在线好友置顶为 * 锚点', () {
      final groups = groupFriendsByPinyin(const [
        Friend(id: 1, showNickName: 'Bob', online: true),
        Friend(id: 2, showNickName: 'Alice'),
      ], '');
      expect(groups.first.indexKey, '*');
      expect(groups.first.anchor, '在线好友');
    });

    test('搜索过滤 showNickName', () {
      final groups = groupFriendsByPinyin(const [
        Friend(id: 1, showNickName: '张三'),
        Friend(id: 2, showNickName: '李四'),
      ], '张');
      expect(groups.length, 1);
      expect(groups.first.friends.single.id, 1);
    });

    test('非字母昵称归入 #', () {
      final groups = groupFriendsByPinyin(const [
        Friend(id: 1, showNickName: '123'),
      ], '');
      expect(groups.single.indexKey, '#');
    });
  });

  group('手机通讯录过滤', () {
    test('按任意号码匹配', () {
      const rows = [
        DeviceContactRow(id: '1', name: '王五', phones: ['13900001111']),
        DeviceContactRow(id: '2', name: '赵六', phones: ['13800002222']),
      ];
      final filtered = filterDeviceContacts(rows, '2222');
      expect(filtered.single.name, '赵六');
    });

    test('保留无号码联系人供展示', () {
      const row = DeviceContactRow(id: '1', name: '无名', phones: []);
      expect(row.primaryPhone, isEmpty);
      expect(filterDeviceContacts([row], ''), [row]);
    });
  });

  group('通讯录权限引导', () {
    test('PermissionGuideUtil 文案对齐 uniapp showPermissionGuide', () {
      expect(
        PermissionGuideUtil.contactsPermissionGuideTitle('通讯录'),
        '需要通讯录权限',
      );
      expect(
        PermissionGuideUtil.contactsPermissionGuideBody(
          '通讯录',
          '访问通讯录用于快速添加好友',
        ),
        '访问通讯录用于快速添加好友，请在系统设置中开启该权限。',
      );
      expect(
        PermissionGuideUtil.contactsPermissionDeniedHint,
        '请在系统设置中开启通讯录权限',
      );
    });

    testWidgets('ImActionSheet 显示选项与取消', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await ImActionSheet.show(
                      ctx,
                      itemList: const ['手机通讯录'],
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('手机通讯录'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
    });
  });

  group('通讯录 Tab UI 契约', () {
    testWidgets('ContactsTab 标题居中且含顶部入口', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...PageTestHarness.friendTabOverrides()],
          child: const MaterialApp(home: ContactsTab()),
        ),
      );
      await tester.pump();
      expect(find.text('好友'), findsOneWidget);
      expect(find.text('新的朋友'), findsOneWidget);
      expect(find.text('我的群聊'), findsOneWidget);
    });
  });

  group('好友子页 UI 契约', () {
    testWidgets('FriendApplyPage 显示申请添加朋友', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...PageTestHarness.friendTabOverrides()],
          child: const MaterialApp(home: FriendApplyPage(userId: 2)),
        ),
      );
      expect(find.text('申请添加朋友'), findsOneWidget);
      expect(find.text('发送'), findsOneWidget);
    });

    testWidgets('FriendContactPage 显示手机通讯录', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...PageTestHarness.friendTabOverrides()],
          child: const MaterialApp(home: FriendContactPage()),
        ),
      );
      expect(find.text('手机通讯录'), findsOneWidget);
    });

    testWidgets('UserInfoPage 显示用户信息', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...PageTestHarness.friendDetailOverrides()],
          child: const MaterialApp(home: UserInfoPage(userId: 2)),
        ),
      );
      expect(find.text('用户信息'), findsOneWidget);
    });

    testWidgets('FriendRemarkPage 提交成功后仍停留当前页', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...PageTestHarness.friendDetailOverrides()],
          child: const MaterialApp(home: FriendRemarkPage(friendId: 2)),
        ),
      );
      await tester.tap(find.text('提交'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('设置备注'), findsOneWidget);
      expect(find.text('修改成功'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
    });
  });
}
