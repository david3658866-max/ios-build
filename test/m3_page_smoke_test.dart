import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/pages/chat/chat_box_page.dart';
import 'package:vortek/pages/chat/chat_history_file_page.dart';
import 'package:vortek/pages/chat/chat_history_image_page.dart';
import 'package:vortek/pages/chat/chat_history_page.dart';
import 'package:vortek/pages/chat/chat_system_content_page.dart';
import 'package:vortek/pages/chat/chat_system_page.dart';
import 'package:vortek/pages/friend/friend_add_page.dart';
import 'package:vortek/pages/friend/friend_apply_page.dart';
import 'package:vortek/pages/friend/friend_contact_page.dart';
import 'package:vortek/pages/friend/friend_remark_page.dart';
import 'package:vortek/pages/friend/friend_request_page.dart';
import 'package:vortek/pages/friend/user_info_page.dart';
import 'package:vortek/pages/main/tabs/contacts_tab.dart';
import 'package:vortek/pages/main/tabs/messages_tab.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/pages/group/group_edit_page.dart';
import 'package:vortek/pages/group/group_info_page.dart';
import 'package:vortek/pages/group/group_invite_page.dart';
import 'package:vortek/pages/group/group_list_page.dart';
import 'package:vortek/pages/group/group_manager_page.dart';
import 'package:vortek/pages/group/group_member_page.dart';
import 'package:vortek/pages/group/group_qrcode_page.dart';
import 'package:vortek/pages/group/group_setting_page.dart';
import 'package:vortek/pages/login/qr_login_confirm_page.dart';
import 'package:vortek/pages/main/tabs/mine_tab.dart';
import 'package:vortek/pages/mine/about_page.dart';
import 'package:vortek/pages/mine/account_page.dart';
import 'package:vortek/pages/mine/bind_email_page.dart';
import 'package:vortek/pages/mine/bind_phone_page.dart';
import 'package:vortek/pages/mine/mine_qrcode_page.dart';
import 'package:vortek/pages/mine/password_page.dart';
import 'package:vortek/pages/mine/profile_edit_page.dart';
import 'package:vortek/pages/mine/settings_page.dart';
import 'package:vortek/pages/mine/teenager_page.dart';

import 'helpers/page_test_harness.dart';

