import 'package:flutter/material.dart';

import '../../core/utils/group_sender_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 群聊消息发送者昵称 + 群主/管理员标签。对齐 chat-message-item `.top`.
class ChatSenderNameRow extends StatelessWidget {
  const ChatSenderNameRow({
    super.key,
    required this.name,
    this.roles = const {},
  });

  final String name;
  final Set<GroupSenderRole> roles;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: rpx(context, 28),
              color: ImColors.textLight,
            ),
          ),
        ),
        if (roles.contains(GroupSenderRole.owner))
          _RoleTag(text: '群主', color: ImColors.danger),
        if (roles.contains(GroupSenderRole.manager))
          _RoleTag(text: '管理员', color: ImColors.accent),
      ],
    );
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: rpx(context, 8)),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: rpx(context, 8),
          vertical: rpx(context, 2),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 0.5),
          borderRadius: BorderRadius.circular(rpx(context, 6)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: rpx(context, 22),
            color: color,
          ),
        ),
      ),
    );
  }
}

/// 群聊对方昵称行（含底边距）。非群聊或己方消息返回 null。
Widget? chatSenderNameLine(
  BuildContext context, {
  required bool selfSend,
  String? name,
  Set<GroupSenderRole> roles = const {},
}) {
  if (selfSend || name == null || name.isEmpty) return null;
  return Padding(
    padding: EdgeInsets.only(bottom: rpx(context, 10)),
    child: ChatSenderNameRow(name: name, roles: roles),
  );
}
