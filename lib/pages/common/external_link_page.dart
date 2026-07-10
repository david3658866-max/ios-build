import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../widgets/im_nav_bar.dart';

/// 外链 WebView。对齐 pages/common/external-link.vue。
class ExternalLinkPage extends StatelessWidget {
  const ExternalLinkPage({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ImNavBar(title: '链接', showBack: true),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
      ),
    );
  }
}
