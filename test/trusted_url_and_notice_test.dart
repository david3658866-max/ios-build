import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/notice_html_util.dart';
import 'package:vortek/core/utils/trusted_url_util.dart';

void main() {
  group('TrustedUrlUtil', () {
    test('trusts product and line hosts', () {
      expect(
        TrustedUrlUtil.isTrustedHttpUrl('https://www.xingyu.com/protocol/services.html'),
        isTrue,
      );
      expect(
        TrustedUrlUtil.isTrustedHttpUrl('https://kavun.bgznp.com/?scan=1&userId=1'),
        isTrue,
      );
      expect(
        TrustedUrlUtil.isTrustedHttpUrl('https://novali.de010.com/?scan=1&groupId=2'),
        isTrue,
      );
      expect(TrustedUrlUtil.isTrustedHttpUrl('http://127.0.0.1:8080/x'), isTrue);
    });

    test('rejects untrusted hosts', () {
      expect(
        TrustedUrlUtil.isTrustedHttpUrl('https://evil.example.com/phish'),
        isFalse,
      );
      expect(TrustedUrlUtil.isTrustedHttpUrl('javascript:alert(1)'), isFalse);
      expect(TrustedUrlUtil.isTrustedHttpUrl(''), isFalse);
    });
  });

  group('NoticeHtmlUtil', () {
    test('strips script and tags', () {
      const html =
          '<p>Hello</p><script>alert(1)</script><style>.x{}</style><br/>World';
      expect(NoticeHtmlUtil.toPlainText(html), 'Hello\n\nWorld');
    });

    test('decodes common entities', () {
      expect(
        NoticeHtmlUtil.toPlainText('A&nbsp;&amp;&lt;B&gt;'),
        'A &<B>',
      );
    });
  });
}
