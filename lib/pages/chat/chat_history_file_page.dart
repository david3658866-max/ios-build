import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/chat_type.dart';
import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/message_long_press_util.dart';
import '../../pages/chat/chat_box_page.dart';
import '../../router/app_router.dart';
import '../../stores/chat_store.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../widgets/chat/chat_history_item.dart';
import '../../widgets/chat/chat_message_menu.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_no_data_tip.dart';
import '../../widgets/im_search_bar.dart';

/// 聊天记录 - 文件。对齐 chat-history-file.vue。
class ChatHistoryFilePage extends ConsumerStatefulWidget {
  const ChatHistoryFilePage({
    super.key,
    required this.chatType,
    required this.targetId,
  });

  final String chatType;
  final int targetId;

  @override
  ConsumerState<ChatHistoryFilePage> createState() =>
      _ChatHistoryFilePageState();
}

class _ChatHistoryFilePageState extends ConsumerState<ChatHistoryFilePage> {
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  int _showMaxIdx = 30;

  static const _loadLimit = 500;

  @override
  void initState() {
    super.initState();
    if (widget.chatType == ChatType.group) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(groupStoreProvider.notifier).loadMembers(widget.targetId);
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ChatMsgQuery get _query => ChatMsgQuery(
        type: widget.chatType,
        targetId: widget.targetId,
        limit: _loadLimit,
      );

  List<Message> _allFiles(List<Message> all) {
    final q = _searchText.trim().toLowerCase();
    return all.where((m) {
      if (m.type != MessageType.file) return false;
      if (q.isEmpty) return true;
      try {
        final map = jsonDecode(m.content ?? '{}');
        if (map is Map) {
          return (map['name']?.toString().toLowerCase() ?? '').contains(q);
        }
      } catch (_) {}
      return false;
    }).toList();
  }

  List<Message> _fileMessages(List<Message> all) {
    return _allFiles(all).reversed.take(_showMaxIdx).toList();
  }

  String? _headImage(Message msg) {
    final mine = ref.read(userStoreProvider);
    if (widget.chatType == ChatType.group) {
      final members =
          ref.read(groupStoreProvider.notifier).membersOf(widget.targetId);
      for (final m in members) {
        if (m.userId == msg.sendId) return m.headImage;
      }
      return null;
    }
    if (msg.selfSend) return mine?.headImageThumb ?? mine?.headImage;
    for (final c in ref.watch(chatListStreamProvider).value ?? const []) {
      if (c.type == widget.chatType && c.targetId == widget.targetId) {
        return c.headImage;
      }
    }
    return null;
  }

  String _showName(Message msg) {
    final mine = ref.read(userStoreProvider);
    if (widget.chatType == ChatType.group) {
      final members =
          ref.read(groupStoreProvider.notifier).membersOf(widget.targetId);
      for (final m in members) {
        if (m.userId == msg.sendId) return m.showNickName ?? '';
      }
      return msg.sendNickName ?? '';
    }
    if (msg.selfSend) return mine?.nickName ?? '';
    for (final c in ref.watch(chatListStreamProvider).value ?? const []) {
      if (c.type == widget.chatType && c.targetId == widget.targetId) {
        return c.showName ?? '';
      }
    }
    return '';
  }

  void _locate(Message msg) {
    FocusManager.instance.primaryFocus?.unfocus();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      context.pop();
      context.push(
        '${AppRoutes.chatPath(widget.chatType, widget.targetId)}?locateId=${msg.id}',
      );
    });
  }

  Future<void> _onLongPress(Message msg, Offset anchor) async {
    final key = await ChatMessageMenu.show(
      context,
      items: const [
        ChatMessageMenuItem(key: 'LOCATE_MESSAGE', label: '在聊天中定位'),
      ],
      anchor: anchor,
    );
    if (key == 'LOCATE_MESSAGE' && mounted) _locate(msg);
  }

  @override
  Widget build(BuildContext context) {
    final msgAsync = ref.watch(chatMessagesProvider(_query));
    final all = msgAsync.value ?? const [];
    final totalFiles = _allFiles(all).length;
    final files = _fileMessages(all);

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(
        title: '文件',
        showBack: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImSearchBar(
            controller: _searchCtrl,
            placeholder: '搜索文件名',
            autofocus: false,
            onChanged: (v) => setState(() {
              _searchText = v;
              _showMaxIdx = 30;
            }),
          ),
          Expanded(
            child: files.isEmpty
                ? ImNoDataTip(
                    tip: _searchText.isEmpty
                        ? '没有数据'
                        : "未搜索到与'$_searchText'相关的内容",
                  )
                : ColoredBox(
                    color: Colors.white,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollEndNotification &&
                            n.metrics.extentAfter < 120 &&
                            _showMaxIdx < totalFiles) {
                          setState(() => _showMaxIdx += 20);
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (_, i) {
                          final msg = files[i];
                          final press = MessageLongPressCapture(
                            (pos) => _onLongPress(msg, pos),
                          );
                          return GestureDetector(
                            onLongPressStart: press.onStart,
                            onLongPress: press.onTriggered,
                            child: ChatHistoryItem(
                              headImage: _headImage(msg),
                              showName: _showName(msg),
                              message: msg,
                              onTap: () => _locate(msg),
                              onAvatarTap: msg.sendId == null
                                  ? null
                                  : () => context.push(
                                        AppRoutes.friendUserPath(msg.sendId!),
                                      ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
