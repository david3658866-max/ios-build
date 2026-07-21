import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vortek/main.dart' as app;

/// 真机：登录 → 进入分页测试群 → 验证首屏只加载 30 条。
const _phone = '15222222222';
const _password = '123456';

/// 与 verify-chat-page-load-e2e.js 最新群名前缀一致；列表按时间排序，匹配任一即可。
const _testGroupPrefix = '分页加载测试-';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('真机：分页测试群进页只拉 30 条', (tester) async {
    app.main();
    await _waitForSettle(tester, const Duration(seconds: 25));
    await _dismissPolicyIfNeeded(tester);

    if (find.text('消息').evaluate().isEmpty) {
      await tester.enterText(
        find.byKey(const Key('login_phone_field')),
        _phone,
      );
      await tester.enterText(
        find.byKey(const Key('login_password_field')),
        _password,
      );
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await _waitForSettle(tester, const Duration(seconds: 60));
    }

    expect(find.text('消息'), findsWidgets);

    // 等待会话同步（sessionSummary 含测试群）。
    Finder groupTile = find.textContaining(_testGroupPrefix);
    final syncDeadline = DateTime.now().add(const Duration(seconds: 45));
    while (DateTime.now().isBefore(syncDeadline)) {
      await tester.pump(const Duration(milliseconds: 500));
      groupTile = find.textContaining(_testGroupPrefix);
      if (groupTile.evaluate().isNotEmpty) break;
    }

    expect(
      groupTile,
      findsWidgets,
      reason: '消息列表应出现「$_testGroupPrefix」测试群，请先运行 verify-chat-page-load-e2e.js',
    );

    await tester.tap(groupTile.first);
    await _waitForSettle(tester, const Duration(seconds: 35));

    // 等待离线拉取完成后再断言（logcat: [Offline] chat offline pull GROUP count=30）。
    final msgDeadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(msgDeadline)) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.textContaining('80/80').evaluate().isNotEmpty) break;
    }

    // 首屏应显示最新一条（第 80 条），不应出现第 1 条（说明未一次性渲染 80 条）。
    expect(find.textContaining('80/80'), findsWidgets);
    expect(find.textContaining('第 1/80'), findsNothing);

    // 上滑加载更早消息。
    final list = find.byType(Scrollable);
    for (var i = 0; i < 4; i++) {
      if (list.evaluate().isEmpty) break;
      await tester.drag(list.first, const Offset(0, 500));
      await _waitForSettle(tester, const Duration(seconds: 5));
    }
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
