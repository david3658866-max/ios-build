/// 头像工具。统一头像取值与占位逻辑（配合 HeadImage 组件使用）。
abstract final class AvatarUtil {
  /// 优先用缩略图，其次原图，空则返回 null（由 UI 用首字/默认图兜底）。
  static String? pick({String? thumb, String? origin}) {
    if (thumb != null && thumb.trim().isNotEmpty) return thumb.trim();
    if (origin != null && origin.trim().isNotEmpty) return origin.trim();
    return null;
  }

  /// 无头像时的首字占位（取名称首个字符）。
  static String initial(String? name) {
    if (name == null) return '';
    final t = name.trim();
    return t.isEmpty ? '' : t.substring(0, 1);
  }
}
