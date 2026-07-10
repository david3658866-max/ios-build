import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/enums/message_type.dart';
import '../../core/http/api_result.dart';
import '../../stores/friend_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';

/// 申请添加朋友。对齐 friend-apply.vue。
class FriendApplyPage extends ConsumerStatefulWidget {
  const FriendApplyPage({super.key, required this.userId});

  final int userId;

  @override
  ConsumerState<FriendApplyPage> createState() => _FriendApplyPageState();
}

class _FriendApplyPageState extends ConsumerState<FriendApplyPage> {
  final _remarkCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ImFeedback.toast(context, '无效的用户，请返回重试');
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.pop();
        });
      });
      return;
    }
    final nickName = ref.read(userStoreProvider)?.nickName;
    _remarkCtrl.text = nickName != null ? '我是$nickName' : '';
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || widget.userId <= 0) return;
    setState(() => _busy = true);
    try {
      final store = ref.read(friendStoreProvider.notifier);
      if (store.isFriend(widget.userId)) {
        ImFeedback.toast(context, '对方已是您的好友');
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.pop();
        return;
      }
      if (store.isPendingRequest(widget.userId)) {
        ImFeedback.toast(context, '您已发送过好友申请，请等待对方验证');
        return;
      }
      final req = await store.applyRequest(
        friendId: widget.userId,
        remark: _remarkCtrl.text.trim(),
      );
      if (!mounted) return;
      if (req.status == RequestStatus.approved) {
        ImFeedback.toast(context, '添加成功，对方已成为您的好友');
      } else {
        ImFeedback.toast(context, '对方开启了好友验证,请等待对方通过您的好友申请');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.pop();
    } catch (e) {
      final api = asApiException(e);
      if (api.message.contains('已是您的好友')) {
        await ref.read(friendStoreProvider.notifier).loadFriends();
        ImFeedback.toast(context, '对方已是您的好友');
      } else {
        ImFeedback.toast(
          context,
          api.message.isEmpty ? '发送失败，请稍后再试' : api.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(
        title: '申请添加朋友',
        showBack: true,
      ),
      body: ListView(
        children: [
          Container(
            margin: EdgeInsets.only(top: rpx(context, 3)),
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              rpx(context, 40),
              rpx(context, 20),
              rpx(context, 40),
              rpx(context, 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: rpx(context, 100),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '申请留言: ',
                      style: TextStyle(
                        fontSize: rpx(context, 32),
                        color: ImColors.textLighter,
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _remarkCtrl,
                  maxLines: 4,
                  minLines: 3,
                  style: TextStyle(fontSize: rpx(context, 30)),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(rpx(context, 8)),
                      borderSide: const BorderSide(color: ImColors.formDivider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(rpx(context, 8)),
                      borderSide: const BorderSide(color: ImColors.formDivider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(rpx(context, 8)),
                      borderSide: const BorderSide(color: ImColors.accent),
                    ),
                    contentPadding: EdgeInsets.all(rpx(context, 16)),
                  ),
                ),
              ],
            ),
          ),
          ImBarGroup(
            children: [
              ImBarPrimaryButton(
                text: '发送',
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
