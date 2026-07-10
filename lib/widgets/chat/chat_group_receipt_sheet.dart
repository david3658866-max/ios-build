import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_providers.dart';
import '../../core/storage/app_database.dart' hide GroupMember;
import '../../models/group_member.dart';
import '../../stores/chat_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'head_image.dart';

/// 群回执已读/未读成员列表。对齐 chat-group-readed.vue。
class ChatGroupReceiptSheet {
  ChatGroupReceiptSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required Message message,
    required List<GroupMember> members,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatGroupReceiptSheet(
        message: message,
        members: members,
        onLoaded: (count) {
          if (message.id == null) return;
          ref.read(chatStoreProvider).updateGroupMessageReadedCount(
                groupId: message.groupId ?? message.chatTargetId,
                messageId: message.id!,
                readedCount: count,
              );
        },
      ),
    );
  }
}

class _ChatGroupReceiptSheet extends ConsumerStatefulWidget {
  const _ChatGroupReceiptSheet({
    required this.message,
    required this.members,
    required this.onLoaded,
  });

  final Message message;
  final List<GroupMember> members;
  final ValueChanged<int> onLoaded;

  @override
  ConsumerState<_ChatGroupReceiptSheet> createState() =>
      _ChatGroupReceiptSheetState();
}

class _ChatGroupReceiptSheetState extends ConsumerState<_ChatGroupReceiptSheet> {
  int _tab = 0;
  bool _loading = true;
  List<GroupMember> _readed = const [];
  List<GroupMember> _unread = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final groupId = widget.message.groupId ?? widget.message.chatTargetId;
    final messageId = widget.message.id;
    if (messageId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final userIds = await ref.read(messageApiProvider).findReadedUsers(
            groupId,
            messageId,
          );
      final readed = <GroupMember>[];
      final unread = <GroupMember>[];
      for (final m in widget.members) {
        if (m.quit || m.userId == widget.message.sendId) continue;
        if (userIds.contains(m.userId)) {
          readed.add(m);
        } else {
          unread.add(m);
        }
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _readed = readed;
        _unread = unread;
      });
      widget.onLoaded(readed.length);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(rpx(context, 30)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: rpx(context, 16)),
          Row(
            children: [
              Expanded(
                child: _TabChip(
                  label: '已读(${_readed.length})',
                  selected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
              ),
              Expanded(
                child: _TabChip(
                  label: '未读(${_unread.length})',
                  selected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _tab == 0 ? _readed.length : _unread.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: ImColors.formDivider,
                    ),
                    itemBuilder: (_, i) {
                      final m = _tab == 0 ? _readed[i] : _unread[i];
                      return SizedBox(
                        height: rpx(context, 120),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: rpx(context, 30),
                          ),
                          child: Row(
                            children: [
                              HeadImage(
                                url: m.headImage,
                                name: m.showNickName,
                                size: 90,
                              ),
                              SizedBox(width: rpx(context, 20)),
                              Expanded(
                                child: Text(
                                  m.showNickName ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: rpx(context, 30),
                                    fontWeight: FontWeight.w600,
                                    color: ImColors.text,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: rpx(context, 12),
          vertical: rpx(context, 8),
        ),
        padding: EdgeInsets.symmetric(vertical: rpx(context, 12)),
        decoration: BoxDecoration(
          color: selected ? ImColors.accent : ImColors.pageBg,
          borderRadius: BorderRadius.circular(rpx(context, 12)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: rpx(context, 26),
            color: selected ? Colors.white : ImColors.text,
          ),
        ),
      ),
    );
  }
}
