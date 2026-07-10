import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_providers.dart';
import '../core/config/app_constants.dart';
import '../router/app_router.dart';
import '../widgets/im_confirm_dialog.dart';
import '../widgets/im_toast.dart';

abstract final class UpgradeService {
  static Future<void> checkAndUpgrade(Ref ref) async {
    if (!AppConstants.upgradeEnabled) {
      
      return;
    }
    try {
      final pkg = await PackageInfo.fromPlatform();
      
      final res = await ref.read(systemApiProvider).checkVersion(pkg.version);
      if (res['isLatestVersion'] == true) return;

      final context =
          ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;

      await showUpgradeDialog(
        context,
        changeLog: parseChangeLog(res['changeLog']),
        isForcedUpdate: res['isForcedUpdate'] == true,
      );
    } catch (e) {
      
    }
  }

  static List<String> parseChangeLog(Object? changeLog) {
    if (changeLog is List) {
      return changeLog.map((e) => e.toString()).toList();
    }
    if (changeLog != null && changeLog.toString().isNotEmpty) {
      return [changeLog.toString()];
    }
    return const [];
  }

  static Future<void> showUpgradeDialog(
    BuildContext context, {
    required List<String> changeLog,
    required bool isForcedUpdate,
  }) {
    final content = changeLog.isEmpty ? '发现新版本' : changeLog.join('\n');
    return showDialog<bool>(
      context: context,
      barrierDismissible: !isForcedUpdate,
      builder: (ctx) => PopScope(
        canPop: !isForcedUpdate,
        child: ImConfirmDialog(
          title: '发现新版本',
          content: content,
          showCancel: !isForcedUpdate,
          cancelText: '绋嶅悗鍐嶈',
          confirmText: '绔嬪嵆鏇存柊',
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        unawaited(downloadAndInstall(context));
      }
    });
  }

  static Future<void> downloadAndInstall(BuildContext context) async {
    if (Platform.isIOS) {
      final uri = Uri.parse(AppConstants.apkDownloadUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) _toast(context, '鏃犳硶鎵撳紑涓嬭浇椤甸潰');
      }
      return;
    }
    if (!Platform.isAndroid) return;

    final progress = ValueNotifier<int>(0);
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, prg, __) => Text(
              prg >= 100 ? '姝ｅ湪瀹夎...' : '姝ｅ湪涓嬭浇$prg%',
            ),
          ),
        ),
      ),
    );
    await WidgetsBinding.instance.endOfFrame;

    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/myim.apk';
      var lastProgress = -1;
      await Dio().download(
        AppConstants.apkDownloadUrl,
        path,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          final prg = (received / total * 100).toInt().clamp(0, 100);
          if (prg != lastProgress) {
            lastProgress = prg;
            progress.value = prg;
          }
        },
      );
      progress.value = 100;
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done && context.mounted) {
        _toast(context, result.message);
      }
    } catch (e) {
      
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _toast(context, '涓嬭浇澶辫触');
      }
    } finally {
      progress.dispose();
    }
  }

  static void _toast(BuildContext context, String message) {
    ImToast.show(context, message);
  }
}

