import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/chat_type.dart';
import 'package:vortek/core/enums/message_status.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/storage/app_database.dart' hide GroupMember;
import 'package:vortek/core/utils/chat_message_window_util.dart';
import 'package:vortek/core/utils/chat_nav_util.dart';
import 'package:vortek/core/utils/group_sender_util.dart';
import 'package:vortek/models/group_member.dart';
import 'package:vortek/models/quote_message.dart';
import 'package:vortek/theme/im_colors.dart';
import 'package:vortek/theme/im_icons.dart';
import 'package:vortek/widgets/chat/audio_message_bubble.dart';
import 'package:vortek/widgets/chat/bubbles/text_bubble.dart';
import 'package:vortek/widgets/chat/chat_sender_name_row.dart';
import 'package:vortek/widgets/chat/chat_receipt_badge.dart';
import 'package:vortek/widgets/chat/chat_emotion_panel.dart';
import 'package:vortek/widgets/chat/chat_message_menu.dart';
import 'package:vortek/widgets/chat/chat_message_row.dart';
import 'package:vortek/widgets/chat/head_image.dart';
import 'package:vortek/widgets/chat/file_message_bubble.dart';
import 'package:vortek/widgets/chat/financial_card_bubble.dart';
import 'package:vortek/widgets/chat/image_message_bubble.dart';
import 'package:vortek/widgets/chat/message_send_status.dart';
import 'package:vortek/widgets/chat/video_message_bubble.dart';

Message _msg({
  int? id,
  int type = MessageType.text,
  String? content,
  int status = MessageStatus.delivered,
  String? quoteMessage,
  String chatType = ChatType.group,
  bool selfSend = false,
  bool receipt = false,
  bool receiptOk = false,
}) {
  return Message(
    rowId: id ?? 0,
    id: id,
    chatType: chatType,
    chatTargetId: 100,
    sendId: 1,
    type: type,
    content: content,
    status: status,
    sendTime: 1,
    quoteMessage: quoteMessage,
    receipt: receipt,
    receiptOk: receiptOk,
    readedCount: 0,
    selfSend: selfSend,
  );
}

