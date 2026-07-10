import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/json_parse.dart';
import '../../api/api_providers.dart';
import '../../core/http/api_result.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_nav_bar.dart';

/// 系统通知详情。对齐 chat-system-content.vue。
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
  String _pageTitle = '系统通知';
  int _contentType = 0;
  String _richText = '';
  String _externLink = '';

  @override
  void initState() {
    super.initState();
    _pageTitle = widget.title ?? '系统通知';
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
        _pageTitle = widget.title ?? '系统通知';
        _contentType = JsonParse.asInt(data['contentType']);
        _richText = html;
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
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(_externLink)),
        ),
      );
    }

    final html = _richText.isEmpty
        ? '<p style="padding:16px;color:#666;">暂无内容</p>'
        : _richText;

    return Padding(
      padding: horizontalPad,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: html,
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
      ),
    );
  }
}
