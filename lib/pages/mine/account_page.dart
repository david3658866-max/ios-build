import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../core/utils/string_util.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../../widgets/im_bar.dart';
import '../../widgets/im_nav_bar.dart';

/// 账号安全。对齐 mine-account.vue。
class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeRoute());
  }

  @override
  void dispose() {
    imRouteObserver.unsubscribe(this);
    super.dispose();
  }

  void _subscribeRoute() {
    final route = ModalRoute.of(context);
    if (route != null) {
      imRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    ref.read(userStoreProvider.notifier).loadSelf();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStoreProvider);
    final phone = user?.phone?.trim() ?? '';
    final email = user?.email?.trim() ?? '';
    final phoneBound = phone.isNotEmpty;
    final emailBound = email.isNotEmpty;

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      appBar: const ImNavBar(title: '账号安全', showBack: true),
      body: ListView(
        padding: EdgeInsets.only(top: rpx(context, 24)),
        children: [
          ImBarGroup(
            children: [
              ImArrowBar(
                title: '修改密码',
                icon: Icons.security,
                iconColor: ImColors.accent,
                onTap: () => context.push(AppRoutes.minePassword),
              ),
              ImArrowBar(
                title: '绑定手机',
                icon: Icons.phone_android,
                iconColor: const Color(0xFF22C55E),
                trailing: phoneBound
                    ? Text(
                        StringUtil.maskPhone(phone),
                        style: TextStyle(
                          fontSize: rpx(context, 28),
                          color: ImColors.textLighter,
                        ),
                      )
                    : Text(
                        '去绑定',
                        style: TextStyle(
                          fontSize: rpx(context, 28),
                          color: ImColors.accent,
                        ),
                      ),
                onTap: phoneBound
                    ? null
                    : () => context.push(AppRoutes.mineBindPhone),
              ),
              ImArrowBar(
                title: '绑定邮箱',
                icon: Icons.email_outlined,
                iconColor: const Color(0xFF3B82F6),
                trailing: emailBound
                    ? Text(
                        StringUtil.maskEmail(email),
                        style: TextStyle(
                          fontSize: rpx(context, 28),
                          color: ImColors.textLighter,
                        ),
                      )
                    : Text(
                        '去绑定',
                        style: TextStyle(
                          fontSize: rpx(context, 28),
                          color: ImColors.accent,
                        ),
                      ),
                onTap: emailBound
                    ? null
                    : () => context.push(AppRoutes.mineBindEmail),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
