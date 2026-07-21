import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/app_constants.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_nav_bar.dart';

/// 关于我们。
class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
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
                title: '检查新版本',
                trailing: Text(
                  _appVersion,
                  style: TextStyle(
                    fontSize: rpx(context, 26),
                    color: ImColors.textLight,
                  ),
                ),
                // 保留入口，点击无任何提示/弹框。
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
