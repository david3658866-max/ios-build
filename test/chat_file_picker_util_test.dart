import 'package:flutter_test/flutter_test.dart';

import 'package:vortek/core/utils/chat_file_picker_util.dart';
import 'package:vortek/core/utils/chat_media_util.dart';

void main() {
  group('ChatFilePickerUtil', () {
    test('maxFileCount 对齐 uniapp lsj-upload count=9', () {
      expect(ChatMediaUtil.maxFileCount, 9);
    });
  });
}
