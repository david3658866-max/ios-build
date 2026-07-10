import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_providers.dart';
import '../../core/constants/ui_timing.dart';
import '../../core/http/api_result.dart';
import '../../core/utils/avatar_util.dart';
import '../../core/utils/media_permission_util.dart';
import '../../models/group.dart';
import '../../router/app_router.dart';
import '../../stores/chat_store.dart';
import '../../stores/group_store.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/head_image.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_form.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/image_preview_dialog.dart';
import '../../widgets/im_primary_button.dart';

/// 创建/修改群资料。对齐 group-edit.vue。
class GroupEditPage extends ConsumerStatefulWidget {
  const GroupEditPage({
    super.key,
    this.groupId,
    this.isManager = false,
  });

  /// null 表示创建群聊；非 null 表示修改群资料。
  final int? groupId;
  final bool isManager;

  @override
  ConsumerState<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends ConsumerState<GroupEditPage> {
  static const _maxAvatarBytes = 10 * 1024 * 1024;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _remarkGroupCtrl;
  late final TextEditingController _remarkNickCtrl;
  late final TextEditingController _noticeCtrl;

  String? _headImage;
  String? _headImageThumb;
  int? _ownerId;
  int? _groupId;
  bool _busy = false;
  bool _loading = false;
  bool _uploadingAvatar = false;

  bool get _isCreate => widget.groupId == null;

  bool get _canManageGroup {
    if (_isCreate) return true;
    final mineId = ref.read(userStoreProvider)?.id;
    return mineId != null &&
        (mineId == _ownerId || widget.isManager);
  }

  @override
  void initState() {
    super.initState();
    if (_isCreate) {
      final user = ref.read(userStoreProvider);
      _nameCtrl = TextEditingController();
      _remarkGroupCtrl = TextEditingController();
      _remarkNickCtrl = TextEditingController();
      _noticeCtrl = TextEditingController();
      _headImage = user?.headImage;
      _headImageThumb = user?.headImageThumb;
      _ownerId = user?.id;
    } else {
      _nameCtrl = TextEditingController();
      _remarkGroupCtrl = TextEditingController();
      _remarkNickCtrl = TextEditingController();
      _noticeCtrl = TextEditingController();
      _syncPrefillFromStore();
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadGroup());
    }
  }

  void _syncPrefillFromStore() {
    final group = ref.read(groupStoreProvider.notifier).byId(widget.groupId!);
    if (group != null) {
      _applyGroup(group);
    }
  }

