import 'package:flutter/material.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

import '../../theme/im_colors.dart';
import 'chat_media_util.dart';
import 'media_permission_util.dart';

/// 聊天相册选图。对齐 uniapp `uni.chooseImage`（album + 原图 + 网格多选）。
abstract final class ChatImagePickerUtil {
  ChatImagePickerUtil._();

  static const _permissionOption = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.image,
      mediaLocation: false,
    ),
  );

  /// 打开相册网格页多选原图。
  /// 对齐 `sizeType: ['original']`，不使用压缩图。
  static Future<List<ChatPickedImage>> pickAlbumImages(
    BuildContext context, {
    int maxCount = ChatMediaUtil.maxAlbumImageCount,
    void Function(String message)? onToast,
  }) async {
    if (!context.mounted) return const [];

    // photo_manager 拒绝后往往不再弹系统框；先走 permission_handler 可重复申请。
    if (!await MediaPermissionUtil.ensureScenario(
      context,
      MediaPermissionScenario.chatAlbumImage,
    )) {
      onToast?.call('未获得相册权限');
      return const [];
    }
    if (!context.mounted) return const [];

    List<AssetEntity>? picked;
    try {
      picked = await AssetPicker.pickAssets(
        context,
        permissionRequestOption: _permissionOption,
        pickerConfig: AssetPickerConfig(
          maxAssets: maxCount,
          requestType: RequestType.image,
          themeColor: ImColors.accent,
          textDelegate: const AssetPickerTextDelegate(),
          gridCount: 4,
          pageSize: 80,
        ),
      );
    } on StateError {
      // permission_handler 与 photo_manager 状态不一致时补一次引导。
      if (context.mounted) {
        await MediaPermissionUtil.ensureScenario(
          context,
          MediaPermissionScenario.chatAlbumImage,
        );
      }
      onToast?.call('未获得相册权限');
      return const [];
    } catch (e) {
      onToast?.call('打开相册失败');
      return const [];
    }
    if (picked == null || picked.isEmpty) return const [];

    final images = <ChatPickedImage>[];
    for (final asset in picked) {
      // 仅原图，对齐 uniapp sizeType: ['original']。
      final file = await asset.originFile;
      if (file == null) {
        onToast?.call('无法读取原图: ${asset.title}');
        continue;
      }
      images.add(
        ChatPickedImage(
          path: file.path,
          width: asset.width,
          height: asset.height,
        ),
      );
    }
    return images;
  }
}
