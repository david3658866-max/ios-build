import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/message_storage_util.dart';

void main() {
  group('MessageStorageConfig 对齐 uniapp fliterMessage', () {
    test('默认上限 5000/1000', () {
      expect(MessageStorageConfig.maxTotalMessages, 5000);
      expect(MessageStorageConfig.maxPerChatMessages, 1000);
    });
  });
}
