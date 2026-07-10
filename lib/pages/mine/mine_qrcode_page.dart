import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/di/app_providers.dart';
import '../../core/utils/avatar_util.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/chat/head_image.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_primary_button.dart';
import '../../widgets/im_feedback.dart';
import '../../core/http/api_result.dart';

/// 我的二维码。对齐 mine-qrcode.vue。
class MineQrcodePage extends ConsumerStatefulWidget {
  const MineQrcodePage({super.key});

  @override
  ConsumerState<MineQrcodePage> createState() => _MineQrcodePageState();
}

class _MineQrcodePageState extends ConsumerState<MineQrcodePage> {
  final _qrKey = GlobalKey();
  bool _saving = false;

  String? _scanUrl(int userId) {
    final scanBase = ref.read(lineProvider).scanUrl;
    return '$scanBase?scan=1&userId=$userId';
  }

  ImageProvider? _embeddedImageProvider(String? thumb, String? origin) {
    final url = AvatarUtil.pick(thumb: thumb, origin: origin);
    if (url == null || !url.startsWith('http')) return null;
    return NetworkImage(url);
  }

  Future<void> _saveToAlbum() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!
              .buffer
              .asUint8List();
      await Gal.putImageBytes(bytes);
      if (!mounted) return;
      ImFeedback.toast(context, '保存成功');
    } catch (e) {
      if (mounted) {
        ImFeedback.toast(context, '保存失败: ${asApiException(e).message}');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStoreProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: ImColors.pageBg,
        appBar: const ImNavBar(title: '我的二维码', showBack: true),
        body: const Center(child: Text('用户信息未加载')),
      );
    }

    final name = user.nickName ?? user.userName ?? '';
    final qrData = _scanUrl(user.id);
    if (qrData == null) {
      return Scaffold(
        backgroundColor: ImColors.pageBg,
        appBar: const ImNavBar(title: '我的二维码', showBack: true),
        body: const Center(child: Text('扫码地址未配置')),
      );
    }

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '我的二维码', showBack: true),
      body: Column(
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
                            url: user.headImageThumb ?? user.headImage,
                            name: name,
                            size: 100,
                          ),
                          SizedBox(width: rpx(context, 30)),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: rpx(context, 36),
                                      fontWeight: FontWeight.w600,
                                      color: ImColors.text,
                                    ),
                                  ),
                                ),
                                if (user.sex == 0)
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: rpx(context, 5)),
                                    child: Icon(
                                      Icons.male,
                                      size: rpx(context, 32),
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                if (user.sex == 1)
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: rpx(context, 5)),
                                    child: Icon(
                                      Icons.female,
                                      size: rpx(context, 32),
                                      color: Colors.red.shade400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: rpx(context, 20)),
                    RepaintBoundary(
                      key: _qrKey,
                      child: ColoredBox(
                        color: Colors.white,
                        child: QrImageView(
                          data: qrData,
                          size: rpx(context, 500),
                          backgroundColor: Colors.white,
                          embeddedImage: _embeddedImageProvider(
                            user.headImageThumb,
                            user.headImage,
                          ),
                          embeddedImageStyle: QrEmbeddedImageStyle(
                            size: Size(
                              rpx(context, 80),
                              rpx(context, 80),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: rpx(context, 10)),
                      child: Text(
                        '扫一扫加我为好友',
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
