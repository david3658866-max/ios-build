import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/models/system_message.dart';

void main() {
  test('SystemMessage.fromJson 兼容 SeqNo 大写与 ISO sendTime', () {
    final msg = SystemMessage.fromJson({
      'id': '1001',
      'SeqNo': '42',
      'title': '公告',
      'sendTime': '2026-07-01T06:06:29.000+00:00',
      'type': '1',
      'status': '0',
    });

    expect(msg.id, 1001);
    expect(msg.seqNo, 42);
    expect(msg.title, '公告');
    expect(msg.sendTime, isNotNull);
    expect(msg.type, 1);
  });

  test('SystemMessage.fromJson 兼容 seqNo 小写', () {
    final msg = SystemMessage.fromJson({
      'id': 2,
      'seqNo': 7,
      'sendTime': '1719797189000',
    });

    expect(msg.seqNo, 7);
    expect(msg.sendTime, 1719797189000);
  });
}
