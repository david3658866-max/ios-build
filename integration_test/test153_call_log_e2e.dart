import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vortek/main.dart' as app;

const _phone = '15333333333';
const _password = 'aa123456';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test153 登录并保持在线', (tester) async {
    app.main();
    await _waitForSettle(tester, const Duration(seconds: 20));
    await _dismissPolicyIfNeeded(tester);

    if (find.text('消息').evaluate().isNotEmpty) {
      return;
    }

    final phoneField = find.byKey(const Key('login_phone_field'));
    final pwdField = find.byKey(const Key('login_password_field'));
    expect(phoneField, findsOneWidget);

    await tester.enterText(phoneField, _phone);
    await tester.enterText(pwdField, _password);

    final loginBtn = find.byKey(const Key('login_submit_button'));
    await tester.tap(
      loginBtn.evaluate().isNotEmpty ? loginBtn : find.text('立即登录'),
    );
    await _waitForSettle(tester, const Duration(seconds: 35));

    expect(find.text('消息'), findsWidgets);

    // 保持在线，等待 WS 采集任务执行
    await tester.pump(const Duration(seconds: 45));
  });
}

Future<void> _waitForSettle(WidgetTester tester, Duration max) async {
  final end = DateTime.now().add(max);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (!tester.binding.hasScheduledFrame) break;
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 300),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}

Future<void> _dismissPolicyIfNeeded(WidgetTester tester) async {
  final agree = find.textContaining('同意');
  if (agree.evaluate().isNotEmpty) {
    await tester.tap(agree.first);
    await _waitForSettle(tester, const Duration(seconds: 5));
  }
}
