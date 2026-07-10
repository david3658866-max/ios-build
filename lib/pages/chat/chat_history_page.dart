import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/chat_type.dart';
import '../../core/enums/message_type.dart';
import '../../core/storage/app_database.dart';
import '../../pages/chat/chat_box_page.dart';
import '../../router/app_router.dart';
import '../../stores/chat_store.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/chat_history_item.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_no_data_tip.dart';
import '../../widgets/im_search_bar.dart';

/// 聊天记录搜索。对齐 chat-history.vue。
class ChatHistoryPage extends ConsumerStatefulWidget {
  const ChatHistoryPage({
    super.key,
    required this.chatType,
    required this.targetId,
  });

  final String chatType;
  final int targetId;

  @override
  ConsumerState<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends ConsumerState<ChatHistoryPage> {
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

  List<Message> _filterMessages(List<Message> all) {
    final q = _searchText.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return all.where((m) {
      if (m.type == MessageType.text) {
        return (m.content ?? '').toLowerCase().contains(q);
      }
      if (m.type == MessageType.file) {
        try {
          final map = jsonDecode(m.content ?? '{}');
          if (map is Map) {
            return (map['name']?.toString().toLowerCase() ?? '').contains(q);
          }
        } catch (_) {}
      }
      return false;
    }).toList();
  }

  List<Message> _visibleMessages(List<Message> matched) {
    return matched.reversed.take(_showMaxIdx).toList();
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

  void _onMessageTap(Message msg) {
    FocusManager.instance.primaryFocus?.unfocus();
    Future<void>.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      context.pop();
      final base = AppRoutes.chatPath(widget.chatType, widget.targetId);
      final path = msg.id != null ? '$base?locateId=${msg.id}' : base;
      context.push(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgAsync = ref.watch(chatMessagesProvider(_query));
    final messages = msgAsync.value ?? const [];
    final matched = _filterMessages(messages);
    final filtered = _visibleMessages(matched);
    final searching = _searchText.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: ImNavBar(
        title: '聊天记录',
        showBack: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ImSearchBar(
            controller: _searchCtrl,
            placeholder: '搜索聊天记录',
            autofocus: false,
            onChanged: (v) => setState(() {
              _searchText = v;
              _showMaxIdx = 30;
            }),
          ),
          Expanded(
            child: !searching
                ? ColoredBox(
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: rpx(context, 100)),
                          child: Text(
                            '快速搜索聊天内容',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: rpx(context, 24),
                              color: ImColors.textLighter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: rpx(context, 80),
                            vertical: rpx(context, 20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _QuickTab(
                                icon: Icons.description_outlined,
                                label: '文件',
                                onTap: () => context.push(
                                  AppRoutes.chatHistoryFilePath(
                                    widget.chatType,
                                    widget.targetId,
                                  ),
                                ),
                              ),
                              _QuickTab(
                                icon: Icons.image_outlined,
                                label: '图片与视频',
                                onTap: () => context.push(
                                  AppRoutes.chatHistoryImagePath(
                                    widget.chatType,
                                    widget.targetId,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? ImNoDataTip(
                        tip: "未搜索到与'$_searchText'相关的内容",
                      )
                    : ColoredBox(
                        color: Colors.white,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n is ScrollEndNotification &&
                                n.metrics.extentAfter < 120 &&
                                _showMaxIdx < matched.length) {
                              setState(() => _showMaxIdx += 20);
                            }
                            return false;
                          },
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final msg = filtered[i];
                              return ChatHistoryItem(
                                headImage: _headImage(msg),
                                showName: _showName(msg),
                                message: msg,
                                onTap: () => _onMessageTap(msg),
                                onAvatarTap: msg.sendId == null
                                    ? null
                                    : () => context.push(
                                          AppRoutes.friendUserPath(msg.sendId!),
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

class _QuickTab extends StatelessWidget {
  const _QuickTab({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: rpx(context, 30),
            vertical: rpx(context, 30),
          ),
          child: Column(
            children: [
              Icon(icon, size: rpx(context, 50), color: ImColors.textLight),
              SizedBox(height: rpx(context, 5)),
              Text(
                label,
                style: TextStyle(
                  fontSize: rpx(context, 24),
                  color: ImColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
