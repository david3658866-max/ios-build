import 'dart:io';

import 'feature_registry.dart';

/// 从功能注册表生成验收报告与真人清单。
///
/// 用法: dart run tool/generate_acceptance_report.dart
void main() {
  final root = Directory.current;
  final docsDir = Directory('${root.path}/docs');
  if (!docsDir.existsSync()) docsDir.createSync(recursive: true);

  final all = FeatureRegistry.all;
  final p0 = FeatureRegistry.p0;
  final manual = FeatureRegistry.manualOnly;
  final autoCount = all.where((f) => f.hasAutomation && !f.manualOnly).length;
  final p0Auto = p0.where((f) => f.hasAutomation).length;
  final p0Manual = p0.where((f) => f.manualOnly).length;

  stdout.writeln('[acceptance] features=${all.length} p0=${p0.length}');
  stdout.writeln('[acceptance] automated=$autoCount p0_auto=$p0Auto p0_manual=$p0Manual');
  stdout.writeln('[acceptance] human_only=${manual.length}');

  final humanMd = _buildHumanOnlyMarkdown(manual);
  File('${docsDir.path}/human-only-acceptance.md').writeAsStringSync(humanMd);

  final matrixMd = _buildMatrixMarkdown(all, p0, manual);
  File('${docsDir.path}/acceptance-matrix.md').writeAsStringSync(matrixMd);

  stdout.writeln('[acceptance] wrote docs/human-only-acceptance.md');
  stdout.writeln('[acceptance] wrote docs/acceptance-matrix.md');
}

String _buildHumanOnlyMarkdown(List<FeatureSpec> manual) {
  final byModule = <String, List<FeatureSpec>>{};
  for (final f in manual) {
    byModule.putIfAbsent(f.module, () => []).add(f);
  }

  final buf = StringBuffer()
    ..writeln('# 须真人验收清单（自动生成）')
    ..writeln()
    ..writeln('> 由 `dart run tool/generate_acceptance_report.dart` 从 `tool/feature_registry.dart` 生成。')
    ..writeln('> 测试账号：`15222222222` / `123456` · 对照同账号 im-uniapp 真机')
    ..writeln()
    ..writeln('下列项 **自动化无法替代**（权限、双机、感官、网络切换等）。验收时逐项勾选 Flutter 列。')
    ..writeln()
    ..writeln('---')
    ..writeln();

  var idx = 1;
  for (final module in byModule.keys.toList()..sort()) {
    buf.writeln('## $idx. $module');
    buf.writeln();
    for (final f in byModule[module]!) {
      final pri = f.priority == FeaturePriority.p0 ? '**P0**' : 'P1+';
      buf.writeln('- [ ] **${f.title}** ($pri)');
      buf.writeln('  - 原因：${f.manualReason ?? "—"}');
      if (f.checklistDoc != null) {
        buf.writeln('  - 细项：${f.checklistDoc}');
      }
      buf.writeln();
    }
    idx++;
  }

  buf
    ..writeln('---')
    ..writeln()
    ..writeln('## 问题记录')
    ..writeln()
    ..writeln('| 功能 | 现象 | 截图/备注 |')
    ..writeln('|------|------|-----------|')
    ..writeln('|      |      |           |');

  return buf.toString();
}

String _buildMatrixMarkdown(
  List<FeatureSpec> all,
  List<FeatureSpec> p0,
  List<FeatureSpec> manual,
) {
  final byModule = <String, List<FeatureSpec>>{};
  for (final f in all.where((f) => f.priority != FeaturePriority.outOfScope)) {
    byModule.putIfAbsent(f.module, () => []).add(f);
  }

  final buf = StringBuffer()
    ..writeln('# 功能验收矩阵（自动生成）')
    ..writeln()
    ..writeln('> 总功能 **${all.length}** · P0 **${p0.length}** · 须真人 **${manual.length}**')
    ..writeln('> 生成：`dart run tool/generate_acceptance_report.dart`')
    ..writeln()
    ..writeln('## 四层自动化')
    ..writeln()
    ..writeln('| 层 | 覆盖 | 命令 |')
    ..writeln('|----|------|------|')
    ..writeln('| L1 逻辑/Store | WS 分发、离线、发送队列、鉴权 | `flutter test test/*_test.dart` |')
    ..writeln('| L2 Widget 契约 | 页面组件行为、路由不串页 | `flutter test test/m3_*_test.dart` |')
    ..writeln('| L3 API 真链路 | 登录、发送、只读 GET | `flutter test test/m3_api_* test/m4_api_*` |')
    ..writeln('| L4 真机日志 | bootstrap、token、WS | `tool/quick_device_verify.ps1` |')
    ..writeln()
    ..writeln('**一键主机**：`powershell -File tool/run_host_verify.ps1`')
    ..writeln()
    ..writeln('## 按模块')
    ..writeln()
    ..writeln('| 模块 | 功能 | 优先级 | 自动化 | 真人 |')
    ..writeln('|------|------|--------|--------|------|');

  for (final module in byModule.keys.toList()..sort()) {
    for (final f in byModule[module]!) {
      final auto = f.hasAutomation
          ? f.automation.map((k) => k.name).join('+')
          : '—';
      final human = f.manualOnly ? '✅须测' : '—';
      final pri = f.priority.name.toUpperCase();
      buf.writeln('| $module | ${f.title} | $pri | $auto | $human |');
    }
  }

  buf
    ..writeln()
    ..writeln('## 真人清单入口')
    ..writeln()
    ..writeln('- [human-only-acceptance.md](./human-only-acceptance.md) — 仅列须真人项')
    ..writeln('- [m3-device-checklist.md](./m3-device-checklist.md) — 真机双跑 10 章（含细项链接）')
    ..writeln('- [parity-checklists-index.md](./parity-checklists-index.md) — 300+ 细项对照');

  return buf.toString();
}
