import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/chat_type.dart';
import '../../core/enums/message_type.dart';
import '../../core/http/api_result.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/system_message_util.dart';
import '../../pages/chat/chat_box_page.dart';
import '../../router/app_router.dart';
import '../../stores/chat_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_no_data_tip.dart';

/// 系统通知列表。对齐 chat-system.vue。
class ChatSystemPage extends ConsumerStatefulWidget {
  const ChatSystemPage({super.key});

  @override
  ConsumerState<ChatSystemPage> createState() => _ChatSystemPageState();
}

class _ChatSystemPageState extends ConsumerState<ChatSystemPage> {
  final _scrollCtrl = ScrollController();
  List<Message>? _seedMessages;

  static const _query = ChatMsgQuery(
    type: ChatType.system,
    targetId: 0,
    limit: 500,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrapLocalMessages());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(chatStoreProvider).activeSystemChat());
      if (mounted) _scrollToBottom();
    });
  }

  Future<void> _bootstrapLocalMessages() async {
    final messages = await ref.read(chatStoreProvider).readMessages(
          ChatType.system,
          0,
          limit: _query.limit,
        );
    if (!mounted) return;
    setState(() => _seedMessages = messages);
    if (messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _openContent(Message msg, SystemMessageView view) {
    final id = msg.id;
    if (id == null) return;
    context.push(
      AppRoutes.chatSystemContentPath(
        id,
        title: view.title ?? '系统通知',
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages) {
    if (messages.isEmpty) {
      return const ImNoDataTip(tip: '暂无系统通知');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ListView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.all(rpx(context, 20)),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];

        if (msg.type == MessageType.tipTime) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: rpx(context, 10)),
            child: Center(
              child: Text(
                DateUtil.formatBubbleTime(msg.sendTime),
                style: TextStyle(
                  fontSize: rpx(context, 24),
                  height: rpx(context, 60) / rpx(context, 24),
                  color: const Color(0xFF555555),
                ),
              ),
            ),
          );
        }

        if (msg.type != MessageType.systemMessage) {
          return const SizedBox.shrink();
        }

        final view = SystemMessageView.fromMessage(msg)!;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            rpx(context, 20),
            0,
            rpx(context, 20),
            rpx(context, 50),
          ),
          child: _SystemMessageCard(
            view: view,
            onTap: () => _openContent(msg, view),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(chatMessagesProvider(_query));

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(
        title: '系统通知',
        showBack: true,
      ),
      body: async.when(
        loading: () => _buildMessageList(
          async.value ?? _seedMessages ?? const [],
        ),
        error: (e, _) {
          final cached = async.value ?? _seedMessages;
          if (cached != null && cached.isNotEmpty) {
            return _buildMessageList(cached);
          }
          return Center(child: Text(asApiException(e).message));
        },
        data: _buildMessageList,
      ),
    );
  }
}

class _SystemMessageCard extends StatelessWidget {
  const _SystemMessageCard({
    required this.view,
    required this.onTap,
  });

  final SystemMessageView view;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(rpx(context, 12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: rpx(context, 20),
            vertical: rpx(context, 5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (view.title != null && view.title!.isNotEmpty)
                SizedBox(
                  height: rpx(context, 50),
                  child: Center(
                    child: Text(
                      view.title!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rpx(context, 30),
                        fontWeight: FontWeight.w600,
                        height: rpx(context, 50) / rpx(context, 30),
                        color: ImColors.text,
                      ),
                    ),
                  ),
                ),
              if (view.coverUrl != null && view.coverUrl!.isNotEmpty)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: ImColors.formDivider),
                    ),
                  ),
                  child: Image.network(
                    view.coverUrl!,
                    height: rpx(context, 350),
                    width: double.infinity,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) => SizedBox(
                      height: rpx(context, 350),
                      child: ColoredBox(color: ImColors.bgActive),
                    ),
                  ),
                ),
              if (view.intro != null && view.intro!.isNotEmpty)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: ImColors.formDivider),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(rpx(context, 16)),
                    child: Text(
                      view.intro!,
                      style: TextStyle(
                        fontSize: rpx(context, 32),
                        color: ImColors.text,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(rpx(context, 16)),
                child: Text(
                  '查看详情',
                  style: TextStyle(
                    fontSize: rpx(context, 26),
                    height: rpx(context, 40) / rpx(context, 26),
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
