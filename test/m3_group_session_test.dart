import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/constants/ui_timing.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/storage/app_database.dart' show Chat;
import 'package:vortek/core/utils/scan_deep_link.dart';
import 'package:vortek/core/utils/scan_util.dart';
import 'package:vortek/models/friend_request.dart';
import 'package:vortek/router/app_router.dart';
import 'package:vortek/services/badge_service.dart';
import 'package:vortek/widgets/chat/chat_item.dart';

Chat _chat({
  int unread = 0,
  bool isDnd = false,
  bool isTop = false,
  bool atMe = false,
  bool atAll = false,
  String? lastContent,
  String? sendNickName,
  int? lastMsgType,
}) {
  return Chat(
    id: 1,
    type: ChatType.group,
    targetId: 100,
    showName: '测试群',
    lastContent: lastContent ?? '你好',
    lastSendTime: 1,
    sendNickName: sendNickName,
    lastMsgType: lastMsgType,
    unreadCount: unread,
    atMe: atMe,
    atAll: atAll,
    lastAtMessageId: 0,
    isDnd: isDnd,
    isTop: isTop,
    lastMsgId: 1,
    messagesLoaded: true,
  );
}

void main() {
  group('G9 群生命周期时序', () {
    test('退群/解散跳转延迟 1500ms 对齐 uniapp', () {
      expect(UiTiming.groupLeaveRedirect.inMilliseconds, 1500);
    });
  });

  group('G11 扫码路由', () {
    test('外链走 external-link 路由', () {
      const url = 'https://example.com/page?id=1';
      expect(
        AppRoutes.externalLinkPath(url),
        '/external-link?url=${Uri.encodeComponent(url)}',
      );
    });

    test('群二维码解析为 groupInfo', () {
      final action = ScanUtil.parse(
        'https://novali.de010.com?scan=1&groupId=42',
      );
      expect(action.type, ScanActionType.groupInfo);
      expect(action.groupId, 42);
    });

    test('用户二维码解析为 userProfile', () {
      final action = ScanUtil.parse(
        'https://novali.de010.com?scan=1&userId=1001',
      );
      expect(action.type, ScanActionType.userProfile);
      expect(action.userId, 1001);
    });

    test('扫码深链路由对齐 uniapp', () {
      expect(
        routeFromScanUri(Uri.parse('https://x.com?scan=1&groupId=9')),
        '/group/info/9',
      );
      expect(
        routeFromScanUri(Uri.parse('https://x.com?scan=1&userId=7')),
        '/friend/user/7',
      );
    });

    test('普通 https 为外链', () {
      final action = ScanUtil.parse('https://example.com/help');
      expect(action.type, ScanActionType.externalLink);
      expect(action.url, 'https://example.com/help');
    });
  });

  group('M3-1 会话列表 ChatItem', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('atMe 显示 [有人@我]', (tester) async {
      await tester.pumpWidget(wrap(ChatItem(chat: _chat(atMe: true))));
      expect(find.text('[有人@我]'), findsOneWidget);
    });

    testWidgets('atAll 显示 [@全体成员]', (tester) async {
      await tester.pumpWidget(wrap(ChatItem(chat: _chat(atAll: true))));
      expect(find.text('[@全体成员]'), findsOneWidget);
    });

    testWidgets('免打扰显示静音图标和弱未读角标', (tester) async {
      await tester.pumpWidget(
        wrap(ChatItem(chat: _chat(isDnd: true, unread: 5))),
      );
      expect(find.byIcon(Icons.notifications_off_outlined), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('未读数显示角标', (tester) async {
      await tester.pumpWidget(wrap(ChatItem(chat: _chat(unread: 3))));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('置顶时渲染置顶角标绘制', (tester) async {
      await tester.pumpWidget(wrap(ChatItem(chat: _chat(isTop: true))));
      expect(tester.takeException(), isNull);
      expect(find.text('置顶'), findsOneWidget);
      // 仍保留右上角 CustomPaint 小角标。
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('群聊文字消息显示发送者前缀', (tester) async {
      await tester.pumpWidget(
        wrap(
          ChatItem(
            chat: _chat(sendNickName: '李四', lastMsgType: MessageType.text),
          ),
        ),
      );
      expect(find.text('李四: '), findsOneWidget);
    });

    testWidgets('群聊提示类消息不显示发送者前缀', (tester) async {
      await tester.pumpWidget(
        wrap(
          ChatItem(
            chat: _chat(
              sendNickName: '李四',
              lastContent: '李四撤回了一条消息',
              lastMsgType: MessageType.tipText,
            ),
          ),
        ),
      );
      expect(find.text('李四: '), findsNothing);
    });
  });

  group('M3-2 Tab 角标计算', () {
    test('computeChatTabBadge 忽略免打扰未读', () {
      final count = computeChatTabBadge([
        _chat(unread: 2),
        _chat(unread: 5, isDnd: true),
        _chat(unread: 1),
      ]);
      expect(count, 3);
    });

    test('computeFriendTabBadge 只统计发给当前用户的申请', () {
      final count = computeFriendTabBadge(const [
        FriendRequest(id: 1, sendId: 2, recvId: 10, status: 0),
        FriendRequest(id: 2, sendId: 3, recvId: 11, status: 0),
        FriendRequest(id: 3, sendId: 4, recvId: 10, status: 0),
      ], 10);
      expect(count, 2);
    });
  });
}
