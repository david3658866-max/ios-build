import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../chat/head_image.dart';

/// 群列表项。对齐 im-uniapp components/group-item/group-item.vue。
class GroupItem extends StatelessWidget {
  const GroupItem({
    super.key,
    required this.group,
    this.onTap,
  });

  final Group group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ImColors.navBarBg,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: rpx(context, 120),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  rpx(context, 24),
                  rpx(context, 10),
                  rpx(context, 24),
                  rpx(context, 10),
                ),
                child: Row(
                  children: [
                    HeadImage(
                      url: group.headImageThumb ?? group.headImage,
                      name: group.showGroupName,
                      size: 84,
                    ),
                    SizedBox(width: rpx(context, 20)),
                    Expanded(
                      child: Text(
                        group.showGroupName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: rpx(context, 32),
                          color: ImColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: rpx(context, 128),
                right: 0,
                bottom: 0,
                child: const Divider(
                  height: 1,
                  thickness: 1,
                  color: ImColors.borderLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
