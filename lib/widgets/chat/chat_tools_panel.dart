import 'package:flutter/material.dart';

import '../../theme/im_colors.dart';
import '../../theme/im_icons.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_icon.dart';

/// 聊天工具栏。对齐 uniapp `.chat-tools-list`（每项 width:25%，一行 4 个）。
class ChatToolsPanel extends StatelessWidget {
  const ChatToolsPanel({
    super.key,
    required this.height,
    required this.isGroup,
    required this.isReceipt,
    required this.onToggleReceipt,
    required this.onPickFile,
    required this.onPickAlbum,
    required this.onPickCamera,
    required this.onPickVideo,
    required this.onPickVoice,
    this.showRtcTools = false,
    this.onPrivateVideo,
    this.onPrivateVoice,
    this.showGroupRtcTools = false,
    this.onGroupVideo,
  });

  final double height;
  final bool isGroup;
  final bool isReceipt;
  final VoidCallback onToggleReceipt;
  final VoidCallback onPickFile;
  final VoidCallback onPickAlbum;
  final VoidCallback onPickCamera;
  final VoidCallback onPickVideo;
  final VoidCallback onPickVoice;
  final bool showRtcTools;
  final VoidCallback? onPrivateVideo;
  final VoidCallback? onPrivateVoice;
  final bool showGroupRtcTools;
  final VoidCallback? onGroupVideo;

  static const _columns = 4;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final tools = <Widget>[
      ChatToolItem(icon: ImIcons.folder, label: '文件', onTap: onPickFile),
      ChatToolItem(icon: ImIcons.picture, label: '相册', onTap: onPickAlbum),
      ChatToolItem(icon: ImIcons.camera, label: '拍摄', onTap: onPickCamera),
      ChatToolItem(icon: ImIcons.film, label: '视频', onTap: onPickVideo),
      ChatToolItem(
        icon: ImIcons.microphone,
        label: '语音消息',
        onTap: onPickVoice,
      ),
      if (isGroup)
        ChatToolItem(
          icon: ImIcons.receipt,
          label: '回执消息',
          active: isReceipt,
          onTap: onToggleReceipt,
        ),
      if (showRtcTools && onPrivateVideo != null)
        ChatToolItem(
          icon: ImIcons.video,
          label: '视频通话',
          onTap: onPrivateVideo!,
        ),
      if (showRtcTools && onPrivateVoice != null)
        ChatToolItem(
          icon: ImIcons.call,
          label: '语音通话',
          onTap: onPrivateVoice!,
        ),
      if (showGroupRtcTools && onGroupVideo != null)
        ChatToolItem(
          icon: ImIcons.call,
          label: '语音通话',
          onTap: onGroupVideo!,
        ),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ImColors.pageBg,
        border: Border(top: BorderSide(color: ImColors.borderLight)),
      ),
      child: SizedBox(
        height: height + bottom,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            rpx(context, 40),
            rpx(context, 20),
            rpx(context, 40),
            rpx(context, 20) + bottom,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / _columns;
              return Wrap(
                runSpacing: rpx(context, 6),
                children: [
                  for (final tool in tools)
                    SizedBox(width: itemWidth, child: tool),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ChatToolItem extends StatelessWidget {
  const ChatToolItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, 16),
        vertical: rpx(context, 6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rpx(context, 12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(rpx(context, 26)),
              decoration: BoxDecoration(
                color: active ? ImColors.bgActive : Colors.white,
                borderRadius: BorderRadius.circular(rpx(context, 12)),
              ),
              child: ImIcon(
                icon,
                size: rpx(context, 54),
                color: active ? ImColors.accent : ImColors.sendBarIcon,
              ),
            ),
            SizedBox(height: rpx(context, 8)),
            SizedBox(
              height: rpx(context, 60),
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rpx(context, 28),
                    color: ImColors.textLight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
