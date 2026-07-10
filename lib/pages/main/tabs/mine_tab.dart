import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../router/app_router.dart';

import '../../../core/config/app_constants.dart';
import '../../../core/utils/avatar_util.dart';
import '../../../stores/user_store.dart';
import '../../../theme/im_colors.dart';
import '../../../theme/rpx.dart';
import '../../../widgets/chat/head_image.dart';
import '../../../widgets/im_bar.dart';
import '../../../widgets/im_nav_bar.dart';
import '../../../widgets/im_feedback.dart';

/// 菜单图标色。对齐 mine.vue arrow-bar icon-color。
const _mineIconProfile = ImColors.accent;
const _mineIconSecurity = Color(0xFF22C55E);
const _mineIconSettings = Color(0xFF6B7280);
const _mineIconAbout = Color(0xFFEF975D);

/// 我的 Tab。UI 对齐 pages/mine/mine.vue（子页 M3 实现）。
class MineTab extends ConsumerWidget {
  const MineTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userStoreProvider);
    final name = user?.nickName ?? user?.userName ?? '未登录';
    final avatar = AvatarUtil.pick(
      thumb: user?.headImageThumb,
      origin: user?.headImage,
    );

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '我的'),
      body: ListView(
        padding: EdgeInsets.only(top: rpx(context, 24)),
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.mineProfile),
            behavior: HitTestBehavior.opaque,
            child: _UserHeader(
              name: name,
              userName: user?.userName,
              userId: user?.id,
              signature: user?.signature,
              companyName: user?.companyName,
              sex: user?.sex,
              avatarUrl: avatar,
            ),
          ),
          ImBarGroup(
            children: [
              ImArrowBar(
                title: '个人资料',
                icon: Icons.contacts,
                iconColor: _mineIconProfile,
                onTap: () => context.push(AppRoutes.mineProfile),
              ),
              ImArrowBar(
                title: '账号安全',
                icon: Icons.lock,
                iconColor: _mineIconSecurity,
                onTap: () => context.push(AppRoutes.mineAccount),
              ),
            ],
          ),
          ImBarGroup(
            children: [
              ImArrowBar(
                title: '设置',
                icon: Icons.settings,
                iconColor: _mineIconSettings,
                onTap: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
          ImBarGroup(
            children: [
              ImArrowBar(
                title: '关于${AppConstants.appName}',
                icon: Icons.info,
                iconColor: _mineIconAbout,
                onTap: () => context.push(AppRoutes.mineAbout),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({
    required this.name,
    this.userName,
    this.userId,
    this.signature,
    this.companyName,
    this.sex,
    this.avatarUrl,
  });

  final String name;
  final String? userName;
  final int? userId;
  final String? signature;
  final String? companyName;
  final int? sex;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        rpx(context, 24),
        0,
        rpx(context, 24),
        rpx(context, 24),
      ),
      padding: EdgeInsets.symmetric(
        vertical: rpx(context, 40),
        horizontal: rpx(context, 32),
      ),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: ImColors.mineHeaderGradient,
        borderRadius: BorderRadius.circular(rpx(context, 28)),
        boxShadow: [
          BoxShadow(
            color: ImColors.accent.withValues(alpha: 0.28),
            blurRadius: rpx(context, 32),
            offset: Offset(0, rpx(context, 12)),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeaderAvatar(name: name, url: avatarUrl),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: rpx(context, 36)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: rpx(context, 14)),
                    child: Row(
                      spacing: rpx(context, 10),
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: rpx(context, 34),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (companyName != null && companyName!.isNotEmpty)
                          Flexible(
                            child: Text(
                              '@$companyName',
                              style: TextStyle(
                                fontSize: rpx(context, 28),
                                color: ImColors.companyTag,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (sex == 0)
                          Icon(
                            Icons.male,
                            size: rpx(context, 32),
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        if (sex == 1)
                          Icon(
                            Icons.female,
                            size: rpx(context, 32),
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                      ],
                    ),
                  ),
                  if (userId != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: rpx(context, 8)),
                      child: _InfoRow(
                        label: '用户编号:',
                        value: '$userId',
                        onCopy: () {
                          Clipboard.setData(ClipboardData(text: '$userId'));
                          ImFeedback.toast(
                            context,
                            "内容'$userId'已复制",
                          );
                        },
                      ),
                    ),
                  if (userName != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: rpx(context, 8)),
                      child: _InfoRow(label: '用户名:', value: userName!),
                    ),
                  if (signature != null && signature!.isNotEmpty)
                    Text(
                      signature!,
                      style: TextStyle(
                        fontSize: rpx(context, 30),
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: rpx(context, 50),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => context.push(AppRoutes.mineQrcode),
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.qr_code,
                    size: rpx(context, 38),
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: rpx(context, 30)),
                Icon(
                  Icons.chevron_right,
                  size: rpx(context, 30),
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 头像白环。对齐 mine.vue `.head-image` box-shadow ring。
class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final ring = rpx(context, 6);
    return Container(
      padding: EdgeInsets.all(ring),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.35),
      ),
      child: HeadImage(url: url, name: name, size: 160),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: rpx(context, 28),
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(width: rpx(context, 10)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: rpx(context, 28),
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopy != null)
          GestureDetector(
            onTap: onCopy,
            child: Container(
              width: rpx(context, 44),
              height: rpx(context, 44),
              margin: EdgeInsets.only(left: rpx(context, 10)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.copy,
                size: rpx(context, 22),
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}
