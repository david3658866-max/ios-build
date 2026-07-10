import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/http/api_result.dart';
import '../../models/friend_request.dart';
import '../../stores/friend_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../im_bar.dart';
import '../im_feedback.dart';

/// 好友申请详情区。对齐 friend-request-info.vue。
class FriendRequestInfo extends ConsumerStatefulWidget {
  const FriendRequestInfo({super.key, required this.request});

  final FriendRequest request;

  @override
  ConsumerState<FriendRequestInfo> createState() => _FriendRequestInfoState();
}

class _FriendRequestInfoState extends ConsumerState<FriendRequestInfo> {
  bool _busy = false;

  bool get _isSender {
    final mineId = ref.read(userStoreProvider)?.id;
    return mineId != null && widget.request.sendId == mineId;
  }

  Future<void> _run(
    Future<void> Function() fn, {
    required String successMsg,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
      if (!mounted) return;
      ImFeedback.toast(context, successMsg);
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatTime(int? ms) {
    if (ms == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final store = ref.read(friendStoreProvider.notifier);

    return Column(
      children: [
        ImBarGroup(
          dividerIndent: 32,
          children: [
            _InfoRow(
              label: _isSender ? '您请求添加对方为好友' : '对方请求添加您为好友',
              value: _formatTime(req.applyTime),
            ),
            if (req.remark != null && req.remark!.isNotEmpty)
              _RemarkRow(
                text: '${_isSender ? '我' : (req.sendNickName ?? '')}: ${req.remark}',
              ),
          ],
        ),
        ImBarGroup(
          children: [
            if (_isSender)
              ImBtnBar(
                title: '撤回',
                danger: true,
                onTap: _busy
                    ? null
                    : () => _run(
                          () => store.recallRequest(req.id),
                          successMsg:
                              '您撤回了 ${req.recvNickName ?? ''} 的添加好友请求',
                        ),
              ),
            if (!_isSender) ...[
              ImBtnBar(
                title: '同意',
                onTap: _busy
                    ? null
                    : () => _run(
                          () => store.approveRequest(req.id),
                          successMsg:
                              '${req.sendNickName ?? ''} 已成为您的好友',
                        ),
              ),
              ImBtnBar(
                title: '拒绝',
                danger: true,
                onTap: _busy
                    ? null
                    : () => _run(
                          () => store.rejectRequest(req.id),
                          successMsg:
                              '您拒绝了 ${req.sendNickName ?? ''} 的好友请求',
                        ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: rpx(context, 40)),
      height: rpx(context, 100),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: rpx(context, 32))),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: rpx(context, 26),
                color: ImColors.textLighter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemarkRow extends StatelessWidget {
  const _RemarkRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        rpx(context, 40),
        0,
        rpx(context, 40),
        rpx(context, 16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: rpx(context, 32),
          color: ImColors.textLighter,
          height: 1.5,
        ),
      ),
    );
  }
}
