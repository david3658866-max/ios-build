import 'dart:io';

/// 静态扫描：捕捉易导致与 uniapp 版面不一致的写法。
abstract final class ParityLayoutScanner {
  static const allowlistPaths = [
    'messages_tab.dart', // 空态提示宽度 80%
  ];

  static List<ParityLayoutViolation> scanDirectory(Directory root) {
    final violations = <ParityLayoutViolation>[];
    if (!root.existsSync()) return violations;

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final rel = entity.path.replaceAll('\\', '/');
      if (rel.contains('/test/')) continue;
      violations.addAll(scanFile(entity));
    }
    return violations;
  }

  static List<ParityLayoutViolation> scanFile(File file) {
    final rel = file.path.replaceAll('\\', '/');
    final base = rel.split('/').last;
    if (allowlistPaths.contains(base)) return const [];

    final lines = file.readAsLinesSync();
    final out = <ParityLayoutViolation>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('parity-layout-ignore')) continue;

      if (_screenWidthFraction.hasMatch(line)) {
        out.add(
          ParityLayoutViolation(
            file: rel,
            line: i + 1,
            ruleId: 'screen_width_fraction',
            message:
                '网格/工具项勿用整屏宽度比例；应在 LayoutBuilder 内按父级 constraints 分列（参考 chat_tools_panel.dart）',
          ),
        );
      }

      if (_fixedEmotionGrid.hasMatch(line) &&
          rel.contains(RegExp(r'emotion|chat_emotion', caseSensitive: false))) {
        out.add(
          ParityLayoutViolation(
            file: rel,
            line: i + 1,
            ruleId: 'emotion_fixed_columns',
            message: '表情面板勿写死 crossAxisCount；应对齐 uniapp flex 换行 + 64rpx',
          ),
        );
      }

      if (_toolItemScreenWidth.hasMatch(line)) {
        out.add(
          ParityLayoutViolation(
            file: rel,
            line: i + 1,
            ruleId: 'tool_item_screen_width',
            message: '工具栏项 width 应基于内容区 /4，而非 MediaQuery.sizeOf.width * 0.25',
          ),
        );
      }
    }
    return out;
  }

  static final _screenWidthFraction = RegExp(
    r'MediaQuery\.sizeOf\([^)]+\)\.width\s*\*\s*0\.(25|2|33|333)',
  );

  static final _toolItemScreenWidth = RegExp(
    r'width:\s*MediaQuery\.sizeOf\([^)]+\)\.width\s*\*\s*0\.25',
  );

  static final _fixedEmotionGrid = RegExp(
    r'crossAxisCount:\s*4\b',
  );
}

class ParityLayoutViolation {
  const ParityLayoutViolation({
    required this.file,
    required this.line,
    required this.ruleId,
    required this.message,
  });

  final String file;
  final int line;
  final String ruleId;
  final String message;

  @override
  String toString() => '$file:$line [$ruleId] $message';
}
