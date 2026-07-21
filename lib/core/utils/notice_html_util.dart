/// Strip/sanitize system-notice HTML to plain text for native Text.
abstract final class NoticeHtmlUtil {
  NoticeHtmlUtil._();

  static String toPlainText(String html) {
    if (html.trim().isEmpty) return '';
    var s = html;
    s = s.replaceAll(
      RegExp(r'<script[\s\S]*?</script>', caseSensitive: false),
      '',
    );
    s = s.replaceAll(
      RegExp(r'<style[\s\S]*?</style>', caseSensitive: false),
      '',
    );
    s = s.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</li\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    s = s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
    s = s.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return s.trim();
  }
}
