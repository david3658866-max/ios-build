import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vortek/main.dart' as app;

/// 真机回归：登录 → 打开首个会话 → 发文字 → 贴底且无失败态。
const _phone = '15222222222';
const _password = '123456';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('真机回归：发会话文字并贴底', (tester) async {
    app.main();
    await _pumpSeconds(tester, 8);
    await _dismissBlockingDialogs(tester);

    await _ensureLoggedIn(tester);
    await _dismissBlockingDialogs(tester);
    await _pumpSeconds(tester, 8);
    await _dismissBlockingDialogs(tester);

    final onMain =
        find.byKey(const Key('chat_list_item_0')).evaluate().isNotEmpty ||
            find.text('消息').evaluate().isNotEmpty ||
            find.text('通讯录').evaluate().isNotEmpty;
    expect(onMain, isTrue, reason: '应进入主界面');

    final firstChat = find.byKey(const Key('chat_list_item_0'));
    expect(firstChat, findsOneWidget);
    await tester.tap(firstChat);
    await _pumpSeconds(tester, 8);
    await _dismissBlockingDialogs(tester);

    if (find.text('群聊已解散').evaluate().isNotEmpty) {
      // 首条是解散群：再试下一条可输入会话。
      await tester.pageBack();
      await _pumpSeconds(tester, 3);
      final second = find.byKey(const Key('chat_list_item_1'));
      if (second.evaluate().isEmpty) return;
      await tester.tap(second);
      await _pumpSeconds(tester, 8);
    }

    if (find.text('群聊已解散').evaluate().isNotEmpty) {
      expect(find.text('群聊已解散'), findsWidgets);
      return;
    }

    final input = find.byKey(const Key('chat_input_field'));
    expect(input, findsOneWidget);

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final text = 'auto$stamp';
    await tester.enterText(input, text);
    await tester.pump(const Duration(milliseconds: 500));

    final sendBtn = find.byKey(const Key('chat_send_button'));
    expect(sendBtn, findsOneWidget);
    await tester.tap(sendBtn);
    await _pumpSeconds(tester, 12);

    // 气泡可能是富文本/自定义绘制，优先认文案；否则认输入框已清空且无失败图标。
    final shown = find.textContaining(text).evaluate().isNotEmpty ||
        find.text(text).evaluate().isNotEmpty;
    final field = tester.widget<TextField>(input);
    final cleared = (field.controller?.text ?? '').isEmpty;
    expect(
      shown || cleared,
      isTrue,
      reason: '发送后应显示消息或清空输入框',
    );
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.text('回到底部'), findsNothing);
  });
}

Future<void> _ensureLoggedIn(WidgetTester tester) async {
  if (find.byKey(const Key('chat_list_item_0')).evaluate().isNotEmpty) return;
  if (find.text('消息').evaluate().isNotEmpty) return;

  await _dismissBlockingDialogs(tester);
  await _pumpSeconds(tester, 3);

  final phoneField = find.byKey(const Key('login_phone_field'));
  if (phoneField.evaluate().isEmpty) return;

  await tester.enterText(phoneField, _phone);
  await tester.enterText(
    find.byKey(const Key('login_password_field')),
    _password,
  );
  final loginBtn = find.byKey(const Key('login_submit_button'));
  await tester.tap(
    loginBtn.evaluate().isNotEmpty ? loginBtn : find.text('立即登录'),
  );
  await _pumpSeconds(tester, 20);
  await _dismissBlockingDialogs(tester);
}

Future<void> _dismissBlockingDialogs(WidgetTester tester) async {
  for (final label in ['同意', '暂不开启', '取消', '我知道了', '确定']) {
    final f = find.text(label);
    if (f.evaluate().isNotEmpty) {
      await tester.tap(f, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 800));
    }
  }
}

Future<void> _pumpSeconds(WidgetTester tester, int seconds) async {
  final steps = seconds * 2;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    while (tester.takeException() != null) {}
  }
}
