import 'package:flutter_test/flutter_test.dart';

import 'package:vortek/core/utils/chat_audio_record_util.dart';
import 'package:vortek/core/utils/chat_media_util.dart';

void main() {
  group('ChatAudioRecordUtil', () {
    test('durationSeconds 四舍五入对齐 uniapp upload', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      expect(
        ChatAudioRecordUtil.durationSeconds(
          start,
          start.add(const Duration(milliseconds: 1600)),
        ),
        2,
      );
      expect(
        ChatAudioRecordUtil.durationSeconds(
          start,
          start.add(const Duration(milliseconds: 400)),
        ),
        0,
      );
    });

    test('录音上限 60s', () {
      expect(ChatMediaUtil.maxAudioDurationSec, 60);
      expect(ChatMediaUtil.minAudioDurationSec, 1);
    });
  });
}
