/// 时间工具。后端时间字段统一为毫秒时间戳(int)。
/// 气泡/会话时间对齐 im-uniapp `common/date.js` `toTimeText`。
abstract final class DateUtil {
  static const List<String> _weekdays = [
    '周一', '周二', '周三', '周四', '周五', '周六', '周日',
  ];

  /// uniapp `$date.toTimeText(timeStamp, simple)`。
  static String toTimeText(
    int? ms, {
    bool simple = false,
    DateTime? now,
  }) {
    if (ms == null || ms <= 0) return '';
    final current = now ?? DateTime.now();
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    final timeDiff = current.millisecondsSinceEpoch - ms;

    if (timeDiff <= 60000) return '刚刚';
    if (timeDiff > 60000 && timeDiff < 3600000) {
      return '${timeDiff ~/ 60000}分钟前';
    }
    if (timeDiff >= 3600000 &&
        timeDiff < 86400000 &&
        !_isYestday(t, current)) {
      return _hhmm(t);
    }
    if (_isYestday(t, current)) {
      return '昨天${_hhmm(t)}';
    }
    if (t.year == current.year) {
      final full = _formatDateTime(t);
      return simple ? full.substring(5, 10) : full.substring(5, 19);
    }
    final full = _formatDateTime(t);
    return simple ? full.substring(2, 10) : full;
  }

  /// 聊天气泡时间分隔。`toTimeText` 非 simple 模式。
  static String formatBubbleTime(int? ms, {DateTime? now}) =>
      toTimeText(ms, now: now);

  /// 会话列表时间：今天 HH:mm，昨天「昨天」，本周周几，更早日期。
  static String formatSessionTime(int? ms) {
    if (ms == null || ms <= 0) return '';
    final now = DateTime.now();
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diffDays = today.difference(day).inDays;

    if (diffDays == 0) return _hhmm(t);
    if (diffDays == 1) return '昨天';
    if (diffDays > 1 && diffDays < 7) return _weekdays[t.weekday - 1];
    if (t.year == now.year) return '${_pad2(t.month)}-${_pad2(t.day)}';
    return '${t.year}-${_pad2(t.month)}-${_pad2(t.day)}';
  }

  /// 两条气泡间隔超过 10 分钟才显示时间分隔（对齐 chatStore insertMessage）。
  static bool needTimeDivider(int? prevMs, int? curMs) {
    if (curMs == null) return false;
    if (prevMs == null) return true;
    return (curMs - prevMs).abs() > 10 * 60 * 1000;
  }

  /// 聊天记录图片页分组标题。对齐 chat-history-image `timeText`。
  static String historyMediaGroupLabel(int? ms) {
    if (ms == null || ms <= 0) return '';
    final now = DateTime.now();
    final t = DateTime.fromMillisecondsSinceEpoch(ms);
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diffDays = today.difference(day).inDays;
    if (diffDays >= 0 && diffDays < 7) return '本周';
    if (t.year == now.year && t.month == now.month) return '本月';
    return '${t.year}-${_pad2(t.month)}';
  }

  /// 对齐 date.js `isYestday`（含同月约束）。
  static bool _isYestday(DateTime date, DateTime now) {
    final yesterday = now.subtract(const Duration(hours: 24));
    return _isMonth(date, now) && yesterday.day == date.day;
  }

  static bool _isMonth(DateTime date, DateTime now) =>
      date.year == now.year && date.month == now.month;

  static String _formatDateTime(DateTime t) =>
      '${t.year}/${_pad2(t.month)}/${_pad2(t.day)} '
      '${_hhmm(t)}:${_pad2(t.second)}';

  static String _hhmm(DateTime t) => '${_pad2(t.hour)}:${_pad2(t.minute)}';
  static String _pad2(int n) => n.toString().padLeft(2, '0');
}
