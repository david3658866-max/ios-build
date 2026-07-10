import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/http/api_result.dart';
import '../../models/friend_request.dart';
import '../../router/app_router.dart';
import '../../stores/friend_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../chat/head_image.dart';
import '../im_feedback.dart';
import '../im_mini_button.dart';

/// 好友申请列表项。对齐 friend-request-item.vue。
class FriendRequestItem extends ConsumerStatefulWidget {
  const FriendRequestItem({
    super.key,
    required this.request,
    required this.isRecvTab,
  });

  final FriendRequest request;
  final bool isRecvTab;

  @override
  ConsumerState<FriendRequestItem> createState() => _FriendRequestItemState();
}

class _FriendRequestItemState extends ConsumerState<FriendRequestItem> {
  bool _busy = false;

  int get _friendId => widget.isRecvTab
      ? (widget.request.sendId ?? 0)
      : (widget.request.recvId ?? 0);

  String get _name => widget.isRecvTab
      ? (widget.request.sendNickName ?? '')
      : (widget.request.recvNickName ?? '');

  String? get _avatar => widget.isRecvTab
      ? widget.request.sendHeadImage
      : widget.request.recvHeadImage;

  bool get _isSender => !widget.isRecvTab;

  void _openUserInfo(BuildContext context) {
    context.push(
      '${AppRoutes.friendUserPath(_friendId)}?requestId=${widget.request.id}',
    );
  }

  Future<void> _recall() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(friendStoreProvider.notifier).recallRequest(widget.request.id);
      if (!mounted) return;
      ImFeedback.toast(
        context,
        '您撤回了 ${widget.request.recvNickName ?? ''} 的添加好友请求',
      );
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _openUserInfo(context),
        hoverColor: ImColors.bgActive,
        splashColor: ImColors.bgActive,
        highlightColor: ImColors.bgActive,
        child: Container(
          height: rpx(context, 110),
          margin: EdgeInsets.only(bottom: rpx(context, 1)),
          padding: EdgeInsets.fromLTRB(
            rpx(context, 20),
            rpx(context, 10),
            rpx(context, 30),
            rpx(context, 10),
          ),
          child: Row(
            children: [
              HeadImage(url: _avatar, name: _name, size: 84),
              SizedBox(width: rpx(context, 20)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: rpx(context, 32)),
                    ),
                    SizedBox(height: rpx(context, 8)),
                    Text(
                      _subtitle(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: rpx(context, 28),
                        color: ImColors.textLighter,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSender)
                ImMiniButton(
                  text: '撤回',
                  warn: true,
                  onPressed: _busy ? null : _recall,
                )
              else
                ImMiniButton(
                  text: '查看',
                  onPressed: () => _openUserInfo(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final request = widget.request;
    if (request.remark != null && request.remark!.isNotEmpty) {
      return request.remark!;
    }
    return _isSender ? '您请求添加对方为好友' : '对方请求添加您为好友';
  }
}
