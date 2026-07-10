import 'package:record/record.dart';

import 'chat_media_util.dart';

/// 聊天语音录制参数。对齐 uniapp `recorder-app.js` + `chat-record.vue`。
abstract final class ChatAudioRecordUtil {
  ChatAudioRecordUtil._();

  static RecordConfig recordConfig() {
    return const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      numChannels: 1,
    );
  }

  static String newTempPath(String dir) {
    return '$dir/voice_${DateTime.now().millisecondsSinceEpoch}.${ChatMediaUtil.audioFileExtension}';
  }

  /// 对齐 uniapp upload()：按实际录音时长（秒）四舍五入。
  static int durationSeconds(DateTime start, DateTime end) {
    final ms = end.difference(start).inMilliseconds;
    return (ms / 1000).round().clamp(0, ChatMediaUtil.maxAudioDurationSec);
  }
}
