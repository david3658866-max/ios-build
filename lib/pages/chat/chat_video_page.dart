import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../widgets/im_nav_bar.dart';

/// 应用内视频播放。对齐 video-player.vue（HTML5 全屏播放）。
class ChatVideoPage extends StatelessWidget {
  const ChatVideoPage({
    super.key,
    required this.url,
    this.poster,
  });

  final String url;
  final String? poster;

  @override
  Widget build(BuildContext context) {
    final posterAttr = (poster != null && poster!.isNotEmpty)
        ? ' poster="${_escape(poster!)}"'
        : '';
    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<style>
  body { margin: 0; background: #000; }
  video { width: 100vw; height: 100vh; object-fit: contain; }
</style>
</head>
<body>
  <video src="${_escape(url)}"$posterAttr controls autoplay playsinline></video>
</body>
</html>
''';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const ImNavBar(title: '视频', showBack: true),
      body: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: html,
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
      ),
    );
  }

  static String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('"', '&quot;');
}
