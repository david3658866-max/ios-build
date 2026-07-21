import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/enums/chat_type.dart';
import '../pages/chat/chat_box_page.dart';
import '../pages/chat/chat_history_page.dart';
import '../pages/chat/chat_history_image_page.dart';
import '../pages/chat/chat_history_file_page.dart';
import '../pages/chat/chat_system_page.dart';
import '../pages/chat/chat_system_content_page.dart';
import '../pages/chat/chat_video_page.dart';
import '../models/friend.dart';
import '../pages/chat/rtc_private_page.dart';
import '../pages/chat/rtc_group_page.dart';
import '../pages/common/external_link_page.dart';
import '../pages/scan/scan_page.dart';
import '../pages/login/login_page.dart';
import '../pages/login/qr_login_confirm_page.dart';
import '../pages/login/register_page.dart';
import '../pages/login/reset_pwd_page.dart';
import '../pages/friend/friend_add_page.dart';
import '../pages/friend/friend_contact_page.dart';
import '../pages/friend/friend_apply_page.dart';
import '../pages/friend/friend_remark_page.dart';
import '../pages/friend/friend_request_page.dart';
import '../pages/friend/user_info_page.dart';
import '../pages/group/group_edit_page.dart';
import '../pages/group/group_info_page.dart';
import '../pages/group/group_invite_page.dart';
import '../pages/group/group_member_page.dart';
import '../pages/group/group_list_page.dart';
import '../pages/group/group_manager_page.dart';
import '../pages/group/group_qrcode_page.dart';
import '../pages/group/group_setting_page.dart';
import '../pages/mine/about_page.dart';
import '../pages/mine/account_page.dart';
import '../pages/mine/bind_email_page.dart';
import '../pages/mine/bind_phone_page.dart';
import '../pages/mine/mine_qrcode_page.dart';
import '../pages/mine/teenager_page.dart';
import '../pages/mine/password_page.dart';
import '../pages/mine/profile_edit_page.dart';
import '../pages/mine/settings_page.dart';
import '../pages/main/main_shell.dart';
import '../services/auth_controller.dart';

/// 路由路径常量（契约：并行 agent 用这些名字跳转，不散写字符串）。
/// 新增页面挂路由需向主 agent 申请登记，不私改本文件。
abstract final class AppRoutes {
  /// 冷启动入口（与 [login] 相同；无独立 Splash 路由）。
  static const String splash = '/login';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPwd = '/reset-pwd';
  static const String qrConfirm = '/qr-confirm';
  static const String main = '/main';
  static const String settings = '/settings';
  static const String friendAdd = '/friend/add';
  static const String friendContact = '/friend/contact';
  static const String friendApply = '/friend/apply/:userId';
  static const String friendRequests = '/friend/requests';
  static const String friendUser = '/friend/user/:userId';
  static const String friendRemark = '/friend/remark/:friendId';

  static const String groupList = '/group/list';

  static const String mineProfile = '/mine/profile';
  static const String mineAccount = '/mine/account';
  static const String minePassword = '/mine/password';
  static const String mineBindPhone = '/mine/bind-phone';
  static const String mineBindEmail = '/mine/bind-email';
  static const String mineTeenager = '/mine/teenager';
  static const String mineAbout = '/mine/about';
  static const String mineQrcode = '/mine/qrcode';

  static String friendApplyPath(int userId) => '/friend/apply/$userId';
  static String friendUserPath(int userId) => '/friend/user/$userId';
  static String friendRemarkPath(int friendId) => '/friend/remark/$friendId';
  static String friendAddKeywordPath(String keyword) =>
      '$friendAdd?keyword=${Uri.encodeComponent(keyword)}';

  static const String groupCreate = '/group/create';
  static const String groupEdit = '/group/edit/:groupId';
  static const String groupInfo = '/group/info/:groupId';
  static const String groupMember = '/group/member/:groupId';
  static const String groupInvite = '/group/invite/:groupId';
  static const String groupQrcode = '/group/qrcode/:groupId';
  static const String groupSetting = '/group/setting/:groupId';
  static const String groupManager = '/group/manager/:groupId';

  static String groupInfoPath(int groupId) => '/group/info/$groupId';
  static String groupEditPath(int groupId) => '/group/edit/$groupId';
  static String groupMemberPath(int groupId) => '/group/member/$groupId';
  static String groupInvitePath(int groupId) => '/group/invite/$groupId';
  static String groupQrcodePath(int groupId, {required bool isAllowInvite}) =>
      '/group/qrcode/$groupId?isAllowInvite=$isAllowInvite';
  static String groupSettingPath(int groupId) => '/group/setting/$groupId';
  static String groupManagerPath(int groupId) => '/group/manager/$groupId';

  /// 会话页：/chat/:type/:id（type=PRIVATE/GROUP/SYSTEM）。
  static const String chat = '/chat/:type/:id';

  static String chatPath(String type, int id) => '/chat/$type/$id';

  static const String scan = '/scan';
  static const String externalLink = '/external-link';

