import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_providers.dart';
import '../../core/http/api_result.dart';
import '../../core/utils/json_parse.dart';
import '../../core/utils/notice_html_util.dart';
import '../../core/utils/trusted_url_util.dart';
import '../../router/app_router.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_confirm_dialog.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';

/// System notice detail. HTML is rendered as plain text (no WebView scripts).
class ChatSystemContentPage extends ConsumerStatefulWidget {
  const ChatSystemContentPage({
    super.key,
    required this.messageId,
    this.title,
  });

  final int messageId;
  final String? title;

  @override
  ConsumerState<ChatSystemContentPage> createState() =>
      _ChatSystemContentPageState();
}

class _ChatSystemContentPageState extends ConsumerState<ChatSystemContentPage> {
  bool _loading = true;
  String? _error;
  String _pageTitle = '\u7CFB\u7EDF\u901A\u77E5';
  int _contentType = 0;
  String _plainText = '';
  String _externLink = '';

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.title ?? '\u7CFB\u7EDF\u901A\u77E5';
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final data = await ref
          .read(messageApiProvider)
          .systemContent(widget.messageId);
      if (!mounted) return;
      final richRaw = JsonParse.asNullableString(data['richText']) ?? '';
      var html = richRaw;
      if (richRaw.isNotEmpty) {
        try {
          html = utf8.decode(base64Decode(richRaw));
        } catch (_) {
          html = richRaw;
        }
      }
      setState(() {
        _loading = false;
        _pageTitle = widget.title ?? '\u7CFB\u7EDF\u901A\u77E5';
        _contentType = JsonParse.asInt(data['contentType']);
        _plainText = NoticeHtmlUtil.toPlainText(html);
        _externLink = JsonParse.asString(data['externLink']);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = asApiException(e).message;
      });
    }
  }

  Future<void> _openExternLink() async {
    final url = _externLink.trim();
    if (url.isEmpty) return;
    if (TrustedUrlUtil.isTrustedHttpUrl(url)) {
      if (!mounted) return;
      context.push(AppRoutes.externalLinkPath(url));
      return;
    }
    final ok = await showImConfirmDialog(
      context,
      title: '\u5916\u94FE\u98CE\u9669\u63D0\u793A',
      content:
          '\u8BE5\u94FE\u63A5\u4E0D\u5728\u53EF\u4FE1\u57DF\u540D\u5185\uFF0C\u662F\u5426\u4F7F\u7528\u7CFB\u7EDF\u6D4F\u89C8\u5668\u6253\u5F00\uFF1F\n\n',
      confirmText: '\u7528\u6D4F\u89C8\u5668\u6253\u5F00',
      cancelText: '\u53D6\u6D88',
    );
    if (ok == true) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: ImNavBar(title: _pageTitle, showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontSize: rpx(context, 28),
                      color: ImColors.textLight,
                    ),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final horizontalPad = EdgeInsets.symmetric(horizontal: rpx(context, 40));

    if (_contentType == 1 && _externLink.isNotEmpty) {
      return Padding(
        padding: horizontalPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: rpx(context, 48)),
            Text(
              _externLink,
              style: TextStyle(
                fontSize: rpx(context, 28),
                color: ImColors.text,
              ),
            ),
            SizedBox(height: rpx(context, 32)),
            ImPrimaryButton(
              text: TrustedUrlUtil.isTrustedHttpUrl(_externLink)
                  ? '\u6253\u5F00\u94FE\u63A5'
                  : '\u7528\u7CFB\u7EDF\u6D4F\u89C8\u5668\u6253\u5F00',
              onPressed: _openExternLink,
            ),
          ],
        ),
      );
    }

    final text = _plainText.isEmpty ? '\u6682\u65E0\u5185\u5BB9' : _plainText;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        rpx(context, 40),
        rpx(context, 32),
        rpx(context, 40),
        rpx(context, 48),
      ),
      child: SelectableText(
        text,
        style: TextStyle(
          fontSize: rpx(context, 30),
          color: ImColors.text,
          height: 1.6,
        ),
      ),
    );
  }
}