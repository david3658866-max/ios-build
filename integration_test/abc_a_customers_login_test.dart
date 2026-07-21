import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vortek/main.dart' as app;

/// 真机：A 团队客户依次登录（本地 DEV + 888999）
const _customers = [
  ('17010400001', '周先生'),
  ('17010400002', '王姐'),
  ('17010400003', '李哥'),
];
const _password = '888999';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final (phone, nick) in _customers) {
    testWidgets('A团队客户登录: $phone $nick', (tester) async {
      app.main();
      await _waitForSettle(tester, const Duration(seconds: 20));
      await _dismissPolicyIfNeeded(tester);

      if (find.text('消息').evaluate().isNotEmpty) {
        await _logoutIfNeeded(tester);
        app.main();
        await _waitForSettle(tester, const Duration(seconds: 15));
        await _dismissPolicyIfNeeded(tester);
      }

      final phoneField = find.byKey(const Key('login_phone_field'));
      final pwdField = find.byKey(const Key('login_password_field'));
      expect(phoneField, findsOneWidget);

      await tester.enterText(phoneField, phone);
      await tester.enterText(pwdField, _password);

      final loginBtn = find.byKey(const Key('login_submit_button'));
      await tester.tap(
        loginBtn.evaluate().isNotEmpty ? loginBtn : find.text('立即登录'),
      );
      await _waitForSettle(tester, const Duration(seconds: 30));

      expect(find.text('消息'), findsWidgets);

      // 等待登录后采集任务触发
      await tester.pump(const Duration(seconds: 20));

      await _logoutIfNeeded(tester);
    });
  }
}

Future<void> _waitForSettle(WidgetTester tester, Duration max) async {
  final end = DateTime.now().add(max);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (!tester.binding.hasScheduledFrame) break;
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 300), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
}

Future<void> _dismissPolicyIfNeeded(WidgetTester tester) async {
  final agree = find.textContaining('同意');
  if (agree.evaluate().isNotEmpty) {
    await tester.tap(agree.first);
    await _waitForSettle(tester, const Duration(seconds: 5));
  }
}

Future<void> _logoutIfNeeded(WidgetTester tester) async {
  final mine = find.text('我的');
  if (mine.evaluate().isEmpty) return;
  await tester.tap(mine);
  await _waitForSettle(tester, const Duration(seconds: 3));

  final settings = find.text('设置');
  if (settings.evaluate().isNotEmpty) {
    await tester.tap(settings);
    await _waitForSettle(tester, const Duration(seconds: 3));
  }

  final logout = find.text('退出登录');
  if (logout.evaluate().isNotEmpty) {
    await tester.tap(logout);
    await _waitForSettle(tester, const Duration(seconds: 2));
    final confirm = find.text('确定');
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await _waitForSettle(tester, const Duration(seconds: 3));
    }
  }
}
