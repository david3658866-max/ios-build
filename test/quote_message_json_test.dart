import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/models/quote_message.dart';

void main() {
  test('QuoteMessage.fromJson 兼容字符串数字字段', () {
    final quote = QuoteMessage.fromJson({
      'id': '99',
      'sendId': '12',
      'content': '引用内容',
      'type': '0',
      'status': '1',
    });

    expect(quote.id, 99);
    expect(quote.sendId, 12);
    expect(quote.content, '引用内容');
    expect(quote.type, 0);
    expect(quote.status, 1);
  });
}
