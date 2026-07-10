import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router/app_router.dart';
import 'scan_util.dart';

class PendingScanRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setRoute(String? route) => state = route;

  String? takeRoute() {
    final route = state;
    state = null;
    return route;
  }
}

/// 冷启动扫码深链待跳转路由（对齐 uniapp App.vue H5 onLaunch ?scan=1）。
final pendingScanRouteProvider =
    NotifierProvider<PendingScanRouteNotifier, String?>(
  PendingScanRouteNotifier.new,
);

/// 从 URI 解析扫码深链目标页；非用户/群码返回 null。
String? routeFromScanUri(Uri uri) {
  final action = ScanUtil.parse(uri.toString());
  switch (action.type) {
    case ScanActionType.userProfile:
      final userId = action.userId;
      if (userId == null || userId <= 0) return null;
      return AppRoutes.friendUserPath(userId);
    case ScanActionType.groupInfo:
      final groupId = action.groupId;
      if (groupId == null || groupId <= 0) return null;
      return AppRoutes.groupInfoPath(groupId);
    default:
      return null;
  }
}

/// 捕获启动 URI 中的扫码参数（Web 冷启动 / 未来 App Links）。
void captureStartupScanDeepLink(WidgetRef ref, [Uri? uri]) {
  final target = uri ?? (kIsWeb ? Uri.base : null);
  if (target == null) return;
  if (target.queryParameters['scan'] != '1') return;
  final route = routeFromScanUri(target);
  if (route != null) {
    ref.read(pendingScanRouteProvider.notifier).setRoute(route);
  }
}

/// 登录成功后消费待跳转扫码路由。
void consumePendingScanRoute(WidgetRef ref) {
  final pending = ref.read(pendingScanRouteProvider.notifier).takeRoute();
  if (pending == null) return;
  ref.read(goRouterProvider).push(pending);
}
