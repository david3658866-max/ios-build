import 'dart:math';

/// 消息临时 id，对齐 UniApp `chat-box.vue` 的 `generateId()`。
///
/// 后端 `im_group_message.tmp_id` / `im_private_message.tmp_id` 为 varchar(32)，
/// UUID v4（36 字符）会触发 Data truncation → API 500。
class MessageTmpId {
  MessageTmpId._();

  static final _random = Random();
  static String _maxTmpId = '';

  /// 时间戳 + 3 位随机数，保证单调递增（与 UniApp 一致）。
  static String next() {
    while (true) {
      final id =
          '${DateTime.now().millisecondsSinceEpoch}${_random.nextInt(1000)}';
      if (_maxTmpId.compareTo(id) > 0) continue;
      _maxTmpId = id;
      return id;
    }
  }
}