  static String externalLinkPath(String url) =>
      '/external-link?url=${Uri.encodeComponent(url)}';

  /// 聊天记录搜索：/chat/history/:type/:id。
  static const String chatHistory = '/chat/history/:type/:id';

  static String chatHistoryPath(String type, int id) =>
      '/chat/history/$type/$id';

  static const String chatHistoryImage = '/chat/history/:type/:id/image';
  static const String chatHistoryFile = '/chat/history/:type/:id/file';

  static String chatHistoryImagePath(String type, int id) =>
      '/chat/history/$type/$id/image';

  static String chatHistoryFilePath(String type, int id) =>
      '/chat/history/$type/$id/file';

  /// 系统通知列表 / 详情。
  static const String chatSystem = '/chat/system';
  static const String chatSystemContent = '/chat/system/content/:id';

  static String chatSystemContentPath(int id, {String? title}) {
    final q = (title != null && title.isNotEmpty)
        ? '?title=${Uri.encodeComponent(title)}'
        : '';
    return '/chat/system/content/$id$q';
  }

  static const String chatVideo = '/chat/video';

  /// 私聊音视频通话页。
  static const String chatRtcPrivate = '/chat/rtc/private';

  static String chatRtcPrivatePath({
    required String mode,
    required Friend friend,
    required bool isHost,
  }) {
    final q = Uri(queryParameters: {
      'mode': mode,
      'isHost': isHost.toString(),
      'friend': Uri.encodeComponent(jsonEncode(friend.toJson())),
    });
    return '${AppRoutes.chatRtcPrivate}?${q.query}';
  }

  /// 群聊音视频通话页。
  static const String chatRtcGroup = '/chat/rtc/group';

  static String chatRtcGroupPath({
    required int groupId,
    required int inviterId,
    required bool isHost,
    required List<Map<String, dynamic>> userInfos,
  }) {
    final q = Uri(queryParameters: {
      'groupId': groupId.toString(),
      'inviterId': inviterId.toString(),
      'isHost': isHost.toString(),
      'userInfos': Uri.encodeComponent(jsonEncode(userInfos)),
    });
    return '${AppRoutes.chatRtcGroup}?${q.query}';
  }

  static String chatVideoPath(String url, {String? poster}) {
    final q = Uri(queryParameters: {
      'url': url,
      if (poster != null && poster.isNotEmpty) 'poster': poster,
    });
    return '${AppRoutes.chatVideo}?${q.query}';
  }
}

/// 页面可见性观察（对齐 uniapp onShow）。
final imRouteObserver = RouteObserver<ModalRoute<void>>();

