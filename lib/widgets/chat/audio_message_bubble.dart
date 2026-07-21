import 'dart:convert';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/di/app_providers.dart';
import '../../core/enums/message_status.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/file_download_util.dart';
import '../../core/utils/group_sender_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/im_icons.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_icon.dart';
import 'chat_sender_name_row.dart';
import 'message_send_status.dart';

/// 全局语音播放（同时只播一条）。
class ChatAudioPlayback {
  ChatAudioPlayback._() {
    _player.playerStateStream.listen((_) => _listener?.call());
  }

  static final ChatAudioPlayback instance = ChatAudioPlayback._();

  final AudioPlayer _player = AudioPlayer();
  VoidCallback? _listener;
  String? _playingKey;

  String? get playingKey => _playingKey;
  bool get isPlaying => _player.playing;

  void attachListener(VoidCallback onChanged) {
    _listener = onChanged;
  }

  void detachListener(VoidCallback onChanged) {
    if (_listener == onChanged) _listener = null;
  }

  Future<void> toggle(String key, String url) async {
    if (_playingKey == key && _player.playing) {
      await _player.pause();
      _listener?.call();
      return;
    }
    if (_playingKey == key && !_player.playing) {
      await _player.play();
      _listener?.call();
      return;
    }
    await _player.stop();
    _playingKey = key;
    if (url.startsWith('http')) {
      await _player.setUrl(url);
    } else {
      await _player.setAudioSource(AudioSource.file(url));
    }
    await _player.play();
    _listener?.call();
  }
}

/// 语音消息气泡。对齐 chat-message-item.vue `.message-audio`。
class AudioMessageBubble extends ConsumerStatefulWidget {
  const AudioMessageBubble({
    super.key,
    required this.message,
    required this.selfSend,
    this.senderName,
    this.senderRoles = const {},
    this.onResend,
    this.onLongPress,
  });

  final Message message;
  final bool selfSend;
  final String? senderName;
  final Set<GroupSenderRole> senderRoles;
  final VoidCallback? onResend;
  final VoidCallback? onLongPress;

  @override
  ConsumerState<AudioMessageBubble> createState() => _AudioMessageBubbleState();
}

class _AudioMessageBubbleState extends ConsumerState<AudioMessageBubble> {
  final _playback = ChatAudioPlayback.instance;

  String get _playKey => '${widget.message.id ?? widget.message.tmpId}';

  @override
  void initState() {
    super.initState();
    _playback.attachListener(_onPlaybackChanged);
  }

  @override
  void dispose() {
    _playback.detachListener(_onPlaybackChanged);
    super.dispose();
  }

  void _onPlaybackChanged() {
    if (mounted) setState(() {});
  }

  Map<String, dynamic> _parse(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return {};
  }

  /// 对齐 chat-message-item.vue `audioPlayState`：STOP / PLAYING / PAUSE。
  String _audioPlayState() {
    if (_playback.playingKey != _playKey) return 'STOP';
    return _playback.isPlaying ? 'PLAYING' : 'PAUSE';
  }

  Widget _voicePlayIcon(BuildContext context, Color color) {
    final icon = ImIcon(
      ImIcons.voicePlay,
      size: rpx(context, 34),
      color: color,
    );
    if (!widget.selfSend) return icon;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: icon,
    );
  }

  List<Widget> _audioContentChildren(BuildContext context) {
    final content = _parse(widget.message.content);
    final duration = (content['duration'] as num?)?.toInt() ?? 0;
    final sending = widget.message.status == MessageStatus.sending;
    final mineBubble = widget.selfSend && !sending;
    final textColor = mineBubble ? Colors.white : ImColors.text;
    final playState = _audioPlayState();
    final gap = SizedBox(width: rpx(context, 12));

    final widgets = <Widget>[
      _voicePlayIcon(context, textColor),
      gap,
      Text(
        '$duration"',
        style: TextStyle(
          fontSize: rpx(context, 32),
          color: textColor,
        ),
      ),
    ];

    if (playState == 'PLAYING') {
      widgets.add(gap);
      widgets.add(
        ImIcon(ImIcons.pause, size: rpx(context, 34), color: textColor),
      );
    } else if (playState == 'PAUSE') {
      widgets.add(gap);
      widgets.add(
        ImIcon(ImIcons.play, size: rpx(context, 34), color: textColor),
      );
    }

    if (widget.selfSend) {
      return widgets.reversed.toList();
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final content = _parse(widget.message.content);
    final url = FileDownloadUtil.toAuthedMediaUrl(
      apiBaseUrl: ref.read(lineProvider).baseUrl,
      accessToken: ref.read(kvStoreProvider).accessToken,
      fileId: content['fileId']?.toString(),
      fileUrl: content['url']?.toString(),
      role: 'origin',
      preferDirect: content['useDirectMedia'] == true,
    );
    final sending = widget.message.status == MessageStatus.sending;
    final mineBubble = widget.selfSend && !sending;

    return Column(
      crossAxisAlignment:
          widget.selfSend ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        ?chatSenderNameLine(
          context,
          selfSend: widget.selfSend,
          name: widget.senderName,
          roles: widget.senderRoles,
        ),
        Row(
            mainAxisAlignment: widget.selfSend
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.selfSend)
                MessageSendSideIcon(
                  message: widget.message,
                  onResend: widget.onResend,
                ),
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    if (url.isNotEmpty) _playback.toggle(_playKey, url);
                  },
                  onLongPress: widget.onLongPress,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: rpx(context, 20),
                      vertical: rpx(context, 16),
                    ),
                    decoration: BoxDecoration(
                      color: mineBubble ? ImColors.bubbleMine : Colors.white,
                      borderRadius: BorderRadius.circular(rpx(context, 20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _audioContentChildren(context),
                    ),
                  ),
                ),
              ),
              if (!widget.selfSend) SizedBox(width: rpx(context, 8)),
            ],
          ),
        if (showPrivateReadLabel(widget.message, widget.selfSend))
          MessagePrivateReadLabel(message: widget.message),
        ],
    );
  }
}
