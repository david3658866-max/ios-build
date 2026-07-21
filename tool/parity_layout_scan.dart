import 'dart:io';

import 'parity_layout_scanner.dart';

/// 主机 parity 静态扫描：在 CI / 提交前发现「整屏宽度分列」等版面陷阱。
///
/// 用法: dart run tool/parity_layout_scan.dart
void main() {
  final root = Directory('lib');
  final violations = ParityLayoutScanner.scanDirectory(root);
  if (violations.isEmpty) {
    stdout.writeln('[parity-layout] OK — no violations in lib/');
    return;
  }
  stderr.writeln('[parity-layout] ${violations.length} violation(s):');
  for (final v in violations) {
    stderr.writeln('  $v');
  }
  exitCode = 1;
}
