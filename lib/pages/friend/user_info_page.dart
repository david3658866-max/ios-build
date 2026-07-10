import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_providers.dart';
import '../../core/di/app_providers.dart';
import '../../core/http/api_result.dart';
import '../../core/utils/teenager_mode_util.dart';
import '../../core/enums/chat_type.dart';
import '../../models/friend_request.dart';
import '../../models/user.dart';
import '../../router/app_router.dart';
import '../../stores/chat_store.dart';
import '../../stores/friend_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/friend/friend_request_info.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/chat/chat_picker_sheet.dart';
import '../../widgets/user/user_info_card.dart';

/// 用户信息 / 好友详情。对齐 common/user-info.vue。
class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({
    super.key,
    required this.userId,
    this.requestId,
  });

  final int userId;
  final int? requestId;

  @override
  ConsumerState<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  User? _user;
  bool _loading = true;
  bool _userLoaded = false;
  bool _hasChat = false;

  @override
  void initState() {
    super.initState();
    _syncPrefillFromStore();
    unawaited(_prefillFromChat());
    unawaited(_load());
  }

  /// 对齐 uniapp onLoad `prefillUserInfo`：同步从好友 store 预填，避免首屏转圈。
  void _syncPrefillFromStore() {
    final store = ref.read(friendStoreProvider.notifier);
    final friend = store.byId(widget.userId);
    if (friend != null && !friend.deleted) {
      _user = User(
        id: friend.id,
        nickName: friend.showNickName ?? friend.nickName,
        headImageThumb: friend.headImage,
        headImage: friend.headImage,
        companyName: friend.companyName,
      );
      _loading = false;
    }
  }

  Future<void> _prefillFromChat() async {
    final chat = await ref.read(chatStoreProvider).findChat(
          ChatType.private,
          widget.userId,
        );
    if (!mounted) return;
    if (chat == null) return;
    setState(() {
      _hasChat = true;
      if (_user == null) {
        _user = User(
          id: widget.userId,
          nickName: chat.showName,
          headImageThumb: chat.headImage,
          headImage: chat.headImage,
          companyName: chat.companyName,
        );
        _loading = false;
      }
    });
  }

  Future<void> _refreshHasChat() async {
    final chat = await ref.read(chatStoreProvider).findChat(
          ChatType.private,
          widget.userId,
        );
    if (mounted) setState(() => _hasChat = chat != null);
  }

  Future<void> _load() async {
    try {
      final user = await ref.read(userApiProvider).find(widget.userId);
      if (widget.requestId != null) {
        final store = ref.read(friendStoreProvider.notifier);
        if (store.findRequest(widget.requestId!) == null) {
          try {
            await store.loadRequests();
          } catch (_) {}
        }
      }
      if (!mounted) return;

      final friendStore = ref.read(friendStoreProvider.notifier);
      if (friendStore.isFriend(widget.userId)) {
        unawaited(friendStore.updateFriendFromUser(user));
      } else {
        unawaited(ref.read(chatStoreProvider).syncChatFromUser(user));
      }

      setState(() {
        _user = user;
        _userLoaded = true;
        _loading = false;
      });
      unawaited(_refreshHasChat());
    } catch (e) {
      if (mounted) {
        setState(() {
          _userLoaded = true;
          _loading = false;
        });
        if (_user == null) {
          ImFeedback.toast(context, asApiException(e).message);
        }
      }
    }
  }

  void _onAddFriend() {
    final user = _user;
    if (user == null) {
      ImFeedback.toast(context, '用户信息加载中，请稍候');
      return;
    }
    final myIdentity = ref.read(userStoreProvider)?.userIdentity;
    if (myIdentity != 1 && user.userIdentity != 1) {
      ImFeedback.toast(context, '普通用户只能添加高级用户为好友');
      return;
    }
    context.push(AppRoutes.friendApplyPath(widget.userId));
  }

  Future<void> _onSendCard() async {
    final enabled = TeenagerModeUtil.isEnabled(
      userId: ref.read(userStoreProvider)?.id,
      kv: ref.read(kvStoreProvider),
    );
    if (guardTeenagerFeature(
      teenagerModeEnabled: enabled,
      feature: TeenagerBlockFeature.shareCard,
      onBlocked: (msg) => ImFeedback.toast(context, msg),
    )) {
      return;
    }
    final friend =
        ref.read(friendStoreProvider.notifier).byId(widget.userId);
    if (friend == null || friend.deleted) return;

    final chats = await ChatPickerSheet.show(context);
    if (chats == null || chats.isEmpty || !mounted) return;

    final err = await ref.read(chatStoreProvider).sendUserCard(
          userId: friend.id,
          nickName: friend.nickName ?? friend.showNickName ?? '',
          headImage: friend.headImage,
          chats: chats,
        );
    if (!mounted) return;
    if (err != null) {
      ImFeedback.toast(context, err);
    } else {
      ImFeedback.toast(context, '发送成功');
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendState = ref.watch(friendStoreProvider);
    final store = ref.read(friendStoreProvider.notifier);
    final storeFriend = store.byId(widget.userId);
    final friend = storeFriend != null && !storeFriend.deleted ? storeFriend : null;
    final isFriend = friend != null;
    final pending = store.isPendingRequest(widget.userId);
    final requestId = widget.requestId;
    final activeRequest = requestId == null
        ? null
        : friendState.requests.where((r) => r.id == requestId).firstOrNull;
    final showActions =
        widget.userId > 0 && (isFriend || _userLoaded);
    final user = _user;

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(
        title: '用户信息',
        showBack: true,
      ),
      body: _loading && user == null
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text('用户不存在'))
              : ListView(
                  children: [
                    UserInfoCard(user: user),
                    if (activeRequest != null)
                      FriendRequestInfo(request: activeRequest)
                    else ...[
                      if (isFriend)
                        ImBarGroup(
                          children: [
                            ImSwitchBar(
                              title: '置顶聊天',
                              value: friend.isTop,
                              onChanged: (v) => ref
                                  .read(friendStoreProvider.notifier)
                                  .setTop(widget.userId, v),
                            ),
                          ],
                        ),
                      if (_hasChat)
                        ImBarGroup(
                          children: [
                            ImArrowBar(
                              title: '查找聊天记录',
                              onTap: () => context.push(
                                AppRoutes.chatHistoryPath(
                                  ChatType.private,
                                  widget.userId,
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (isFriend)
                        ImBarGroup(
                          children: [
                            ImArrowBar(
                              title: '设置备注',
                              trailing: Text(
                                friend.showNickName ?? '',
                                style: TextStyle(
                                  fontSize: rpx(context, 26),
                                  color: ImColors.textLight,
                                ),
                              ),
                              onTap: () async {
                                await context.push(
                                  AppRoutes.friendRemarkPath(widget.userId),
                                );
                                if (!mounted) return;
                                setState(_syncPrefillFromStore);
                              },
                            ),
                            ImArrowBar(
                              title: '推荐该联系人',
                              onTap: _onSendCard,
                            ),
                          ],
                        ),
                      if (showActions)
                        ImBarGroup(
                          children: [
                            if (isFriend)
                              ImBtnBar(
                                title: '发送消息',
                                onTap: () => context.push(
                                  AppRoutes.chatPath(
                                    ChatType.private,
                                    widget.userId,
                                  ),
                                ),
                              ),
                            if (!isFriend && !pending)
                              ImBtnBar(
                                title: '加为好友',
                                onTap: _onAddFriend,
                              ),
                            if (!isFriend && pending)
                              const ImBtnBar(title: '等待对方验证'),
                          ],
                        ),
                    ],
                  ],
                ),
    );
  }
}