void main() {
  group('ChatMessageMenuBuilder 对齐 uniapp menuItems', () {
    test('文字消息含复制/引用/转发/删除', () {
      final items = ChatMessageMenuBuilder.forMessage(
        msg: _msg(id: 1, content: 'hi'),
        canRecall: true,
        canTop: false,
      );
      expect(items.map((e) => e.key).toList(), [
        'COPY',
        'RECALL',
        'QUOTE',
        'FORWARD',
        'DELETE',
      ]);
    });

    test('群管理员可置顶', () {
      final items = ChatMessageMenuBuilder.forMessage(
        msg: _msg(id: 1, type: MessageType.image, content: '{}'),
        canRecall: false,
        canTop: true,
      );
      expect(items.map((e) => e.key), contains('TOP'));
    });

    test('文件消息含下载并打开且在删除之后', () {
      final items = ChatMessageMenuBuilder.forMessage(
        msg: _msg(id: 1, type: MessageType.file, content: '{"name":"a.pdf"}'),
        canRecall: false,
        canTop: false,
      );
      final keys = items.map((e) => e.key).toList();
      expect(keys.indexOf('DELETE'), lessThan(keys.indexOf('DOWNLOAD')));
    });

    test('无 id 时不出现引用/转发/撤回', () {
      final items = ChatMessageMenuBuilder.forMessage(
        msg: _msg(content: 'sending'),
        canRecall: false,
        canTop: false,
      );
      expect(items.map((e) => e.key), ['COPY', 'DELETE']);
    });

    test('失败文字消息可重发或编辑后重发', () {
      final items = ChatMessageMenuBuilder.forMessage(
        msg: _msg(content: 'failed', status: MessageStatus.failed),
        canRecall: false,
        canTop: false,
      );
      expect(items.map((e) => e.key), [
        'COPY',
        'RESEND',
        'EDIT_RESEND',
        'DELETE',
      ]);
    });

    test('撤回态与 tip 消息无菜单', () {
      expect(
        ChatMessageMenuBuilder.forMessage(
          msg: _msg(id: 1, status: MessageStatus.recall, content: 'x'),
          canRecall: false,
          canTop: false,
        ),
        isEmpty,
      );
      expect(
        ChatMessageMenuBuilder.forMessage(
          msg: _msg(id: 1, type: MessageType.tipTime),
          canRecall: false,
          canTop: false,
        ),
        isEmpty,
      );
    });
  });

  group('ChatMessageMenuBuilder quoteItems', () {
    test('有引用且未撤回时仅定位', () {
      final quote = QuoteMessage(
        id: 9,
        sendId: 2,
        content: '原消息',
        type: MessageType.text,
        status: MessageStatus.delivered,
      );
      final items = ChatMessageMenuBuilder.forQuote(
        _msg(id: 1, quoteMessage: jsonEncode(quote.toJson())),
      );
      expect(items.length, 1);
      expect(items.first.key, 'LOCATE_QUOTE');
    });

    test('引用已撤回时无菜单', () {
      final quote = QuoteMessage(
        id: 9,
        sendId: 2,
        content: '消息已撤回',
        type: MessageType.text,
        status: MessageStatus.recall,
      );
      expect(
        ChatMessageMenuBuilder.forQuote(
          _msg(quoteMessage: jsonEncode(quote.toJson())),
        ),
        isEmpty,
      );
    });
  });

  group('ChatMessageMenu 触点菜单', () {
    test('toLongPressItems 映射 danger 与文案', () {
      final mapped = ChatMessageMenuBuilder.toLongPressItems(const [
        ChatMessageMenuItem(key: 'COPY', label: '复制'),
        ChatMessageMenuItem(key: 'DELETE', label: '删除', danger: true),
      ]);
      expect(mapped.length, 2);
      expect(mapped.first.key, 'COPY');
      expect(mapped.first.name, '复制');
      expect(mapped.last.danger, isTrue);
    });
  });

  group('媒体气泡首帧冒烟', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('ImageMessageBubble 不崩溃', (tester) async {
      await tester.pumpWidget(
        wrap(
          ImageMessageBubble(
            message: _msg(
              id: 1,
              type: MessageType.image,
              content: '{"thumbUrl":"https://example.com/t.jpg"}',
            ),
            selfSend: true,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('FileMessageBubble 显示文件名', (tester) async {
      await tester.pumpWidget(
        wrap(
          FileMessageBubble(
            message: _msg(
              id: 1,
              type: MessageType.file,
              content: '{"name":"合同.pdf","size":1024}',
            ),
            selfSend: false,
          ),
        ),
      );
      expect(find.textContaining('合同.pdf'), findsOneWidget);
    });

    testWidgets('FileMessageBubble 下载中显示进度', (tester) async {
      await tester.pumpWidget(
        wrap(
          FileMessageBubble(
            message: _msg(
              id: 1,
              type: MessageType.file,
              content: '{"name":"合同.pdf","size":1024}',
            ),
            selfSend: false,
            downloadProgress: 42,
          ),
        ),
      );
      expect(find.text('42%'), findsOneWidget);
    });

    testWidgets('TextBubble 含引用块', (tester) async {
      final quote = QuoteMessage(
        id: 2,
        sendId: 3,
        content: 'quoted',
        type: MessageType.text,
        status: MessageStatus.delivered,
      );
      await tester.pumpWidget(
        wrap(
          TextBubble(
            message: _msg(
              id: 1,
              content: 'reply',
              quoteMessage: jsonEncode(quote.toJson()),
            ),
            selfSend: false,
            quoteShowName: '张三',
          ),
        ),
      );
      expect(find.textContaining('张三'), findsOneWidget);
      expect(find.text('reply'), findsOneWidget);
    });
  });

  group('FinancialCardBubble 对齐 uniapp 大卡片', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    test('loanStatusColors 对齐 getLoanStatusClass', () {
      expect(
        FinancialCardBubble.loanStatusColors(36).$2,
        const Color(0xFFFF9800),
      );
      expect(
        FinancialCardBubble.loanStatusColors(32).$2,
        const Color(0xFFF44336),
      );
      expect(
        FinancialCardBubble.loanStatusColors(53).$2,
        const Color(0xFF9C27B0),
      );
    });

    testWidgets('合同卡片展示金额与底部文案', (tester) async {
      await tester.pumpWidget(
        wrap(
          FinancialCardBubble(
            message: _msg(
              id: 1,
              type: MessageType.contractCard,
              content: jsonEncode({
                'title': '借款合同',
                'contractNumber': 'HT20260701',
                'contractAmount': '50000',
                'loanStatus': 43,
                'loanStatusText': '使用中',
              }),
            ),
            selfSend: false,
            variant: FinancialCardVariant.contract,
          ),
        ),
      );
      expect(find.text('借款合同'), findsOneWidget);
      expect(find.text('¥50000'), findsOneWidget);
      expect(find.text('使用中'), findsOneWidget);
      expect(find.text('点击查看合同'), findsOneWidget);
    });

    testWidgets('借款卡片展示产品与状态', (tester) async {
      await tester.pumpWidget(
        wrap(
          FinancialCardBubble(
            message: _msg(
              id: 2,
              type: MessageType.loanCard,
              content: jsonEncode({
                'product': '极速贷',
                'amount': '10000',
                'status': 42,
                'statusText': '放款中',
              }),
            ),
            selfSend: true,
            variant: FinancialCardVariant.loan,
          ),
        ),
      );
      expect(find.text('极速贷'), findsOneWidget);
      expect(find.text('¥10000'), findsOneWidget);
      expect(find.text('放款中'), findsOneWidget);
      expect(find.text('点击查看借款'), findsOneWidget);
    });

    testWidgets('产品卡片格式化最高可借', (tester) async {
      await tester.pumpWidget(
        wrap(
          FinancialCardBubble(
            message: _msg(
              id: 3,
              type: MessageType.productCard,
              content: jsonEncode({
                'productName': '优享贷',
                'loanAmountMax': 200000,
                'minimumYearRate': '3.6%',
              }),
            ),
            selfSend: false,
            variant: FinancialCardVariant.product,
          ),
        ),
      );
      expect(find.text('优享贷'), findsOneWidget);
      expect(find.text('¥200000.00'), findsOneWidget);
      expect(find.text('3.6%'), findsOneWidget);
      expect(find.text('点击查看产品'), findsOneWidget);
    });
  });

  test('表情面板高度对齐 uniapp chatPanelHeight', () {
    expect(kChatPanelHeight, 290);
  });

  group('chat-box P1 状态与标题', () {
    test('groupChatNavTitle 含未退群人数', () {
      expect(
        groupChatNavTitle('测试群', const [
          GroupMember(userId: 1, showNickName: 'A', quit: false),
          GroupMember(userId: 2, showNickName: 'B', quit: true),
          GroupMember(userId: 3, showNickName: 'C', quit: false),
        ]),
        '测试群(2)',
      );
    });

    test('showPrivateReadLabel 仅私聊己方普通消息', () {
      final msg = _msg(
        id: 1,
        chatType: ChatType.private,
        selfSend: true,
        status: MessageStatus.delivered,
      );
      expect(showPrivateReadLabel(msg, true), isTrue);
      expect(
        showPrivateReadLabel(_msg(chatType: ChatType.group), true),
        isFalse,
      );
      expect(
        showPrivateReadLabel(
          _msg(status: MessageStatus.sending, selfSend: true),
          true,
        ),
        isFalse,
      );
    });

    testWidgets('TextBubble 私聊未读使用 danger 色', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextBubble(
              message: _msg(
                id: 1,
                chatType: ChatType.private,
                selfSend: true,
                status: MessageStatus.delivered,
                content: 'hi',
              ),
              selfSend: true,
            ),
          ),
        ),
      );
      final unread = tester.widget<Text>(find.text('未读'));
      expect(unread.style?.color, ImColors.danger);
    });

    testWidgets('ImageMessageBubble 失败显示旁侧重发图标', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageMessageBubble(
              message: _msg(
                id: 1,
                type: MessageType.image,
                status: MessageStatus.failed,
                content: '{"thumbUrl":"https://example.com/t.jpg"}',
                selfSend: true,
              ),
              selfSend: true,
              onResend: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.byIcon(ImIcons.warningCircleFill), findsOneWidget);
      await tester.tap(find.byIcon(ImIcons.warningCircleFill));
      expect(retried, isTrue);
    });

    testWidgets('FileMessageBubble 发送中显示文案', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileMessageBubble(
              message: _msg(
                id: 1,
                type: MessageType.file,
                status: MessageStatus.sending,
                content: '{"name":"合同.pdf","size":1024}',
              ),
              selfSend: true,
            ),
          ),
        ),
      );
      expect(find.text('发送中...'), findsOneWidget);
    });

    testWidgets('ImageMessageBubble 发送中显示上传文案', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageMessageBubble(
              message: _msg(
                id: 1,
                type: MessageType.image,
                status: MessageStatus.sending,
                content: '{"thumbUrl":"https://example.com/t.jpg"}',
              ),
              selfSend: true,
            ),
          ),
        ),
      );
      expect(find.text('上传中…'), findsOneWidget);
    });

    test('ImIcons 语音气泡 codepoint 对齐 iconfont.css', () {
      expect(ImIcons.voicePlay.codePoint, 0xe675);
      expect(ImIcons.play.codePoint, 0xe620);
      expect(ImIcons.pause.codePoint, 0xe669);
    });

    testWidgets('AudioMessageBubble 使用 iconfont voice-play', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioMessageBubble(
              message: _msg(
                id: 1,
                type: MessageType.audio,
                content: '{"duration":5,"url":"https://example.com/a.m4a"}',
              ),
              selfSend: false,
            ),
          ),
        ),
      );
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      expect(
        icons.any(
          (icon) => icon.icon?.codePoint == ImIcons.voicePlay.codePoint,
        ),
        isTrue,
      );
      expect(find.text('5"'), findsOneWidget);
    });

    testWidgets('VideoMessageBubble 私聊已读标签', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoMessageBubble(
              message: _msg(
                id: 1,
                chatType: ChatType.private,
                type: MessageType.video,
                status: MessageStatus.readed,
                content: '{"videoUrl":"https://example.com/v.mp4"}',
                selfSend: true,
              ),
              selfSend: true,
            ),
          ),
        ),
      );
      expect(find.text('已读'), findsOneWidget);
    });

    test('groupSenderRoles 识别群主与管理员', () {
      const members = [
        GroupMember(userId: 1, showNickName: '群主', quit: false),
        GroupMember(
          userId: 2,
          showNickName: '管理',
          quit: false,
          isManager: true,
        ),
      ];
      expect(groupSenderRoles(ownerId: 1, sendId: 1, members: members), {
        GroupSenderRole.owner,
      });
      expect(groupSenderRoles(ownerId: 1, sendId: 2, members: members), {
        GroupSenderRole.manager,
      });
    });

    testWidgets('ChatSenderNameRow 显示群主标签', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatSenderNameRow(name: '张三', roles: {GroupSenderRole.owner}),
          ),
        ),
      );
      expect(find.text('张三'), findsOneWidget);
      expect(find.text('群主'), findsOneWidget);
    });

    testWidgets('ChatReceiptBadge 已确认使用 success 色', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatReceiptBadge(
              message: _msg(
                id: 1,
                receipt: true,
                receiptOk: true,
                selfSend: true,
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, ImColors.success);
    });
  });

  group('ChatMessageWindowUtil 对齐 uniapp 虚拟窗口', () {
    test('常量 pageSize/preloadStep/maxRenderCount', () {
      expect(ChatMessageWindowConfig.pageSize, 15);
      expect(ChatMessageWindowConfig.preloadStep, 10);
      expect(ChatMessageWindowConfig.maxRenderCount, 220);
      expect(ChatMessageWindowConfig.locateMaxLimit, 500);
      expect(ChatMessageWindowConfig.historyMaxLimit, 500);
      expect(ChatMessageWindowConfig.scrollTopThreshold, 28);
      expect(locateHistoryMaxLimit(), 500);
    });

    test('bottomPage 初始窗口为最后一页', () {
      final w = ChatMessageWindowState.bottomPage(200);
      expect(w.showMinIdx, 185);
      expect(w.showMaxIdx, -1);
      expect(w.windowSize(200), 15);
    });

    test('expandHistory 每次减 preloadStep', () {
      const w = ChatMessageWindowState(showMinIdx: 50, showMaxIdx: -1);
      final next = w.expandHistory(totalSize: 200);
      expect(next.showMinIdx, 40);
    });

    test('normalize 裁剪超大窗口', () {
      final w = normalizeMessageWindow(
        showMinIdx: 0,
        showMaxIdx: 300,
        totalSize: 300,
        anchorIdx: 150,
      );
      expect(w.windowSize(300), lessThanOrEqualTo(220));
    });

    test('sliceMessages 按窗口截取', () {
      final messages = List.generate(100, (i) => i);
      final visible = sliceMessages(
        messages: messages,
        window: const ChatMessageWindowState(showMinIdx: 20, showMaxIdx: 40),
      );
      expect(visible, List.generate(20, (i) => i + 20));
    });
  });

  group('MessageType.isTip 对齐 uniapp message-tip', () {
    test('TIP_TIME / TIP_TEXT 为提示行', () {
      expect(MessageType.isTip(MessageType.tipTime), isTrue);
      expect(MessageType.isTip(MessageType.tipText), isTrue);
      expect(MessageType.isTip(MessageType.text), isFalse);
    });

    testWidgets('TIP_TEXT 气泡居中且无头像', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageTipRow(
              child: TextBubble(
                message: _msg(
                  type: MessageType.tipText,
                  content: "'小巴黎'邀请'user_1'加入了群聊",
                ),
                selfSend: true,
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('加入了群聊'), findsOneWidget);
      expect(find.byType(HeadImage), findsNothing);
    });

    testWidgets('TIP_TEXT 长文案换行不被裁切', (tester) async {
      const longTip = "'15333333333'邀请'user_13444444444,15111111111,小巴黎'加入了群聊";
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ChatMessageTipRow(
                child: TextBubble(
                  message: _msg(type: MessageType.tipText, content: longTip),
                  selfSend: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.textContaining('加入了群聊'));
      expect(box.height, greaterThan(40));
    });
  });
}
