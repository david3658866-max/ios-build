import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:vortek/core/config/app_constants.dart';
import 'package:vortek/core/di/app_providers.dart';
import 'package:vortek/core/line/line_config.dart';
import 'package:vortek/core/storage/kv_store.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/core/utils/auth_form_util.dart';
import 'package:vortek/core/utils/auth_login_mode_util.dart';
import 'package:vortek/core/utils/policy_consent_util.dart';
import 'package:vortek/pages/login/login_page.dart';
import 'package:vortek/pages/login/register_page.dart';
import 'package:vortek/pages/login/reset_pwd_page.dart';
import 'package:vortek/pages/main/tabs/mine_tab.dart';
import 'package:vortek/pages/mine/about_page.dart';
import 'package:vortek/pages/mine/account_page.dart';
import 'package:vortek/router/app_router.dart';
import 'package:vortek/stores/user_store.dart';
import 'package:vortek/widgets/auth/policy_consent_panel.dart';

class _FakeUserStore extends UserStore {
  _FakeUserStore(this._user);

  final User? _user;

  @override
  User? build() => _user;
}

/// 登录/注册页测试用线路：跳过 HTTP 探活，避免 widget test 挂起。
class _FakeLine extends LineNotifier {
  @override
  LineConfig build() => kDefaultLine;

  @override
  Future<bool> checkCurrentLineStatus({bool allowFallback = true}) async =>
      true;
}

