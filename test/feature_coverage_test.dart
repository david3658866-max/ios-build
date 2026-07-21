import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/feature_registry.dart';

void main() {
  test('P0 功能均已自动化或已登记须真人验收', () {
    final gaps = FeatureRegistry.automationGaps;
    expect(
      gaps,
      isEmpty,
      reason: gaps.map((f) => '${f.id}: ${f.title}').join('\n'),
    );
  });

  test('须真人验收项均有原因说明', () {
    final bad = FeatureRegistry.manualOnly
        .where((f) => f.manualReason == null || f.manualReason!.trim().isEmpty);
    expect(bad, isEmpty, reason: bad.map((f) => f.id).join(', '));
  });

  test('自动化登记引用的测试文件均存在', () {
    final root = Directory.current;
    final missing = <String>[];
    for (final f in FeatureRegistry.all) {
      for (final path in f.testFiles) {
        if (path.endsWith('.ps1')) continue;
        final file = File('${root.path}/$path');
        if (!file.existsSync()) missing.add(path);
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('功能注册表规模合理（防漏登记）', () {
    expect(FeatureRegistry.all.length, greaterThanOrEqualTo(40));
    expect(FeatureRegistry.p0.length, greaterThanOrEqualTo(25));
    expect(FeatureRegistry.manualOnly.length, greaterThanOrEqualTo(10));
  });
}
