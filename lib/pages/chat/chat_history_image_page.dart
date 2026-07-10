import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/chat_media_util.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/message_long_press_util.dart';
import '../../pages/chat/chat_box_page.dart';
import '../../router/app_router.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/chat_message_menu.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_no_data_tip.dart';

/// 聊天记录 - 图片与视频。对齐 chat-history-image.vue。
class ChatHistoryImagePage extends ConsumerStatefulWidget {
  const ChatHistoryImagePage({
    super.key,
    required this.chatType,
    required this.targetId,
  });

  final String chatType;
  final int targetId;

  @override
  ConsumerState<ChatHistoryImagePage> createState() =>
      _ChatHistoryImagePageState();
}

class _ChatHistoryImagePageState extends ConsumerState<ChatHistoryImagePage> {
  int _showMaxIdx = 30;

  static const _loadLimit = 500;

  ChatMsgQuery get _query => ChatMsgQuery(
    type: widget.chatType,
    targetId: widget.targetId,
    limit: _loadLimit,
  );

  List<Message> _allMedia(List<Message> all) {
    return all
        .where(
          (m) => m.type == MessageType.image || m.type == MessageType.video,
        )
        .toList();
  }

  List<Message> _mediaMessages(List<Message> all) {
    return _allMedia(all).reversed.take(_showMaxIdx).toList();
  }

  Map<String, List<Message>> _groupByTime(List<Message> messages) {
    final map = <String, List<Message>>{};
    for (final m in messages) {
      final key = DateUtil.historyMediaGroupLabel(m.sendTime);
      map.putIfAbsent(key, () => []).add(m);
    }
    return map;
  }

  String? _thumbUrl(Message msg) {
    try {
      final map = jsonDecode(msg.content ?? '{}');
      if (map is! Map) return null;
      if (msg.type == MessageType.image) {
        return map['thumbUrl']?.toString();
      }
      return map['coverUrl']?.toString();
    } catch (_) {
      return null;
    }
  }

  void _previewImage(Message msg) {
    final url = _thumbUrl(msg);
    if (url == null || url.isEmpty) return;
    if (NetworkImageFailCache.isTemporarilyBlocked(url)) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: InteractiveViewer(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            frameBuilder: (context, child, frame, syncLoaded) {
              if (syncLoaded || frame != null) {
                NetworkImageFailCache.markSucceeded(url);
              }
              return child;
            },
            errorBuilder: (_, _, _) {
              NetworkImageFailCache.markFailed(url);
              return Icon(
                Icons.broken_image_outlined,
                color: Colors.white54,
                size: rpx(context, 72),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onLongPress(Message msg, Offset anchor) async {
    final key = await ChatMessageMenu.show(
      context,
      items: const [
        ChatMessageMenuItem(key: 'LOCATE_MESSAGE', label: '在聊天中定位'),
      ],
      anchor: anchor,
    );
    if (key == 'LOCATE_MESSAGE' && mounted) {
      context.pop();
      Future<void>.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        context.push(
          '${AppRoutes.chatPath(widget.chatType, widget.targetId)}?locateId=${msg.id}',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final msgAsync = ref.watch(chatMessagesProvider(_query));
    final all = msgAsync.value ?? const [];
    final totalMedia = _allMedia(all).length;
    final media = _mediaMessages(all);
    final grouped = _groupByTime(media);
    final tile = rpx(context, 240);

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '图片与视频', showBack: true),
      body: media.isEmpty
          ? const ImNoDataTip(tip: '没有数据')
          : ColoredBox(
              color: Colors.white,
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification &&
                      n.metrics.extentAfter < 120 &&
                      _showMaxIdx < totalMedia) {
                    setState(() => _showMaxIdx += 20);
                  }
                  return false;
                },
                child: ListView(
                  padding: EdgeInsets.only(bottom: rpx(context, 20)),
                  children: [
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          rpx(context, 10),
                          rpx(context, 20),
                          rpx(context, 10),
                          rpx(context, 10),
                        ),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: rpx(context, 28),
                            color: ImColors.textLight,
                          ),
                        ),
                      ),
                      Wrap(
                        children: [
                          for (final m in entry.value)
                            Builder(
                              builder: (context) {
                                final press = MessageLongPressCapture(
                                  (pos) => _onLongPress(m, pos),
                                );
                                return GestureDetector(
                                  onTap: m.type == MessageType.image
                                      ? () => _previewImage(m)
                                      : null,
                                  onLongPressStart: press.onStart,
                                  onLongPress: press.onTriggered,
                                  child: Container(
                                    width: tile,
                                    height: tile,
                                    margin: EdgeInsets.all(rpx(context, 5)),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF333333),
                                      borderRadius: BorderRadius.circular(
                                        rpx(context, 10),
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (_thumbUrl(m) != null)
                                          Builder(
                                            builder: (context) {
                                              final thumb = _thumbUrl(m)!;
                                              if (NetworkImageFailCache.isTemporarilyBlocked(
                                                thumb,
                                              )) {
                                                return Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white54,
                                                  size: rpx(context, 60),
                                                );
                                              }
                                              return Image.network(
                                                thumb,
                                                fit: BoxFit.cover,
                                                frameBuilder:
                                                    (
                                                      context,
                                                      child,
                                                      frame,
                                                      syncLoaded,
                                                    ) {
                                                      if (syncLoaded ||
                                                          frame != null) {
                                                        NetworkImageFailCache.markSucceeded(
                                                          thumb,
                                                        );
                                                      }
                                                      return child;
                                                    },
                                                errorBuilder: (_, _, _) {
                                                  NetworkImageFailCache.markFailed(
                                                    thumb,
                                                  );
                                                  return Icon(
                                                    Icons.broken_image,
                                                    color: Colors.white54,
                                                    size: rpx(context, 60),
                                                  );
                                                },
                                              );
                                            },
                                          )
                                        else
                                          Icon(
                                            Icons.image,
                                            color: Colors.white54,
                                            size: rpx(context, 60),
                                          ),
                                        if (m.type == MessageType.video)
                                          Center(
                                            child: Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.white70,
                                              size: rpx(context, 80),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
