import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../api/api_providers.dart';
import '../../core/config/app_constants.dart';
import '../../core/http/api_result.dart';
import '../../router/app_router.dart';
import '../../services/upgrade_service.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_feedback.dart';

/// 关于我们。对齐 mine-about-us.vue。
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  bool _checking = false;
  String _appVersion = AppConstants.appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final pkg = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = pkg.version);
  }

  void _openInAppLink(String url) {
    context.push(AppRoutes.externalLinkPath(url));
  }

  void _snack(String msg) => ImFeedback.toast(context, msg);

  Future<void> _onCheckVersion() async {
    if (!AppConstants.upgradeEnabled) {
      _snack('当前为测试版本，暂未开放更新');
      return;
    }
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final pkg = await PackageInfo.fromPlatform();
      final res = await ref.read(systemApiProvider).checkVersion(pkg.version);
      if (!mounted) return;
      if (res['isLatestVersion'] == true) {
        _snack('已是最新版本');
      } else {
        await UpgradeService.showUpgradeDialog(
          context,
          changeLog: UpgradeService.parseChangeLog(res['changeLog']),
          isForcedUpdate: res['isForcedUpdate'] == true,
        );
      }
    } catch (e) {
      if (mounted) _snack(asApiException(e).message);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '关于我们', showBack: true),
      body: ListView(
        padding: EdgeInsets.only(top: rpx(context, 24)),
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(
              rpx(context, 24),
              0,
              rpx(context, 24),
              rpx(context, 24),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: rpx(context, 100),
              vertical: rpx(context, 60),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(rpx(context, 24)),
              boxShadow: [
                BoxShadow(
                  color: ImColors.accent.withValues(alpha: 0.06),
                  blurRadius: rpx(context, 24),
                  offset: Offset(0, rpx(context, 6)),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(rpx(context, 40)),
                    boxShadow: [
                      BoxShadow(
                        color: ImColors.accent.withValues(alpha: 0.3),
                        blurRadius: rpx(context, 28),
                        offset: Offset(0, rpx(context, 12)),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(rpx(context, 40)),
                    child: Image.asset(
                      'assets/image/app_logo.png',
                      width: rpx(context, 160),
                      height: rpx(context, 160),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    rpx(context, 20),
                    rpx(context, 24),
                    rpx(context, 20),
                    rpx(context, 10),
                  ),
                  child: Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: rpx(context, 38),
                      fontWeight: FontWeight.bold,
                      color: ImColors.text,
                    ),
                  ),
                ),
                Text(
                  '版本:$_appVersion',
                  style: TextStyle(
                    fontSize: rpx(context, 30),
                    color: ImColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          ImBarGroup(
            dividerIndent: 32,
            children: [
              ImArrowBar(
                title: '用户协议',
                onTap: () => _openInAppLink(AppConstants.protocolUrl),
              ),
              ImArrowBar(
                title: '隐私政策',
                onTap: () => _openInAppLink(AppConstants.privacyUrl),
              ),
              ImArrowBar(
                title: '检查新版本',
                trailing: _checking
                    ? SizedBox(
                        width: rpx(context, 32),
                        height: rpx(context, 32),
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _appVersion,
                        style: TextStyle(
                          fontSize: rpx(context, 26),
                          color: ImColors.textLight,
                        ),
                      ),
                onTap: _onCheckVersion,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
