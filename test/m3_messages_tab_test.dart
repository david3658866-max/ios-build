import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/storage/app_database.dart';
import 'package:vortek/core/utils/chat_list_util.dart';
import 'package:vortek/core/utils/chat_item_util.dart';
import 'package:vortek/core/utils/long_press_menu_util.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/pages/main/tabs/messages_tab.dart';
import 'package:vortek/stores/config_store.dart';

import 'helpers/page_test_harness.dart';

Chat _testChat({
  int id = 1,
  String showName = '张三',
  String type = ChatType.private,
  int targetId = 2,
}) => Chat(
  id: id,
  type: type,
  targetId: targetId,
  showName: showName,
  unreadCount: 0,
  atMe: false,
  atAll: false,
  lastAtMessageId: 0,
  isDnd: false,
  isTop: false,
  lastMsgId: 0,
  messagesLoaded: false,
);

void _useTallPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1624);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('会话列表工具', () {
    test('matchesChatSearch 按 showName 子串匹配', () {
      final chat = _testChat(showName: '测试好友');
      expect(matchesChatSearch(chat, ''), isTrue);
      expect(matchesChatSearch(chat, '好友'), isTrue);
      expect(matchesChatSearch(chat, '不存在'), isFalse);
    });

    test('filterChatsForDisplay 过滤并限制条数', () {
      final chats = [
        _testChat(id: 1, showName: '张三'),
        _testChat(id: 2, showName: '李四'),
        _testChat(id: 3, showName: '王五'),
      ];
      final filtered = filterChatsForDisplay(chats, '张', limit: 10);
      expect(filtered.map((c) => c.id), [1]);

      final limited = filterChatsForDisplay(chats, '', limit: 2);
      expect(limited.length, 2);
    });

    test('messagesTabStatusMessage 仅 syncLoading 时显示状态条', () {
      expect(
        messagesTabStatusMessage(appInit: false, chatSyncLoading: false),
        isNull,
      );
      expect(
        messagesTabStatusMessage(
          appInit: false,
          chatSyncLoading: false,
          isAuthenticated: true,
        ),
        isNull,
      );
      expect(
        messagesTabStatusMessage(appInit: false, chatSyncLoading: true),
        '正在同步最近消息…',
      );
      expect(
        messagesTabStatusMessage(appInit: true, chatSyncLoading: false),
        isNull,
      );
    });

    test('isChatItemTextPreview 仅 TEXT 渲染表情', () {
      expect(isChatItemTextPreview(MessageType.text), isTrue);
      expect(isChatItemTextPreview(MessageType.image), isFalse);
      expect(isChatItemTextPreview(MessageType.tipText), isFalse);
      expect(isChatItemTextPreview(null), isFalse);
    });

    test('shouldOpenChatLongPressMenu 滑动时不弹出', () {
      expect(shouldOpenChatLongPressMenu(touchMoved: false), isTrue);
      expect(shouldOpenChatLongPressMenu(touchMoved: true), isFalse);
    });

    test('computeLongPressMenuTopLeft 对齐 long-press-menu.vue 四象限', () {
      const menuSize = Size(200, 264);
      const size = Size(400, 800);
      const gap = 20.0;

      final topLeft = computeLongPressMenuTopLeft(
        touch: const Offset(100, 100),
        menuSize: menuSize,
        windowSize: size,
        gap: gap,
      );
      expect(topLeft.dx, 100);
      expect(topLeft.dy, 120);

      final bottomRight = computeLongPressMenuTopLeft(
        touch: const Offset(300, 600),
        menuSize: menuSize,
        windowSize: size,
        gap: gap,
      );
      expect(bottomRight.dx, 100);
      expect(bottomRight.dy, 316);
    });

    test('shouldShowChatItemSendName 仅群聊普通消息显示发送者', () {
      expect(
        shouldShowChatItemSendName(
          type: ChatType.group,
          sendNickName: '张三',
          lastMsgType: MessageType.text,
        ),
        isTrue,
      );
      expect(
        shouldShowChatItemSendName(
          type: ChatType.group,
          sendNickName: '张三',
          lastMsgType: MessageType.tipText,
        ),
        isFalse,
      );
      expect(
        shouldShowChatItemSendName(
          type: ChatType.group,
          sendNickName: '张三',
          lastMsgType: null,
        ),
        isFalse,
      );
      expect(
        shouldShowChatItemSendName(
          type: ChatType.private,
          sendNickName: '张三',
          lastMsgType: MessageType.text,
        ),
        isFalse,
      );
    });
  });

  group('消息 Tab UI 契约', () {
    testWidgets('MessagesTab 显示标题与空态', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [...PageTestHarness.messagesTabOverrides()],
          child: const MaterialApp(home: MessagesTab()),
        ),
      );
      await tester.pump();
      expect(find.text('消息'), findsOneWidget);
      expect(find.text('还没有聊天'), findsOneWidget);
    });

    testWidgets('离线同步中显示正在同步最近消息', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...PageTestHarness.messagesTabOverrides(
              config: const ConfigState(appInit: true, chatSyncLoading: true),
            ),
          ],
          child: const MaterialApp(home: MessagesTab()),
        ),
      );
      await tester.pump();
      expect(find.text('正在同步最近消息…'), findsOneWidget);
    });

    testWidgets('搜索过滤会话 showName', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...PageTestHarness.messagesTabOverrides(
              chats: [
                _testChat(id: 1, showName: '张三'),
                _testChat(id: 2, showName: '李四', targetId: 3),
              ],
            ),
          ],
          child: const MaterialApp(home: MessagesTab()),
        ),
      );
      await tester.pump();
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('李四'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '张');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.text('张三', findRichText: true), findsOneWidget);
      expect(find.text('李四'), findsNothing);
      expect(find.text("未搜索到与'张'相关的会话"), findsNothing);
    });

    testWidgets('长按会话弹出置顶/免打扰/删除菜单', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...PageTestHarness.messagesTabOverrides(
              chats: [_testChat(id: 1, showName: '张三')],
            ),
          ],
          child: const MaterialApp(home: MessagesTab()),
        ),
      );
      await tester.pump();

      await tester.longPress(find.text('张三'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('置顶该聊天'), findsOneWidget);
      expect(find.text('消息免打扰'), findsOneWidget);
      expect(find.text('删除该聊天'), findsOneWidget);
    });
  });
}
