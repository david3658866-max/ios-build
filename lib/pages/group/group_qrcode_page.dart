import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/http/api_result.dart';
import '../../core/di/app_providers.dart';
import '../../core/utils/avatar_util.dart';
import '../../models/group.dart';
import '../../stores/group_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/head_image.dart';
import '../../widgets/im_feedback.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';

/// 群二维码。对齐 group-qrcode.vue。
class GroupQrcodePage extends ConsumerStatefulWidget {
  const GroupQrcodePage({
    super.key,
    required this.groupId,
    this.isAllowInvite = true,
  });

  final int groupId;
  final bool isAllowInvite;

  @override
  ConsumerState<GroupQrcodePage> createState() => _GroupQrcodePageState();
}

class _GroupQrcodePageState extends ConsumerState<GroupQrcodePage> {
  final _qrKey = GlobalKey();
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final hasGroup =
        ref.read(groupStoreProvider.notifier).byId(widget.groupId) != null;
    _loading = !hasGroup;
    if (!hasGroup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    try {
      final exists = ref.read(groupStoreProvider).any((g) => g.id == widget.groupId);
      if (!exists) {
        await ref.read(groupStoreProvider.notifier).loadGroupDetail(widget.groupId);
      }
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Group? _resolveGroup() {
    for (final g in ref.watch(groupStoreProvider)) {
      if (g.id == widget.groupId) return g;
    }
    return null;
  }

  String _scanUrl(Group group) {
    final scanBase = ref.read(lineProvider).scanUrl;
    return '$scanBase?scan=1&groupId=${group.id}';
  }

  ImageProvider? _embeddedImageProvider(Group group) {
    final url = AvatarUtil.pick(
      thumb: group.headImageThumb,
      origin: group.headImage,
    );
    if (url == null || !url.startsWith('http')) return null;
    return NetworkImage(url);
  }

  Future<void> _saveToAlbum() async {
    if (_saving || !widget.isAllowInvite) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      await Gal.putImageBytes(bytes);
      if (!mounted) return;
      ImFeedback.toast(context, '保存成功');
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, asApiException(e).message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _resolveGroup();
    final allow = widget.isAllowInvite;

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '群二维码', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : group == null
          ? const Center(child: Text('群聊不存在'))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      margin: EdgeInsets.all(rpx(context, 50)),
                      padding: EdgeInsets.all(rpx(context, 30)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(rpx(context, 20)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: rpx(context, 460),
                            child: Row(
                              children: [
                                HeadImage(
                                  url: group.headImageThumb ?? group.headImage,
                                  name: group.name,
                                  size: 100,
                                ),
                                SizedBox(width: rpx(context, 30)),
                                Expanded(
                                  child: Text(
                                    group.name ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: rpx(context, 36),
                                      fontWeight: FontWeight.w600,
                                      color: ImColors.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: rpx(context, 20)),
                          SizedBox(
                            width: rpx(context, 560),
                            height: rpx(context, 560),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                RepaintBoundary(
                                  key: _qrKey,
                                  child: ColoredBox(
                                    color: Colors.white,
                                    child: QrImageView(
                                      data: _scanUrl(group),
                                      size: rpx(context, 500),
                                      backgroundColor: Colors.white,
                                      embeddedImage: _embeddedImageProvider(group),
                                      embeddedImageStyle: QrEmbeddedImageStyle(
                                        size: Size(
                                          rpx(context, 80),
                                          rpx(context, 80),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (!allow)
                                  Container(
                                    color: const Color(0xF0FFFFFF),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_outlined,
                                          size: rpx(context, 60),
                                          color: ImColors.textLighter,
                                        ),
                                        SizedBox(height: rpx(context, 10)),
                                        Text(
                                          '该群不允许成员邀请加群',
                                          style: TextStyle(
                                            fontSize: rpx(context, 28),
                                            color: ImColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (allow)
                            Padding(
                              padding: EdgeInsets.only(top: rpx(context, 10)),
                              child: Text(
                                '扫一扫二维码,加入群聊',
                                style: TextStyle(
                                  fontSize: rpx(context, 24),
                                  color: ImColors.textLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (allow)
                  ImPrimaryButton(
                    text: '保存到相册',
                    loading: _saving,
                    onPressed: _saving ? null : _saveToAlbum,
                  ),
              ],
            ),
    );
  }
}
