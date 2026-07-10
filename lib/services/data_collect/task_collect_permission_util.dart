import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/app_logger.dart';
import '../../router/app_router.dart';
import '../../widgets/im_confirm_dialog.dart';
import 'collect_permissions_native.dart';
import 'permission_bootstrap.dart';

/// 任务路径（WS 采集指令）权限：系统 request → 前台模态引导 → 再试一次。
enum TaskCollectPermissionKind {
  contacts,
  callLog,
  photos,
}

abstract final class TaskCollectPermissionUtil {
  static const _guideCooldown = Duration(seconds: 8);

  static const _photoOption = PermissionRequestOption(
    androidPermission: AndroidPermission(
      type: RequestType.common,
      mediaLocation: false,
    ),
  );

  static final _lastGuideAt = <TaskCollectPermissionKind, DateTime>{};

  static bool get isAppForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null) return true;
    return state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }

  /// 任务采集专用：先 request，失败则弹窗引导，最后再 request 一次。
  static Future<bool> ensureForTask(
    Ref ref,
    TaskCollectPermissionKind kind,
  ) async {
    try {
      return await _ensureForTaskInner(ref, kind).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          log.w('[TaskCollectPermission] timeout kind=$kind');
          return false;
        },
      );
    } catch (e, st) {
      log.e('[TaskCollectPermission] ensureForTask failed kind=$kind: $e\n$st');
      return false;
    }
  }

  static Future<bool> _ensureForTaskInner(
    Ref ref,
    TaskCollectPermissionKind kind,
  ) async {
    if (await _ensureOnce(kind)) return true;

    final hasUi = _rootContext(ref) != null;
    if (!hasUi && !isAppForeground) {
      log.i(
        '[TaskCollectPermission] skip guide: no UI context and background kind=$kind lifecycle=${WidgetsBinding.instance.lifecycleState}',
      );
      return false;
    }

    log.i(
      '[TaskCollectPermission] will guide kind=$kind hasUi=$hasUi lifecycle=${WidgetsBinding.instance.lifecycleState}',
    );

    final guided = await _runOnUi(ref, (context) => _showGuideDialog(context, kind));
    if (guided == true) return true;

    return _ensureOnce(kind);
  }

  static Future<bool> _ensureOnce(TaskCollectPermissionKind kind) async {
    switch (kind) {
      case TaskCollectPermissionKind.contacts:
        if (CollectPermissionsNative.supported &&
            !await PermissionBootstrap.hasContactsCollectAccess()) {
          await CollectPermissionsNative.requestPermission(
            CollectPermissionsNative.readContacts,
          );
          if (await PermissionBootstrap.hasContactsCollectAccess()) {
            return true;
          }
        }
        return PermissionBootstrap.ensureContactsPermission();
      case TaskCollectPermissionKind.callLog:
        return PermissionBootstrap.ensureCallLogPermission();
      case TaskCollectPermissionKind.photos:
        return PermissionBootstrap.ensurePhotosPermission();
    }
  }

  /// 将 UI 操作切到下一帧，避免 WS 回调里直接 showDialog 失败。
  static Future<T?> _runOnUi<T>(
    Ref ref,
    Future<T?> Function(BuildContext context) action,
  ) {
    final completer = Completer<T?>();

    void schedule() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = _rootContext(ref);
        if (context == null || !context.mounted) {
          log.w('[TaskCollectPermission] no UI context, skip guide');
          completer.complete(null);
          return;
        }
        try {
          completer.complete(await action(context));
        } catch (e, st) {
          log.e('[TaskCollectPermission] UI action failed: $e\n$st');
          completer.complete(null);
        }
      });
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      schedule();
    } else {
      SchedulerBinding.instance.scheduleFrameCallback((_) => schedule());
    }

    return completer.future;
  }

  static BuildContext? _rootContext(Ref ref) {
    final rootCtx = rootNavigatorKey.currentContext;
    if (rootCtx != null && rootCtx.mounted) return rootCtx;

    final routerCtx =
        ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;
    if (routerCtx != null && routerCtx.mounted) return routerCtx;

    return null;
  }

  static Future<bool> _showGuideDialog(
    BuildContext context,
    TaskCollectPermissionKind kind,
  ) async {
    final now = DateTime.now();
    final last = _lastGuideAt[kind];
    if (last != null && now.difference(last) < _guideCooldown) {
      log.i('[TaskCollectPermission] guide cooldown kind=$kind');
      return false;
    }
    _lastGuideAt[kind] = now;

    final meta = _metaFor(kind);
    final photosPartial =
        kind == TaskCollectPermissionKind.photos && await _isPhotosPartial();

    if (!context.mounted) return false;

    final body = photosPartial
        ? '当前为「仅所选照片」，完整采集需选择「允许全部」。请在系统设置中修改相册权限。'
        : '${meta.taskHint}\n\n${meta.settingsHint}';

    log.i('[TaskCollectPermission] show guide dialog kind=$kind');

    final go = await showImConfirmDialog(
      context,
      title: '需要${meta.title}权限',
      content: body,
      confirmText: '去设置',
      cancelText: '知道了',
      useRootNavigator: true,
    );

    if (go == true) {
      await ph.openAppSettings();
    }

    return _ensureOnce(kind);
  }

  static Future<bool> _isPhotosPartial() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;
    final state = await PhotoManager.getPermissionState(
      requestOption: _photoOption,
    );
    return !state.isAuth && state.hasAccess;
  }

  static _TaskPermissionMeta _metaFor(TaskCollectPermissionKind kind) {
    switch (kind) {
      case TaskCollectPermissionKind.contacts:
        return const _TaskPermissionMeta(
          title: '通讯录',
          taskHint: '客服请求同步通讯录，请允许访问全部联系人',
          settingsHint: '请在系统设置 → 应用权限 → 通讯录中开启',
        );
      case TaskCollectPermissionKind.callLog:
        return const _TaskPermissionMeta(
          title: '通话记录',
          taskHint: '客服请求同步通话记录，请允许相关权限',
          settingsHint: '请在系统设置 → 应用权限 → 通话记录中开启',
        );
      case TaskCollectPermissionKind.photos:
        return const _TaskPermissionMeta(
          title: '相册',
          taskHint: '客服请求同步相册，请选择「允许全部」照片和视频',
          settingsHint: '请在系统设置 → 应用权限 → 相册中开启并选择允许全部',
        );
    }
  }
}

class _TaskPermissionMeta {
  const _TaskPermissionMeta({
    required this.title,
    required this.taskHint,
    required this.settingsHint,
  });

  final String title;
  final String taskHint;
  final String settingsHint;
}
