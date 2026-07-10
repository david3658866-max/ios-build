import 'package:characters/characters.dart';

/// 表情工具。对齐 im-uniapp `common/emotion.js`。
///
/// 发送格式：`#憨笑;`（editor insertImage 转文本后的协议）
/// 输入框内部：单码点占位符（对齐 uniapp editor 内嵌图片，光标按一个单位移动）
/// 资源：`assets/emoji/{idx}.gif`（原 `/static/emoji/`）
abstract final class EmotionUtil {
  /// 输入框内表情占位起始码点（PUA，每个表情占 1 个字符）。
  static const int inputTokenBase = 0xF000;
  /// 与 im-uniapp `emoTextList` 顺序一致。
  static const List<String> emoTextList = [
    '憨笑', '媚眼', '开心', '坏笑', '可怜', '爱心', '笑哭', '拍手', '惊喜', '打气',
    '大哭', '流泪', '饥饿', '难受', '健身', '示爱', '色色', '眨眼', '暴怒', '惊恐',
    '思考', '头晕', '大吐', '酷笑', '翻滚', '享受', '鼻涕', '快乐', '雀跃', '微笑',
    '贪婪', '红心', '粉心', '星星', '大火', '眼睛', '音符', '叹号', '问号', '绿叶',
    '燃烧', '喇叭', '警告', '信封', '房子', '礼物', '点赞', '举手', '喝彩', '点头',
    '摇头', '偷瞄', '庆祝', '疾跑', '打滚', '惊吓', '起跳',
  ];

  /// uniapp: `/\#[\u4E00-\u9FA5]{1,3}\;/gi`
  /// 兼容早期 Flutter 误用的 `[xxx]` 格式。
  static final RegExp pattern = RegExp(
    r'\#([\u4e00-\u9fa5]{1,3})\;|\[([^\[\]]{1,8})\]',
  );

  static String wrap(String word) => '#$word;';

  /// 输入框插入用单字符 token。对齐 uniapp `insertImage` 占一个编辑单元。
  static String inputTokenForWord(String word) {
    final idx = indexOfWord(word);
    if (idx == null) return wrap(word);
    return String.fromCharCode(inputTokenBase + idx);
  }

  static String? wordFromInputToken(String char) {
    if (char.isEmpty) return null;
    final rune = char.runes.first;
    if (rune < inputTokenBase || rune >= inputTokenBase + emoTextList.length) {
      return null;
    }
    return emoTextList[rune - inputTokenBase];
  }

  static bool containsInputToken(String? text) {
    if (text == null || text.isEmpty) return false;
    for (final char in text.characters) {
      if (wordFromInputToken(char) != null) return true;
    }
    return false;
  }

  /// 输入框文本 → 发送协议（`#词;`）。粘贴的 `#词;` 原样保留。
  static String encodeForWire(String input) {
    final out = StringBuffer();
    for (final char in input.characters) {
      final word = wordFromInputToken(char);
      if (word != null) {
        out.write(wrap(word));
        continue;
      }
      out.write(char);
    }
    return out.toString();
  }

  static bool hasEmotion(String? text) =>
      text != null && (pattern.hasMatch(text) || containsInputToken(text));

  static List<String> extract(String? text) {
    if (text == null) return const [];
    return pattern
        .allMatches(text)
        .map((m) => m.group(1) ?? m.group(2))
        .whereType<String>()
        .toList();
  }

  static int? indexOfWord(String word) {
    final idx = emoTextList.indexOf(word);
    return idx >= 0 ? idx : null;
  }

  static String? assetPathForWord(String word) {
    final idx = indexOfWord(word);
    if (idx == null) return null;
    return assetPathForIndex(idx);
  }

  static String assetPathForIndex(int index) => 'assets/emoji/$index.gif';

  static String? wordFromToken(String token) {
    final m = pattern.firstMatch(token);
    if (m == null) return null;
    return m.group(1) ?? m.group(2);
  }

  /// 将文本中的表情码替换为可读占位（会话列表预览等）。
  static String stripForPreview(String text) {
    return text.replaceAllMapped(pattern, (m) {
      final word = m.group(1) ?? m.group(2);
      return word == null ? m.group(0)! : '[$word]';
    });
  }
}
