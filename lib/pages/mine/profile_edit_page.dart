import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_providers.dart';
import '../../core/http/api_result.dart';
import '../../core/utils/avatar_util.dart';
import '../../models/user.dart';
import '../../router/app_router.dart';
import '../../core/utils/media_permission_util.dart';
import '../../core/utils/string_util.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/head_image.dart';
import '../../widgets/im_form.dart';
import '../../widgets/image_preview_dialog.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';
import '../../widgets/im_feedback.dart';

/// 修改我的信息。对齐 mine-edit.vue。
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage>
    with RouteAware {
  static const _maxAvatarBytes = 10 * 1024 * 1024;

  late TextEditingController _nickCtrl;
  late TextEditingController _signCtrl;
  int _sex = 0;
  String? _headImage;
  String? _headImageThumb;
  bool _busy = false;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _nickCtrl = TextEditingController();
    _signCtrl = TextEditingController();
    _reloadFromStore();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeRoute());
  }

  @override
  void dispose() {
    imRouteObserver.unsubscribe(this);
    _nickCtrl.dispose();
    _signCtrl.dispose();
    super.dispose();
  }

  void _subscribeRoute() {
    final route = ModalRoute.of(context);
    if (route != null) {
      imRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _reloadFromStore();
  }

  void _reloadFromStore() {
    final u = ref.read(userStoreProvider);
    _nickCtrl.text = u?.nickName ?? '';
    _signCtrl.text = u?.signature ?? '';
    _sex = u?.sex ?? 0;
    _headImage = u?.headImage;
    _headImageThumb = u?.headImageThumb;
    if (mounted) setState(() {});
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingAvatar || _busy) return;
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
        _headImageThumb = result.displayUrl;
      });
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _submit() async {
    final base = ref.read(userStoreProvider);
    if (base == null || _busy) return;
    setState(() => _busy = true);
    try {
      final updated = User(
        id: base.id,
        userName: base.userName,
        phone: base.phone,
        email: base.email,
        nickName: _nickCtrl.text.trim(),
        sex: _sex,
        type: base.type,
        signature: _signCtrl.text.trim(),
        headImage: _headImage,
        headImageThumb: _headImageThumb,
        companyName: base.companyName,
        isManualApprove: base.isManualApprove,
        isAudioTip: base.isAudioTip,
        userIdentity: base.userIdentity,
      );
      await ref.read(userStoreProvider.notifier).updateProfile(updated);
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

  Widget _buildAvatarRing(BuildContext context, String? nickName) {
    final avatarSize = rpx(context, 120);
    return GestureDetector(
      onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
      onLongPress: _uploadingAvatar
          ? null
          : () => showNetworkImagePreview(context, _headImage),
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
            HeadImage(
              url: AvatarUtil.pick(
                thumb: _headImageThumb,
                origin: _headImage,
              ),
              name: nickName,
              size: 120,
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStoreProvider);

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '修改我的信息', showBack: true),
      body: user == null
          ? const Center(child: Text('未登录'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: rpx(context, 24)),
                ImFormCard(
                  children: [
                    ImFormRow(
                      label: '头像',
                      showDivider: true,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _buildAvatarRing(context, user.nickName),
                      ),
                    ),
                    ImFormReadRow(label: '用户编号', value: '${user.id}'),
                    ImFormReadRow(label: '用户名', value: user.userName ?? ''),
                    if (user.companyName != null &&
                        user.companyName!.isNotEmpty)
                      ImFormReadRow(
                        label: '所属企业',
                        value: user.companyName!,
                      ),
                    if (user.phone != null && user.phone!.isNotEmpty)
                      ImFormReadRow(
                        label: '手机',
                        value: StringUtil.maskPhone(user.phone),
                      )
                    else
                      ImFormBindRow(
                        label: '手机',
                        actionText: '去绑定',
                        onTap: () => context.push(AppRoutes.mineBindPhone),
                      ),
                    ImFormInputRow(
                      label: '昵称',
                      controller: _nickCtrl,
                      placeholder: '请输入您的昵称',
                      maxLength: 20,
                    ),
                    ImFormRadioRow(
                      label: '性别',
                      groupValue: _sex,
                      onChanged: (v) => setState(() => _sex = v),
                    ),
                    ImFormTextAreaRow(
                      label: '个性签名',
                      controller: _signCtrl,
                      placeholder: '编辑个性签名,展示我的独特态度',
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