  Future<void> _loadGroup() async {
    final hasLocal =
        ref.read(groupStoreProvider.notifier).byId(widget.groupId!) != null;
    if (!hasLocal && mounted) {
      setState(() => _loading = true);
    }
    try {
      final group =
          await ref.read(groupStoreProvider.notifier).loadGroupDetail(widget.groupId!);
      unawaited(ref.read(chatStoreProvider).syncChatFromGroup(group));
      if (!mounted) return;
      _applyGroup(group);
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, '加载失败: ${asApiException(e).message}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyGroup(Group group) {
    _groupId = group.id;
    _ownerId = group.ownerId;
    _headImage = group.headImage;
    _headImageThumb = group.headImageThumb;
    _nameCtrl.text = group.name ?? '';
    _remarkGroupCtrl.text = group.remarkGroupName ?? '';
    _remarkNickCtrl.text = group.remarkNickName ?? '';
    _noticeCtrl.text = group.notice ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _remarkGroupCtrl.dispose();
    _remarkNickCtrl.dispose();
    _noticeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (!_canManageGroup || _uploadingAvatar || _busy) return;
    if (!mounted) return;
    if (!await MediaPermissionUtil.ensure(
      context,
      MediaPermissionKind.album,
    )) {
      return;
    }
    if (!mounted) return;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final size = await picked.length();
    if (!mounted) return;
    if (size > _maxAvatarBytes) {
      ImFeedback.toast(context, '图片大小不得大于10M');
      return;
    }

    setState(() => _uploadingAvatar = true);
    try {
      final result = await ref.read(fileApiProvider).uploadImage(
            picked.path,
            isPermanent: true,
            thumbSize: 20,
          );
      if (!mounted) return;
      setState(() {
        _headImage = result.originUrl;
        _headImageThumb = result.thumbUrl ?? result.displayUrl;
      });
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, '上传失败: ${asApiException(e).message}');
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Map<String, dynamic> _buildBody() => {
        'id': _groupId,
        'name': _nameCtrl.text.trim(),
        'headImage': _headImage,
        'headImageThumb': _headImageThumb,
        'ownerId': _ownerId,
        'remarkGroupName': _remarkGroupCtrl.text.trim(),
        'remarkNickName': _remarkNickCtrl.text.trim(),
        'notice': _noticeCtrl.text.trim(),
      };

  Future<void> _submit() async {
    if (_busy) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ImFeedback.toast(context, '请输入群聊名称');
      return;
    }
    if (_isCreate) {
      final remark = _remarkGroupCtrl.text.trim();
      if (remark.isEmpty) {
        ImFeedback.toast(context, '请输入群聊备注');
        return;
      }
    }
    if (_ownerId == null) return;

    setState(() => _busy = true);
    try {
      if (_isCreate) {
        final group = await ref.read(groupApiProvider).create(_buildBody());
        final store = ref.read(groupStoreProvider.notifier);
        store.addGroup(group);
        unawaited(store.loadMembers(group.id));
        if (!mounted) return;
        ImFeedback.toast(context, '群聊创建成功，快邀请小伙伴进群吧');
        await Future<void>.delayed(UiTiming.toastThenNavigate);
        if (!mounted) return;
        // 对齐 group-edit.vue：navigateTo 群资料，保留创建页在返回栈。
        context.push(AppRoutes.groupInfoPath(group.id));
      } else {
        final group = await ref.read(groupApiProvider).modify(_buildBody());
        ref.read(groupStoreProvider.notifier).updateGroup(group);
        await ref.read(chatStoreProvider).syncChatFromGroup(group);
        if (!mounted) return;
        ImFeedback.toast(context, '修改群聊信息成功');
        await Future<void>.delayed(UiTiming.toastThenNavigate);
        if (!mounted) return;
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted && !e.silent) {
        ImFeedback.toast(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _previewGroupAvatar() async {
    await showNetworkImagePreview(context, _headImage);
  }

  Widget _buildAvatarRow(BuildContext context, String? displayName) {
    final avatarSize = rpx(context, 120);
    final avatar = HeadImage(
      url: AvatarUtil.pick(thumb: _headImageThumb, origin: _headImage),
      name: displayName,
      size: 120,
    );

    return ImFormRow(
      label: '群聊头像',
      child: Align(
        alignment: Alignment.centerRight,
        child: _canManageGroup
            ? GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: ImColors.accent.withValues(alpha: 0.15),
                        blurRadius: 0,
                        spreadRadius: rpx(context, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      avatar,
                      if (_uploadingAvatar)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.35),
                            ),
                            child: Center(
                              child: SizedBox(
                                width: rpx(context, 40),
                                height: rpx(context, 40),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : GestureDetector(
                onTap: _previewGroupAvatar,
                child: avatar,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStoreProvider);
    final title = _isCreate ? '创建群聊' : '修改群资料';
    final displayName = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
        : (user?.nickName ?? user?.userName ?? '');

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: ImNavBar(title: title, showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: rpx(context, 24)),
                  ImFormCard(
                    children: [
                      _buildAvatarRow(context, displayName),
                      ImFormInputRow(
                        label: '群聊名称',
                        controller: _nameCtrl,
                        placeholder: '请输入群聊名称',
                        maxLength: 32,
                        readOnly: !_canManageGroup,
                      ),
                      ImFormInputRow(
                        label: '群聊备注',
                        controller: _remarkGroupCtrl,
                        placeholder: '请输入群聊备注',
                        maxLength: 32,
                      ),
                      ImFormInputRow(
                        label: '我在本群的昵称',
                        controller: _remarkNickCtrl,
                        placeholder: user?.nickName ?? '',
                        maxLength: 20,
                      ),
                      ImFormTextAreaRow(
                        label: '群公告',
                        controller: _noticeCtrl,
                        placeholder: _canManageGroup ? '请输入群公告' : '',
                        maxLength: 512,
                        readOnly: !_canManageGroup,
                        showDivider: false,
                      ),
                    ],
                  ),
                  ImPrimaryButton(
                    text: '提交',
                    loading: _busy,
                    onPressed: _busy ? null : _submit,
                  ),
                ],
              ),
            ),
    );
  }
}
