import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/message_tmp_id.dart';

void main() {
  test('MessageTmpId 长度不超过 32 且递增', () {
    final a = MessageTmpId.next();
    final b = MessageTmpId.next();
    expect(a.length, lessThanOrEqualTo(32));
    expect(b.length, lessThanOrEqualTo(32));
    expect(b.compareTo(a), greaterThanOrEqualTo(0));
  });
}
