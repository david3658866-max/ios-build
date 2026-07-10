import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/friend_request.dart';
import '../../stores/friend_store.dart';
import '../../stores/user_store.dart';
import '../../theme/rpx.dart';
import '../../widgets/friend/friend_request_item.dart';
import '../../widgets/im_nav_bar.dart';
import '../../widgets/im_no_data_tip.dart';
import '../../widgets/im_tabs.dart';

/// 新的朋友页。对齐 im-uniapp pages/friend/friend-request.vue。
class FriendRequestPage extends ConsumerStatefulWidget {
  const FriendRequestPage({super.key});

  @override
  ConsumerState<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends ConsumerState<FriendRequestPage> {
  int _tabIdx = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendStoreProvider.notifier).loadRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendState = ref.watch(friendStoreProvider);
    final mineId = ref.watch(userStoreProvider)?.id;
    final recvRequests = mineId == null
        ? <FriendRequest>[]
        : friendState.requests.where((r) => r.recvId == mineId).toList();
    final sendRequests = mineId == null
        ? <FriendRequest>[]
        : friendState.requests.where((r) => r.sendId == mineId).toList();

    final items = [
      '我收到的(${recvRequests.length})',
      '我发起的(${sendRequests.length})',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const ImNavBar(
        title: '新的朋友',
        showBack: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(rpx(context, 20)),
            child: ImTabs(
              items: items,
              current: _tabIdx,
              onChanged: (i) => setState(() => _tabIdx = i),
            ),
          ),
          Expanded(
            child: _tabIdx == 0
                ? _RequestList(
                    requests: recvRequests,
                    emptyTip: '您未收到申请',
                    isRecvTab: true,
                  )
                : _RequestList(
                    requests: sendRequests,
                    emptyTip: '您未发起申请',
                    isRecvTab: false,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.emptyTip,
    required this.isRecvTab,
  });

  final List<FriendRequest> requests;
  final String emptyTip;
  final bool isRecvTab;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return ImNoDataTip(tip: emptyTip);
    }
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) => FriendRequestItem(
        request: requests[index],
        isRecvTab: isRecvTab,
      ),
    );
  }
}
