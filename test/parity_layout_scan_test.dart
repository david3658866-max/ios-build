import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/parity_layout_scanner.dart';

void main() {
  test('lib/ 无版面反模式（整屏分列、表情死写 4 列等）', () {
    final violations = ParityLayoutScanner.scanDirectory(Directory('lib'));
    expect(
      violations,
      isEmpty,
      reason: violations.map((v) => v.toString()).join('\n'),
    );
  });
}
