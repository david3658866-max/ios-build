import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/date_util.dart';

void main() {
  group('DateUtil.toTimeText 对齐 uniapp date.js', () {
    final now = DateTime(2026, 7, 1, 15, 0);

    test('1 分钟内显示刚刚', () {
      final ms = now.subtract(const Duration(seconds: 30)).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, now: now), '刚刚');
    });

    test('1 小时内显示 N 分钟前', () {
      final ms = now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, now: now), '5分钟前');
    });

    test('今日超过 1 小时显示 HH:mm', () {
      final ms = DateTime(2026, 7, 1, 10, 30).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, now: now), '10:30');
    });

    test('昨天显示昨天HH:mm 无空格', () {
      final ref = DateTime(2026, 7, 15, 15, 0);
      final ms = DateTime(2026, 7, 14, 9, 15).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, now: ref), '昨天09:15');
    });

    test('今年较早日期显示 MM/dd HH:mm:ss 片段', () {
      final ms = DateTime(2026, 3, 15, 8, 5, 7).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, now: now), '03/15 08:05:07');
    });

    test('非今年显示完整 yyyy/MM/dd HH:mm:ss', () {
      final ms = DateTime(2025, 12, 1, 8, 5, 7).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, now: now), '2025/12/01 08:05:07');
    });

    test('simple 模式今年仅 MM/dd', () {
      final ms = DateTime(2026, 3, 15, 8, 5).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, simple: true, now: now), '03/15');
    });

    test('simple 模式非今年 yy/MM/dd', () {
      final ms = DateTime(2025, 12, 1, 8, 5).millisecondsSinceEpoch;
      expect(DateUtil.toTimeText(ms, simple: true, now: now), '25/12/01');
    });
  });

  group('DateUtil.formatBubbleTime', () {
    test('委托 toTimeText 非 simple', () {
      final now = DateTime(2026, 7, 1, 15, 0);
      final ms = now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch;
      expect(DateUtil.formatBubbleTime(ms, now: now), '2分钟前');
    });
  });

  group('DateUtil.needTimeDivider', () {
    test('间隔超过 10 分钟需要分隔', () {
      expect(DateUtil.needTimeDivider(0, 11 * 60 * 1000), isTrue);
      expect(DateUtil.needTimeDivider(0, 9 * 60 * 1000), isFalse);
    });
  });
}
