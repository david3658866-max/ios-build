import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/http/api_result.dart';
import '../../stores/friend_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_form.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';

/// 设置好友备注。对齐 friend-remark.vue。
class FriendRemarkPage extends ConsumerStatefulWidget {
  const FriendRemarkPage({super.key, required this.friendId});

  final int friendId;

  @override
  ConsumerState<FriendRemarkPage> createState() => _FriendRemarkPageState();
}

class _FriendRemarkPageState extends ConsumerState<FriendRemarkPage> {
  late final TextEditingController _ctrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final f = ref.read(friendStoreProvider.notifier).byId(widget.friendId);
    _ctrl = TextEditingController(text: f?.remarkNickName ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(friendStoreProvider.notifier).modifyRemark(
            widget.friendId,
            _ctrl.text.trim(),
          );
      if (mounted) {
        ImFeedback.toast(context, '修改成功');
        context.pop();
      }
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
    final friend = ref.read(friendStoreProvider.notifier).byId(widget.friendId);
    final placeholder = friend?.nickName ?? '请输入备注';

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(
        title: '设置备注',
        showBack: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: rpx(context, 24)),
          ImFormCard(
            padding: EdgeInsets.fromLTRB(
              rpx(context, 30),
              rpx(context, 20),
              rpx(context, 30),
              rpx(context, 8),
            ),
            children: [
              ImFormTopField(
                label: '备注',
                controller: _ctrl,
                placeholder: placeholder,
                maxLength: 32,
              ),
            ],
          ),
          const Spacer(),
          ImPrimaryButton(
            text: '提交',
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
