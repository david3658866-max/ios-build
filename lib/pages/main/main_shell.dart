import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/badge_service.dart';
import '../../theme/im_colors.dart';
import '../../widgets/im_tab_bar.dart';
import 'tabs/contacts_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/mine_tab.dart';

/// 主框架：底部三 Tab（消息 / 通讯录 / 我的）。
/// 对应 im-uniapp tabBar + 各 tab 页自定义 nav-bar。
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  static const _tabs = [MessagesTab(), ContactsTab(), MineTab()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshAllBadges(ref);
    });
  }

  void _onTabChanged(int i) {
    setState(() => _index = i);
    refreshAllBadges(ref);
  }

  @override
  Widget build(BuildContext context) {
    bindBadgeAutoRefresh(ref);

    final badgeCounts = ref.watch(badgeCountsProvider);

    return Scaffold(
      backgroundColor: ImColors.pageBg,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: ImTabBar(
        currentIndex: _index,
        onTap: _onTabChanged,
        items: ImTabBar.defaultItems,
        badgeCounts: badgeCounts,
      ),
    );
  }
}
