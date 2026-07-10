import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/rtc_service.dart';
import '../../stores/user_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../im_confirm_dialog.dart';
import 'head_image.dart';

/// 加入进行中的群通话确认弹窗。对齐 group-rtc-join.vue。
class GroupRtcJoinSheet {
  GroupRtcJoinSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required int groupId,
    required Map<String, dynamic> rtcInfo,
  }) async {
    final ok = await showImConfirmDialog(
      context,
      title: '是否加入通话?',
      confirmText: '加入',
      body: _RtcJoinBody(rtcInfo: rtcInfo),
    );
    if (ok != true || !context.mounted) return;
    _joinCall(context, ref, groupId: groupId, rtcInfo: rtcInfo);
  }

  static void _joinCall(
    BuildContext context,
    WidgetRef ref, {
    required int groupId,
    required Map<String, dynamic> rtcInfo,
  }) {
    final mine = ref.read(userStoreProvider);
    if (mine == null) return;

    final rawUsers = rtcInfo['userInfos'];
    final users = <Map<String, dynamic>>[];
    if (rawUsers is List) {
      for (final item in rawUsers) {
        if (item is Map) {
          users.add(Map<String, dynamic>.from(item));
        }
      }
    }
    if (!users.any((u) => u['id'] == mine.id)) {
      users.add({
        'id': mine.id,
        'nickName': mine.nickName,
        'headImage': mine.headImageThumb ?? mine.headImage ?? '',
        'isCamera': false,
        'isMicroPhone': true,
        'isShareScreen': false,
      });
    }

    ref.read(rtcServiceProvider).openJoinGroupCall(
          groupId: groupId,
          inviterId: mine.id,
          userInfos: users,
        );
  }
}

class _RtcJoinBody extends StatelessWidget {
  const _RtcJoinBody({required this.rtcInfo});

  final Map<String, dynamic> rtcInfo;

  @override
  Widget build(BuildContext context) {
    final host = rtcInfo['host'];
    final hostMap = host is Map ? Map<String, dynamic>.from(host) : null;
    final rawUsers = rtcInfo['userInfos'];
    final users = <Map<String, dynamic>>[];
    if (rawUsers is List) {
      for (final item in rawUsers) {
        if (item is Map) {
          users.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hostMap != null) ...[
          Text(
            '发起人',
            style: TextStyle(
              fontSize: rpx(context, 28),
              color: ImColors.textLight,
            ),
          ),
          SizedBox(height: rpx(context, 12)),
          HeadImage(
            url: hostMap['headImage']?.toString(),
            name: hostMap['nickName']?.toString(),
            size: rpx(context, 80),
          ),
          SizedBox(height: rpx(context, 20)),
        ],
        Text(
          '${users.length}人正在通话中',
          style: TextStyle(
            fontSize: rpx(context, 28),
            color: ImColors.textLight,
          ),
        ),
        SizedBox(height: rpx(context, 12)),
        SizedBox(
          height: rpx(context, 90),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            separatorBuilder: (_, _) => SizedBox(width: rpx(context, 8)),
            itemBuilder: (_, i) {
              final user = users[i];
              return HeadImage(
                url: user['headImage']?.toString(),
                name: user['nickName']?.toString(),
                size: rpx(context, 80),
              );
            },
          ),
        ),
      ],
    );
  }
}
