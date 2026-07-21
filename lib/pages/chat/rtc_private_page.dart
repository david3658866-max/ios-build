import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/app_providers.dart';
import '../../core/utils/audio_route_util.dart';
import '../../models/friend.dart';
import '../../services/rtc_service.dart';
import '../../stores/config_store.dart';
import '../../stores/user_store.dart';

/// 私聊音视频通话页。对齐 im-uniapp chat-private-video.vue（WebView + 信令桥）。
class RtcPrivatePage extends ConsumerStatefulWidget {
  const RtcPrivatePage({
    super.key,
    required this.mode,
    required this.isHost,
    required this.friend,
  });

  final String mode;
  final bool isHost;
  final Friend friend;

  @override
  ConsumerState<RtcPrivatePage> createState() => _RtcPrivatePageState();
}

class _RtcPrivatePageState extends ConsumerState<RtcPrivatePage> {
  InAppLocalhostServer? _localhostServer;
  InAppWebViewController? _webViewController;
  StreamSubscription<Map<String, dynamic>>? _signalSub;
  bool _serverReady = false;
  WebUri? _initialUrl;

  @override
  void initState() {
    super.initState();
    ref.read(rtcServiceProvider).setPrivateRtcPageOpen(true);
    _signalSub = ref.read(rtcServiceProvider).privateRtcSignals.listen((msg) {
      _sendMessageToWebView('RTC_MESSAGE', msg);
    });
    unawaited(_startLocalServer());
  }

  @override
  void dispose() {
    ref.read(rtcServiceProvider).setPrivateRtcPageOpen(false);
    _signalSub?.cancel();
    unawaited(_localhostServer?.close());
    super.dispose();
  }

  Future<void> _startLocalServer() async {
    final server = InAppLocalhostServer(
      documentRoot: 'assets/hybrid/html/rtc-private',
    );
    await server.start();
    if (!mounted) {
      await server.close();
      return;
    }
    _localhostServer = server;
    _initialUrl = _buildWebViewUrl();
    setState(() => _serverReady = true);
  }

  WebUri _buildWebViewUrl() {
    final line = ref.read(lineProvider);
    final user = ref.read(userStoreProvider);
    final webrtc = ref.read(configStoreProvider).systemConfig?['webrtc'];
    final webrtcMap = webrtc is Map
        ? Map<String, dynamic>.from(webrtc)
        : <String, dynamic>{};

    // 不在 URL 中带 loginInfo / token（改由 INIT_AUTH / document-start 注入）。
    final params = <String, String>{
      'mode': widget.mode,
      'isHost': widget.isHost.toString(),
      'baseUrl': line.baseUrl,
      'userId': '${user?.id ?? 0}',
      'friend': Uri.encodeComponent(jsonEncode(widget.friend.toJson())),
      'config': Uri.encodeComponent(jsonEncode(webrtcMap)),
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return WebUri('http://localhost:8080/index.html?$query');
  }

  /// 仅注入 accessToken（不含 refreshToken），供 H5 API 使用。
  Map<String, dynamic> _rtcAuthPayload() {
    final info = ref.read(kvStoreProvider).getLoginInfo();
    final user = ref.read(userStoreProvider);
    return <String, dynamic>{
      'accessToken': info?.accessToken ?? '',
      'userId': info?.userId ?? user?.id ?? 0,
      'deviceId': info?.deviceId,
    };
  }

  String _authBootstrapScript() {
    final payload = jsonEncode(_rtcAuthPayload());
    return 'window.__IM_RTC_AUTH=$payload;';
  }

  void _onWebViewMessage(Map<String, dynamic>? event) {
    if (event == null) return;
    final key = event['key']?.toString();
    switch (key) {
      case 'WV_READY':
        _initAudioRoute();
        unawaited(_sendMessageToWebView('INIT_AUTH', _rtcAuthPayload()));
      case 'TOKEN_EXPIRED':
        unawaited(_onRtcTokenExpired());
      case 'WV_CLOSE':
        if (mounted) context.pop();
      case 'INSERT_MESSAGE':
        unawaited(
          ref.read(rtcServiceProvider).insertPrivateActMessageFromWebView(
            event['data'],
          ),
        );
      case 'WV_SET_AUDIO_ROUTE':
        final data = event['data'];
        if (data is Map && data['isSpeaker'] is bool) {
          unawaited(AudioRouteUtil.setSpeakerphoneOn(data['isSpeaker'] as bool));
        }
      default:
        break;
    }
  }

  Future<void> _onRtcTokenExpired() async {
    final ok = await ref.read(dioClientProvider).refreshSession();
    if (!mounted) return;
    if (ok) {
      await _sendMessageToWebView('INIT_AUTH', _rtcAuthPayload());
    }
  }

  void _initAudioRoute() {
    unawaited(AudioRouteUtil.setSpeakerphoneOn(false));
  }

  Future<void> _sendMessageToWebView(String key, dynamic message) async {
    final wv = _webViewController;
    if (wv == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (mounted) await _sendMessageToWebView(key, message);
      return;
    }
    final event = jsonEncode({'key': key, 'data': message});
    final encoded = Uri.encodeComponent(event);
    await wv.evaluateJavascript(source: "onEvent('$encoded')");
  }

  Future<void> _installBridge(InAppWebViewController controller) async {
    controller.addJavaScriptHandler(
      handlerName: 'imRtcBridge',
      callback: (args) {
        if (args.isEmpty) return null;
        final raw = args.first;
        if (raw is Map) {
          _onWebViewMessage(Map<String, dynamic>.from(raw));
        }
        return null;
      },
    );
    await controller.evaluateJavascript(source: '''
(function() {
  function forwardToFlutter(payload) {
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('imRtcBridge', payload);
    }
  }
  window.addEventListener('message', function(e) {
    var d = e.data;
    if (d && d.type === 'WEB_INVOKE_APPSERVICE' && d.data && d.data.name === 'postMessage') {
      forwardToFlutter(d.data.arg);
    }
  });
})();
''');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          unawaited(_sendMessageToWebView('NAV_BACK', {}));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          child: _serverReady && _initialUrl != null
              ? InAppWebView(
                  initialUrlRequest: URLRequest(url: _initialUrl!),
                  initialUserScripts: UnmodifiableListView<UserScript>([
                    UserScript(
                      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                      source: _authBootstrapScript(),
                    ),
                  ]),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    javaScriptEnabled: true,
                    // 仅本机 hybrid 页可申请音视频权限。
                    allowFileAccessFromFileURLs: false,
                    allowUniversalAccessFromFileURLs: false,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStop: (controller, _) => _installBridge(controller),
                  onPermissionRequest: (controller, request) async {
                    final origin = request.origin.toString();
                    final trusted = origin.startsWith('http://localhost') ||
                        origin.startsWith('https://localhost') ||
                        origin.startsWith('http://127.0.0.1');
                    return PermissionResponse(
                      resources: request.resources,
                      action: trusted
                          ? PermissionResponseAction.GRANT
                          : PermissionResponseAction.DENY,
                    );
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
