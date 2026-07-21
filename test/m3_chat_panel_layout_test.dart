import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/widgets/chat/chat_emotion_panel.dart';
import 'package:vortek/widgets/chat/chat_tools_panel.dart';

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1624);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  group('ChatToolsPanel 对齐 uniapp 25% 四列', () {
    testWidgets('文件/相册/拍摄/视频首行同一行', (tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatToolsPanel(
              height: 290,
              isGroup: false,
              isReceipt: false,
              onToggleReceipt: () {},
              onPickFile: () {},
              onPickAlbum: () {},
              onPickCamera: () {},
              onPickVideo: () {},
              onPickVoice: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final fileY = tester.getTopLeft(find.text('文件')).dy;
      final albumY = tester.getTopLeft(find.text('相册')).dy;
      final cameraY = tester.getTopLeft(find.text('拍摄')).dy;
      final videoY = tester.getTopLeft(find.text('视频')).dy;

      expect(albumY, fileY);
      expect(cameraY, fileY);
      expect(videoY, fileY);

      final fileX = tester.getTopLeft(find.text('文件')).dx;
      final albumX = tester.getTopLeft(find.text('相册')).dx;
      final cameraX = tester.getTopLeft(find.text('拍摄')).dx;
      final videoX = tester.getTopLeft(find.text('视频')).dx;

      expect(albumX, greaterThan(fileX));
      expect(cameraX, greaterThan(albumX));
      expect(videoX, greaterThan(cameraX));
    });
  });

  group('ChatEmotionPanel 对齐 uniapp flex 换行', () {
    testWidgets('首行表情数量大于 4', (tester) async {
      _usePhoneViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatEmotionPanel(onSelect: (_) {}),
          ),
        ),
      );
      await tester.pump();

      final y0 = tester.getTopLeft(find.byType(InkWell).first).dy;
      var sameRow = 0;
      final count = tester.widgetList(find.byType(InkWell)).length;
      for (var i = 0; i < count && i < 12; i++) {
        final y = tester.getTopLeft(find.byType(InkWell).at(i)).dy;
        if ((y - y0).abs() < 2) sameRow++;
      }
      expect(sameRow, greaterThan(4));
    });
  });
}
