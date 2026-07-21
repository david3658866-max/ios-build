import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/theme/im_colors.dart';
import 'package:vortek/widgets/im_confirm_dialog.dart';
import 'package:vortek/widgets/im_loading.dart';
import 'package:vortek/widgets/im_nav_bar.dart';
import 'package:vortek/widgets/im_toast.dart';

void main() {
  tearDown(() {
    ImToast.hide();
    ImLoading.reset();
  });

  group('ImToast 对齐 uni.showToast', () {
    testWidgets('居中显示并在超时后消失', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ImToast.show(ctx, '复制成功'),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.text('复制成功'), findsOneWidget);
      final toastText = tester.widget<Text>(find.text('复制成功'));
      expect(toastText.style?.color, Colors.white);

      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump();
      expect(find.text('复制成功'), findsNothing);
    });
  });

  group('ImLoading 对齐 uni.showLoading', () {
    testWidgets('显示遮罩与进度圈', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ImLoading.show(ctx, title: '加载中'),
                child: const Text('load'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('load'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('加载中'), findsOneWidget);

      ImLoading.hide();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('嵌套 show/hide 引用计数', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ImLoading.show(ctx),
                child: const Text('load'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('load'));
      await tester.pump();
      final ctx = tester.element(find.byType(Scaffold));
      ImLoading.show(ctx);
      ImLoading.hide();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      ImLoading.hide();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('showImConfirmDialog 对齐 popup-modal', () {
    testWidgets('取消与确定返回 bool', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Column(
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      result = await showImConfirmDialog(
                        ctx,
                        title: '删除会话',
                        content: '确认删除该会话？',
                      );
                    },
                    child: const Text('open'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('删除会话'), findsOneWidget);
      expect(find.text('确认删除该会话？'), findsOneWidget);

      final cancel = find.text('取消');
      expect(tester.widget<Text>(cancel).style?.color, ImColors.danger);
      final confirm = find.text('确定');
      expect(tester.widget<Text>(confirm).style?.color, ImColors.accent);

      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  group('ImNavBar 标题对齐', () {
    testWidgets('默认居中', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(appBar: ImNavBar(title: '好友')),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('titleAlign left 时左对齐', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: ImNavBar(title: '消息', titleAlign: TextAlign.left),
          ),
        ),
      );
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.centerTitle, isFalse);
    });
  });
}
