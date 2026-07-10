import 'package:lpinyin/lpinyin.dart';

/// 中文拼音首字母。对齐 im-uniapp friend.vue `pinyin-pro` firstLetter。
abstract final class PinyinUtil {
  /// 取名称首字母（大写）；非 A-Z 返回 `#`。
  static String firstLetter(String? name) {
    final text = name?.trim() ?? '';
    if (text.isEmpty) return '#';

    final py = PinyinHelper.getPinyinE(
      text,
      separator: '',
      format: PinyinFormat.WITHOUT_TONE,
    );
    if (py.isEmpty) return '#';

    final letter = py[0].toUpperCase();
    if (RegExp(r'^[A-Z]$').hasMatch(letter)) return letter;
    return '#';
  }
}
