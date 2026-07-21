import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/trusted_url_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';

/// External link page: trusted hosts use in-app WebView; others show risk UI.
class ExternalLinkPage extends StatefulWidget {
  const ExternalLinkPage({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<ExternalLinkPage> createState() => _ExternalLinkPageState();
}

class _ExternalLinkPageState extends State<ExternalLinkPage> {
  late final bool _trusted = TrustedUrlUtil.isTrustedHttpUrl(widget.url);

  Future<void> _openSystemBrowser() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_trusted) {
      return Scaffold(
        backgroundColor: ImColors.pageBg,
        appBar: const ImNavBar(title: '\u5916\u94FE\u98CE\u9669\u63D0\u793A', showBack: true),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: rpx(context, 40)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: rpx(context, 48)),
              Text(
                '\u8BE5\u94FE\u63A5\u4E0D\u5728\u53EF\u4FE1\u57DF\u540D\u5185\uFF0C\u5E94\u7528\u5185\u6253\u5F00\u5B58\u5728\u98CE\u9669\u3002\u5982\u9700\u7EE7\u7EED\u8BBF\u95EE\uFF0C\u8BF7\u4F7F\u7528\u7CFB\u7EDF\u6D4F\u89C8\u5668\u3002',
                style: TextStyle(
                  fontSize: rpx(context, 28),
                  color: ImColors.text,
                  height: 1.5,
                ),
              ),
              SizedBox(height: rpx(context, 24)),
              Text(
                widget.url,
                style: TextStyle(
                  fontSize: rpx(context, 26),
                  color: ImColors.textLight,
                ),
              ),
              SizedBox(height: rpx(context, 48)),
              ImPrimaryButton(
                text: '\u7528\u7CFB\u7EDF\u6D4F\u89C8\u5668\u6253\u5F00',
                onPressed: _openSystemBrowser,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const ImNavBar(title: '\u94FE\u63A5', showBack: true),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(widget.url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          allowFileAccessFromFileURLs: false,
          allowUniversalAccessFromFileURLs: false,
          supportZoom: true,
        ),
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url;
          if (uri == null) return NavigationActionPolicy.CANCEL;
          if (TrustedUrlUtil.isTrustedUri(Uri.parse(uri.toString()))) {
            return NavigationActionPolicy.ALLOW;
          }
          final external = Uri.tryParse(uri.toString());
          if (external != null) {
            await launchUrl(external, mode: LaunchMode.externalApplication);
          }
          return NavigationActionPolicy.CANCEL;
        },
      ),
    );
  }
}