void _useTallPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1624);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 关键子页面挂载冒烟：首帧不崩溃、标题可见。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  late KvStore kv;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('page_smoke_');
    Hive.init(hiveDir.path);
    kv = await KvStore.open();
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  List mineOverrides() => [
        ...PageTestHarness.baseOverrides(),
        kvStoreProvider.overrideWithValue(kv),
      ];
  Future<void> pumpSmoke(
    WidgetTester tester,
    Widget page, {
    String? expectTitle,
    List? overrides,
  }) async {
    final scopeOverrides = overrides ?? PageTestHarness.baseOverrides();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...scopeOverrides],
        child: MaterialApp(home: page),
      ),
    );
    expect(tester.takeException(), isNull);
    if (expectTitle != null) {
      expect(find.text(expectTitle), findsOneWidget);
    }
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  }

  group('群组页面', () {
    testWidgets('GroupInfoPage 显示群聊信息与邀请入口', (tester) async {
      await pumpSmoke(
        tester,
        const GroupInfoPage(groupId: 100),
        expectTitle: '群聊信息',
      );
      expect(find.text('邀请'), findsOneWidget);
    });

    testWidgets('GroupInfoPage 已解散群显示不可加入', (tester) async {
      await pumpSmoke(
        tester,
        const GroupInfoPage(groupId: 100),
        expectTitle: '群聊信息',
        overrides: PageTestHarness.baseOverrides(
          group: const Group(
            id: 100,
            name: 'wo聊',
            quit: true,
            dissolve: true,
          ),
          members: const [],
        ),
      );
      expect(find.text('群聊已解散'), findsOneWidget);
      expect(find.text('加入群聊'), findsNothing);
    });

    testWidgets('GroupInvitePage 显示邀请', (tester) async {
      await pumpSmoke(
        tester,
        const GroupInvitePage(groupId: 100),
        expectTitle: '邀请',
      );
    });

    testWidgets('GroupMemberPage 显示群成员', (tester) async {
      await pumpSmoke(
        tester,
        const GroupMemberPage(groupId: 100),
        expectTitle: '群成员',
      );
    });

    testWidgets('GroupSettingPage 显示群设置', (tester) async {
      await pumpSmoke(
        tester,
        const GroupSettingPage(groupId: 100),
        expectTitle: '群设置',
      );
      expect(find.text('全员禁言'), findsOneWidget);
      expect(find.text('允许普通成员邀请好友'), findsOneWidget);
      expect(find.text('允许普通成员分享名片'), findsOneWidget);
    });

    testWidgets('GroupListPage 显示我的群聊', (tester) async {
      await pumpSmoke(
        tester,
        const GroupListPage(),
        expectTitle: '我的群聊',
        overrides: PageTestHarness.baseOverrides(),
      );
    });

    testWidgets('GroupManagerPage 显示群管理员', (tester) async {
      await pumpSmoke(
        tester,
        const GroupManagerPage(groupId: 100),
        expectTitle: '群管理员',
        overrides: PageTestHarness.baseOverrides(),
      );
    });

    testWidgets('GroupQrcodePage 显示群二维码', (tester) async {
      await pumpSmoke(
        tester,
        const GroupQrcodePage(groupId: 100),
        expectTitle: '群二维码',
        overrides: PageTestHarness.baseOverrides(),
      );
    });

    testWidgets('GroupEditPage 创建群聊首帧', (tester) async {
      await pumpSmoke(
        tester,
        const GroupEditPage(),
        expectTitle: '创建群聊',
        overrides: PageTestHarness.baseOverrides(),
      );
    });
  });

  group('消息页面', () {
    testWidgets('MessagesTab 显示消息', (tester) async {
      await pumpSmoke(
        tester,
        const MessagesTab(),
        expectTitle: '消息',
        overrides: PageTestHarness.messagesTabOverrides(),
      );
    });
  });

  group('好友页面', () {
    testWidgets('ContactsTab 显示好友', (tester) async {
      await pumpSmoke(
        tester,
        const ContactsTab(),
        expectTitle: '好友',
        overrides: PageTestHarness.friendTabOverrides(),
      );
      expect(find.text('新的朋友'), findsOneWidget);
    });

    testWidgets('FriendAddPage 显示添加好友', (tester) async {
      await pumpSmoke(
        tester,
        const FriendAddPage(),
        expectTitle: '添加好友',
      );
    });

    testWidgets('FriendRequestPage 显示新的朋友', (tester) async {
      await pumpSmoke(
        tester,
        const FriendRequestPage(),
        expectTitle: '新的朋友',
      );
    });

    testWidgets('FriendApplyPage 显示申请添加朋友', (tester) async {
      await pumpSmoke(
        tester,
        const FriendApplyPage(userId: 2),
        expectTitle: '申请添加朋友',
      );
    });

    testWidgets('FriendRemarkPage 显示设置备注', (tester) async {
      await pumpSmoke(
        tester,
        const FriendRemarkPage(friendId: 2),
        expectTitle: '设置备注',
        overrides: PageTestHarness.friendDetailOverrides(),
      );
    });

    testWidgets('FriendContactPage 显示手机通讯录', (tester) async {
      await pumpSmoke(
        tester,
        const FriendContactPage(),
        expectTitle: '手机通讯录',
      );
    });

    testWidgets('UserInfoPage 显示用户信息', (tester) async {
      await pumpSmoke(
        tester,
        const UserInfoPage(userId: 2),
        expectTitle: '用户信息',
        overrides: PageTestHarness.friendDetailOverrides(),
      );
    });
  });

  group('聊天子页', () {
    testWidgets('ChatHistoryPage 显示聊天记录', (tester) async {
      await pumpSmoke(
        tester,
        const ChatHistoryPage(
          chatType: ChatType.group,
          targetId: 100,
        ),
        expectTitle: '聊天记录',
      );
    });

    testWidgets('ChatSystemPage 显示系统通知', (tester) async {
      await pumpSmoke(
        tester,
        const ChatSystemPage(),
        expectTitle: '系统通知',
      );
    });

    testWidgets('ChatHistoryImagePage 显示图片与视频', (tester) async {
      await pumpSmoke(
        tester,
        const ChatHistoryImagePage(
          chatType: ChatType.group,
          targetId: 100,
        ),
        expectTitle: '图片与视频',
        overrides: PageTestHarness.baseOverrides(),
      );
    });

    testWidgets('ChatHistoryFilePage 显示文件', (tester) async {
      await pumpSmoke(
        tester,
        const ChatHistoryFilePage(
          chatType: ChatType.group,
          targetId: 100,
        ),
        expectTitle: '文件',
        overrides: PageTestHarness.baseOverrides(),
      );
    });

    testWidgets('ChatSystemContentPage 显示系统通知详情', (tester) async {
      await pumpSmoke(
        tester,
        const ChatSystemContentPage(messageId: 1, title: '测试通知'),
        expectTitle: '测试通知',
      );
    });

    testWidgets('ChatBoxPage 群聊首帧含输入框', (tester) async {
      await pumpSmoke(
        tester,
        const ChatBoxPage(
          chatType: ChatType.group,
          targetId: 100,
        ),
        overrides: PageTestHarness.chatBoxOverrides(),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('chat_input_field')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('我的/设置', () {
    testWidgets('MineTab 显示我的', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const MineTab(),
        expectTitle: '我的',
        overrides: mineOverrides(),
      );
    });

    testWidgets('SettingsPage 显示设置', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const SettingsPage(),
        expectTitle: '设置',
        overrides: mineOverrides(),
      );
    });

    testWidgets('ProfileEditPage 显示修改我的信息', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const ProfileEditPage(),
        expectTitle: '修改我的信息',
        overrides: mineOverrides(),
      );
    });

    testWidgets('AccountPage 显示账号安全', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const AccountPage(),
        expectTitle: '账号安全',
        overrides: mineOverrides(),
      );
    });

    testWidgets('PasswordPage 显示修改密码', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const PasswordPage(),
        expectTitle: '修改密码',
        overrides: mineOverrides(),
      );
    });

    testWidgets('BindPhonePage 显示绑定手机', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const BindPhonePage(),
        expectTitle: '绑定手机',
        overrides: mineOverrides(),
      );
    });

    testWidgets('BindEmailPage 显示绑定邮箱', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const BindEmailPage(),
        expectTitle: '绑定邮箱',
        overrides: mineOverrides(),
      );
    });

    testWidgets('TeenagerPage 显示青少年模式', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const TeenagerPage(),
        expectTitle: '青少年模式',
        overrides: mineOverrides(),
      );
    });

    testWidgets('MineQrcodePage 显示我的二维码', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const MineQrcodePage(),
        expectTitle: '我的二维码',
        overrides: mineOverrides(),
      );
    });

    testWidgets('AboutPage 显示关于我们', (tester) async {
      _useTallPhoneViewport(tester);
      await pumpSmoke(
        tester,
        const AboutPage(),
        expectTitle: '关于我们',
        overrides: mineOverrides(),
      );
    });
  });

  group('通用', () {
    // WebView 需平台实现，widget test 不测；真机见 m3-device-checklist。
    testWidgets('QrLoginConfirmPage 显示登录确认', (tester) async {
      await pumpSmoke(
        tester,
        const QrLoginConfirmPage(qrCode: 'test-qr'),
        expectTitle: '登录确认',
      );
    });
  });
}
