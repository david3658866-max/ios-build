import 'package:flutter/material.dart';



import '../../core/enums/message_type.dart';

import '../../core/storage/app_database.dart';

import '../../core/utils/group_sender_util.dart';

import '../../theme/im_colors.dart';

import '../../theme/im_icons.dart';

import '../../theme/rpx.dart';

import '../../widgets/im_icon.dart';

import 'chat_sender_name_row.dart';



/// 语音/视频通话记录气泡（type 40/41）。对齐 chat-message-item.vue `.chat-realtime`。

class ActRtMessageBubble extends StatelessWidget {

  const ActRtMessageBubble({

    super.key,

    required this.message,

    required this.selfSend,

    this.senderName,

    this.senderRoles = const {},

    this.onTap,

    this.onLongPress,

  });



  final Message message;

  final bool selfSend;

  final String? senderName;

  final Set<GroupSenderRole> senderRoles;

  final VoidCallback? onTap;

  final VoidCallback? onLongPress;



  bool get _isVideo => message.type == MessageType.actRtVideo;



  @override

  Widget build(BuildContext context) {

    final text = message.content ?? '';

    final textColor = selfSend ? Colors.white : ImColors.text;

    final iconColor = selfSend ? Colors.white : ImColors.accent;

    final icon = _isVideo ? ImIcons.chatVideo : ImIcons.chatVoice;



    return Column(

      crossAxisAlignment:

          selfSend ? CrossAxisAlignment.end : CrossAxisAlignment.start,

      children: [

        ?chatSenderNameLine(

          context,

          selfSend: selfSend,

          name: senderName,

          roles: senderRoles,

        ),

        Row(

          mainAxisAlignment:

              selfSend ? MainAxisAlignment.end : MainAxisAlignment.start,

          children: [

            Flexible(

              child: GestureDetector(

                onTap: onTap,

                onLongPress: onLongPress,

                behavior: HitTestBehavior.opaque,

                child: Container(

                  padding: EdgeInsets.fromLTRB(

                    rpx(context, selfSend ? 16 : 20),

                    rpx(context, 16),

                    rpx(context, selfSend ? 20 : 16),

                    rpx(context, 16),

                  ),

                  decoration: BoxDecoration(

                    color: selfSend ? ImColors.bubbleMine : Colors.white,

                    borderRadius: BorderRadius.circular(rpx(context, 20)),

                  ),

                  child: Row(

                    mainAxisSize: MainAxisSize.min,

                    children: selfSend

                        ? [

                            Text(

                              text,

                              style: TextStyle(

                                fontSize: rpx(context, 32),

                                color: textColor,

                                height: 1.4,

                              ),

                            ),

                            SizedBox(width: rpx(context, 12)),

                            Transform.flip(

                              flipX: true,

                              child: ImIcon(

                                icon,

                                size: rpx(context, 40),

                                color: iconColor,

                              ),

                            ),

                          ]

                        : [

                            ImIcon(

                              icon,

                              size: rpx(context, 40),

                              color: iconColor,

                            ),

                            SizedBox(width: rpx(context, 12)),

                            Text(

                              text,

                              style: TextStyle(

                                fontSize: rpx(context, 32),

                                color: textColor,

                                height: 1.4,

                              ),

                            ),

                          ],

                  ),

                ),

              ),

            ),

            if (!selfSend) SizedBox(width: rpx(context, 8)),

          ],

        ),

      ],

    );

  }

}


