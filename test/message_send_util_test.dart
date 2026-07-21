import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/core/utils/message_resend_util.dart';
import 'package:vortek/core/utils/message_send_queue.dart';

void main() {
  group('MessageSendQueue 对齐 uniapp reqQueue', () {
    test('串行执行，后任务等待前任务完成', () async {
      final queue = MessageSendQueue();
      final log = <int>[];

      final first = queue.run(() async {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        log.add(1);
      });
      final second = queue.run(() async {
        log.add(2);
      });

      await Future.wait([first, second]);
      expect(log, [1, 2]);
    });

    test('前任务失败不阻塞后续任务', () async {
      final queue = MessageSendQueue();
      var done = false;

      try {
        await queue.run(() async {
          throw StateError('fail');
        });
      } catch (_) {}

      await queue.run(() async {
        done = true;
      });

      expect(done, isTrue);
    });
  });

  group('MessageResendUtil 对齐 uniapp onResendMessage', () {
    test('uniapp 自动重发仅 TEXT', () {
      expect(MessageResendUtil.canUniappAutoResend(MessageType.text), isTrue);
      expect(
        MessageResendUtil.canUniappAutoResend(MessageType.image),
        isFalse,
      );
    });

    test('Flutter 旁侧支持文字/语音，媒体可选', () {
      expect(
        MessageResendUtil.supportsSideResend(MessageType.audio),
        isTrue,
      );
      expect(
        MessageResendUtil.supportsSideResend(MessageType.image),
        isFalse,
      );
      expect(
        MessageResendUtil.supportsSideResend(
          MessageType.image,
          sideFailForMedia: true,
        ),
        isTrue,
      );
    });
  });
}
