import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vortek/main.dart' as app;

/// 真机/模拟器冒烟：冷启动 → 登录（如需）→ 消息 Tab。
const _phone = '15222222222';
const _password = '123456';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('真机冒烟：登录并进入消息 Tab', (tester) async {
    app.main();
    await _waitForSettle(tester, const Duration(seconds: 25));

    await _dismissPolicyIfNeeded(tester);

    // 已登录冷启动会直接进入主框架。
    if (find.text('消息').evaluate().isNotEmpty) {
      expect(find.text('消息'), findsWidgets);
      return;
    }

    final loginBtn = find.byKey(const Key('login_submit_button'));
    if (loginBtn.evaluate().isEmpty) {
      expect(find.text('立即登录'), findsOneWidget);
    }

    await tester.enterText(find.byKey(const Key('login_phone_field')), _phone);
    await tester.enterText(find.byKey(const Key('login_password_field')), _password);
    await tester.tap(loginBtn.evaluate().isNotEmpty
        ? loginBtn
        : find.text('立即登录'));
    await _waitForSettle(tester, const Duration(seconds: 45));

    expect(find.text('消息'), findsWidgets);
  });
}

Future<void> _waitForSettle(
  WidgetTester tester,
  Duration maxWait, {
  Duration step = const Duration(milliseconds: 500),
}) async {
  final deadline = DateTime.now().add(maxWait);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(step);
    if (!tester.binding.hasScheduledFrame) {
      await tester.pump(step);
      if (!tester.binding.hasScheduledFrame) return;
    }
  }
  await tester.pump(step);
}

Future<void> _dismissPolicyIfNeeded(WidgetTester tester) async {
  final agree = find.text('同意');
  if (agree.evaluate().isEmpty) return;
  await tester.tap(agree);
  await _waitForSettle(tester, const Duration(seconds: 5));
}