/// 登录/注册 Hero 较高，默认 600 高测试视口会溢出；我的 Tab ListView 需更高视口才懒加载到底部菜单。
void _useTallPhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1624);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDir;
  late KvStore kv;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('auth_mine_');
    Hive.init(hiveDir.path);
    kv = await KvStore.open();
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  group('AuthFormUtil', () {
    test('手机号校验与 uniapp 一致', () {
      expect(AuthFormUtil.phoneValidationError(''), '请输入手机号');
      expect(AuthFormUtil.phoneValidationError('123'), '手机号格式错误');
      expect(AuthFormUtil.phoneValidationError('13812345678'), isNull);
    });

    test('密码登录不需要图形验证码', () {
      expect(AuthFormUtil.passwordLoginRequiresCaptcha, isFalse);
    });
  });

  group('AuthLoginModeUtil 对齐 login.vue modes', () {
    test('当前仅启用 username 模式', () {
      expect(AuthLoginModeUtil.enabledModes, [AuthLoginMode.username]);
      expect(AuthLoginModeUtil.showModeSwitcher, isFalse);
    });

    test('resolveUserName 手机号映射为 userName', () {
      expect(
        AuthLoginModeUtil.resolveUserName(
          mode: AuthLoginMode.username,
          phone: '13812345678',
        ),
        '13812345678',
      );
    });

    test('displayName 对齐 modeNameMap', () {
      expect(
        AuthLoginModeUtil.displayName(AuthLoginMode.username),
        '密码登录',
      );
    });
  });

  group('PolicyConsentUtil', () {
    test('storageKey 对齐 uniapp has_read_privacy', () {
      expect(PolicyConsentUtil.storageKey, StorageKeys.hasReadPrivacy);
      expect(StorageKeys.hasReadPrivacy, 'has_read_privacy');
    });

    test('shouldShowConsent 未同意且在目标平台时展示', () async {
      expect(
        PolicyConsentUtil.shouldShowConsent(
          kv: kv,
          isTargetPlatformOverride: true,
        ),
        isTrue,
      );
      await PolicyConsentUtil.markAccepted(kv);
      expect(
        PolicyConsentUtil.shouldShowConsent(
          kv: kv,
          isTargetPlatformOverride: true,
        ),
        isFalse,
      );
    });

    test('shouldShowConsent 非目标平台不展示', () {
      expect(
        PolicyConsentUtil.shouldShowConsent(
          kv: kv,
          isTargetPlatformOverride: false,
        ),
        isFalse,
      );
    });
  });

  group('登录页 UI 契约', () {
    testWidgets('LoginPage 显示密码登录 Hero', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kvStoreProvider.overrideWithValue(kv),
            lineProvider.overrideWith(_FakeLine.new),
          ],
          child: const MaterialApp(home: LoginPage()),
        ),
      );
      await tester.pump();
      expect(find.text('密码登录'), findsOneWidget);
      expect(find.text('立即登录'), findsOneWidget);
      expect(find.text('立即注册'), findsOneWidget);
    });

    testWidgets('PolicyConsentPanel 显示协议文案与按钮', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PolicyConsentPanel(
              onAgree: () {},
              onDecline: () {},
              onOpenProtocol: () {},
              onOpenPrivacy: () {},
            ),
          ),
        ),
      );
      expect(find.text('服务协议和隐私政策'), findsOneWidget);
      expect(find.text('暂不使用'), findsOneWidget);
      expect(find.text('同意'), findsOneWidget);
    });
  });

  group('注册页 UI 契约', () {
    testWidgets('RegisterPage 手机注册三字段', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            kvStoreProvider.overrideWithValue(kv),
            lineProvider.overrideWith(_FakeLine.new),
          ],
          child: const MaterialApp(home: RegisterPage()),
        ),
      );
      await tester.pump();
      expect(find.text('手机注册'), findsOneWidget);
      expect(find.text('请填写手机号码'), findsOneWidget);
      expect(find.text('请设置密码'), findsOneWidget);
      expect(find.text('请输入6位数字邀请码'), findsOneWidget);
      expect(find.text('确认密码'), findsNothing);
    });
  });

  group('找回密码页 UI 契约', () {
    testWidgets('ResetPwdPage 无页内模式切换', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPwdPage(mode: ResetMode.phone),
        ),
      );
      expect(find.text('验证身份，设置新密码'), findsOneWidget);
      expect(find.byType(SegmentedButton<ResetMode>), findsNothing);
      expect(find.text('重置密码'), findsWidgets);
    });
  });

  group('我的 Tab UI 契约', () {
    testWidgets('MineTab 菜单与头部', (tester) async {
      _useTallPhoneViewport(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStoreProvider.overrideWith(
              () => _FakeUserStore(
                const User(
                  id: 10001,
                  userName: 'tester',
                  nickName: '测试用户',
                  signature: '个性签名',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: MineTab()),
        ),
      );
      expect(find.text('我的'), findsOneWidget);
      expect(find.text('测试用户'), findsOneWidget);
      expect(find.text('个人资料'), findsOneWidget);
      expect(find.text('账号安全'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('关于${AppConstants.appName}'), findsOneWidget);
    });
  });

  group('账号安全页 UI 契约', () {
    testWidgets('AccountPage 绑定信息脱敏展示', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userStoreProvider.overrideWith(
              () => _FakeUserStore(
                const User(
                  id: 1,
                  userName: 'tester',
                  phone: '13812345678',
                  email: 'alice@example.com',
                ),
              ),
            ),
          ],
          child: const MaterialApp(home: AccountPage()),
        ),
      );
      await tester.pump();
      expect(find.text('账号安全'), findsOneWidget);
      expect(find.text('138****5678'), findsOneWidget);
      expect(find.text('a****@example.com'), findsOneWidget);
    });
  });

  group('关于页外链', () {
    test('协议/隐私走路由 external-link', () {
      expect(
        AppRoutes.externalLinkPath(AppConstants.protocolUrl),
        contains('/external-link?url='),
      );
      expect(
        AppRoutes.externalLinkPath(AppConstants.privacyUrl),
        contains('/external-link?url='),
      );
    });

    testWidgets('AboutPage 显示版本与协议入口', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: AboutPage()),
        ),
      );
      await tester.pump();
      expect(find.text('关于我们'), findsOneWidget);
      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('用户协议'), findsOneWidget);
      expect(find.text('隐私政策'), findsOneWidget);
    });
  });
}