/// 根 Navigator，供 WS 后台任务等无 BuildContext 场景弹窗。
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 全局路由。鉴权重定向由 authControllerProvider 驱动：
/// unknown → 主框架（原生闪屏遮住）；unauthenticated → login；authenticated → main。
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<AuthStatus>(ref.read(authControllerProvider));
  ref.onDispose(refresh.dispose);
  ref.listen<AuthStatus>(
    authControllerProvider,
    (_, next) => refresh.value = next,
  );

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    observers: [imRouteObserver],
    refreshListenable: refresh,
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFEEF0F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '页面加载失败，请重启应用\n${state.error}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
    redirect: (context, state) {
      final status = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      final onAuthPage = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.resetPwd;

      // 启动判定中：先展示登录页，避免闪屏去掉后长时间空白。
      if (status == AuthStatus.unknown) {
        return onAuthPage ? null : AppRoutes.login;
      }

      final loggedIn = status == AuthStatus.authenticated;

      if (!loggedIn) {
        // 未登录：允许登录/注册/找回密码页，其余踢回登录。
        return onAuthPage ? null : AppRoutes.login;
      }
      // 已登录：鉴权页一律进主框架。
      if (onAuthPage) {
        return AppRoutes.main;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.resetPwd,
        builder: (context, state) {
          final m = state.uri.queryParameters['mode'];
          return ResetPwdPage(
            mode: m == 'email' ? ResetMode.email : ResetMode.phone,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.qrConfirm,
        builder: (context, state) => QrLoginConfirmPage(
          qrCode: state.uri.queryParameters['qrCode'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.main,
        builder: (_, _) => const MainShell(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.friendAdd,
        builder: (context, state) => FriendAddPage(
          keyword: state.uri.queryParameters['keyword'] ??
              (state.extra is String ? state.extra as String : null),
        ),
      ),
      GoRoute(
        path: AppRoutes.friendContact,
        builder: (_, _) => const FriendContactPage(),
      ),
      GoRoute(
        path: AppRoutes.friendApply,
        builder: (context, state) => FriendApplyPage(
          userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.friendRequests,
        builder: (_, _) => const FriendRequestPage(),
      ),
      GoRoute(
        path: AppRoutes.friendUser,
        builder: (context, state) => UserInfoPage(
          userId: int.tryParse(state.pathParameters['userId'] ?? '') ?? 0,
          requestId: int.tryParse(state.uri.queryParameters['requestId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.friendRemark,
        builder: (context, state) => FriendRemarkPage(
          friendId: int.tryParse(state.pathParameters['friendId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.groupList,
        builder: (_, _) => const GroupListPage(),
      ),
      GoRoute(
        path: AppRoutes.mineProfile,
        builder: (_, _) => const ProfileEditPage(),
      ),
      GoRoute(
        path: AppRoutes.mineAccount,
        builder: (_, _) => const AccountPage(),
      ),
      GoRoute(
        path: AppRoutes.minePassword,
        builder: (_, _) => const PasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.mineBindPhone,
        builder: (_, _) => const BindPhonePage(),
      ),
      GoRoute(
        path: AppRoutes.mineBindEmail,
        builder: (_, _) => const BindEmailPage(),
      ),
      GoRoute(
        path: AppRoutes.mineTeenager,
        builder: (_, _) => const TeenagerPage(),
      ),
      GoRoute(
        path: AppRoutes.mineAbout,
        builder: (_, _) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.mineQrcode,
        builder: (_, _) => const MineQrcodePage(),
      ),
      GoRoute(
        path: AppRoutes.groupCreate,
        builder: (_, _) => const GroupEditPage(),
      ),
      GoRoute(
        path: AppRoutes.groupEdit,
        builder: (context, state) => GroupEditPage(
          groupId: int.tryParse(state.pathParameters['groupId'] ?? ''),
        ),
      ),
      GoRoute(
        path: AppRoutes.groupMember,
        builder: (context, state) => GroupMemberPage(
          groupId: int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.groupInvite,
        builder: (context, state) => GroupInvitePage(
          groupId: int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.groupQrcode,
        builder: (context, state) => GroupQrcodePage(
          groupId: int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0,
          isAllowInvite:
              state.uri.queryParameters['isAllowInvite'] != 'false',
        ),
      ),
      GoRoute(
        path: AppRoutes.groupSetting,
        builder: (context, state) => GroupSettingPage(
          groupId: int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.groupManager,
        builder: (context, state) => GroupManagerPage(
          groupId: int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? ChatType.private;
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          final locateId =
              int.tryParse(state.uri.queryParameters['locateId'] ?? '');
          return ChatBoxPage(
            chatType: type,
            targetId: id,
            locateMessageId: locateId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (_, _) => const ScanPage(),
      ),
      GoRoute(
        path: AppRoutes.externalLink,
        builder: (context, state) {
          final url = state.uri.queryParameters['url'] ?? '';
          return ExternalLinkPage(url: Uri.decodeComponent(url));
        },
      ),
      GoRoute(
        path: AppRoutes.chatHistory,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? ChatType.private;
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ChatHistoryPage(chatType: type, targetId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.chatHistoryImage,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? ChatType.private;
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ChatHistoryImagePage(chatType: type, targetId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.chatHistoryFile,
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? ChatType.private;
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ChatHistoryFilePage(chatType: type, targetId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.chatSystem,
        builder: (_, _) => const ChatSystemPage(),
      ),
      GoRoute(
        path: AppRoutes.chatSystemContent,
        builder: (context, state) => ChatSystemContentPage(
          messageId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          title: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        path: AppRoutes.chatVideo,
        builder: (context, state) => ChatVideoPage(
          url: state.uri.queryParameters['url'] ?? '',
          poster: state.uri.queryParameters['poster'],
        ),
      ),
      GoRoute(
        path: AppRoutes.chatRtcPrivate,
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'video';
          final isHost = state.uri.queryParameters['isHost'] == 'true';
          Friend friend = Friend(id: 0, showNickName: '未知用户');
          final rawFriend = state.uri.queryParameters['friend'];
          if (rawFriend != null && rawFriend.isNotEmpty) {
            try {
              final decoded = jsonDecode(Uri.decodeComponent(rawFriend));
              if (decoded is Map<String, dynamic>) {
                friend = Friend.fromJson(decoded);
              }
            } catch (_) {}
          }
          return RtcPrivatePage(
            mode: mode,
            isHost: isHost,
            friend: friend,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.chatRtcGroup,
        builder: (context, state) {
          final groupId =
              int.tryParse(state.uri.queryParameters['groupId'] ?? '') ?? 0;
          final inviterId =
              int.tryParse(state.uri.queryParameters['inviterId'] ?? '') ?? 0;
          final isHost = state.uri.queryParameters['isHost'] == 'true';
          var userInfos = <Map<String, dynamic>>[];
          final rawUsers = state.uri.queryParameters['userInfos'];
          if (rawUsers != null && rawUsers.isNotEmpty) {
            try {
              final decoded = jsonDecode(Uri.decodeComponent(rawUsers));
              if (decoded is List) {
                userInfos = decoded
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
              }
            } catch (_) {}
          }
          return RtcGroupPage(
            groupId: groupId,
            inviterId: inviterId,
            isHost: isHost,
            userInfos: userInfos,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.groupInfo,
        builder: (context, state) => GroupInfoPage(
          groupId: int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0,
        ),
      ),
    ],
  );
});
