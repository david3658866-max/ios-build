import 'package:flutter/material.dart';

import '../../core/enums/chat_type.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/message_long_press_util.dart';
import '../../core/utils/chat_item_util.dart';
import '../../core/utils/date_util.dart';
import '../../core/utils/emotion_util.dart';
import '../../core/utils/string_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import 'emotion_text.dart';
import 'head_image.dart';

/// 会话列表项。对齐 im-uniapp components/chat-item/chat-item.vue。
class ChatItem extends StatelessWidget {
  const ChatItem({
    super.key,
    required this.chat,
    this.searchKeyword,
    this.onTap,
    this.onLongPress,
    this.online = false,
  });

  final Chat chat;
  final String? searchKeyword;
  final VoidCallback? onTap;
  final void Function(Offset globalPosition)? onLongPress;
  final bool online;

  static const _textHeightBehavior = TextHeightBehavior(
    applyHeightToFirstAscent: true,
    applyHeightToLastDescent: true,
  );

  static const _previewEmojiSizeRpx = 36.0;

  TextStyle _titleStyle(BuildContext context) =>
      TextStyle(fontSize: rpx(context, 34), height: 1.0, color: ImColors.text);

  TextStyle _metaStyle(BuildContext context) => TextStyle(
    fontSize: rpx(context, 26),
    height: 1.0,
    color: ImColors.textLighter,
  );

  TextStyle _previewStyle(BuildContext context) => TextStyle(
    fontSize: rpx(context, 28),
    height: 1.0,
    color: ImColors.textLighter,
  );

  bool get _enableKeywordHighlight {
    final keyword = searchKeyword?.trim();
    return keyword != null && keyword.isNotEmpty;
  }

  Widget _highlightText(
    BuildContext context, {
    required String text,
    required TextStyle style,
    int maxLines = 1,
    TextOverflow overflow = TextOverflow.ellipsis,
  }) {
    final keyword = searchKeyword?.trim();
    if (keyword == null || keyword.isEmpty || text.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        textHeightBehavior: _textHeightBehavior,
        style: style,
      );
    }
    final reg = RegExp(RegExp.escape(keyword), caseSensitive: false);
    final matches = reg.allMatches(text).toList();
    if (matches.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        textHeightBehavior: _textHeightBehavior,
        style: style,
      );
    }

    final spans = <InlineSpan>[];
    var start = 0;
    for (final m in matches) {
      if (m.start > start) {
        spans.add(TextSpan(text: text.substring(start, m.start), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(m.start, m.end),
          style: style.copyWith(
            color: ImColors.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      start = m.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
      textHeightBehavior: _textHeightBehavior,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hairline = 1 / MediaQuery.devicePixelRatioOf(context);
    final titleLineHeight = rpx(context, 34);
    final previewLineHeight = rpx(context, _previewEmojiSizeRpx);
    final contentGap = rpx(context, 8);

    return Material(
      color: chat.isTop ? const Color(0xFFF7F8FF) : Colors.white,
      child: wrapMessageLongPress(
        InkWell(
          onTap: onTap,
          splashColor: ImColors.bgActive.withValues(alpha: 0.5),
          highlightColor: ImColors.bgActive,
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
                      SizedBox(
                        width: rpx(context, 96),
                        height: rpx(context, 96),
                        child: HeadImage(
                          url: chat.headImage,
                          name: chat.showName,
                          size: 96,
                          online: online,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            rpx(context, 20),
                            0,
                            rpx(context, 5),
                            0,
                          ),
                          child: ClipRect(
                            child: SizedBox(
                              height: rpx(context, 96),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: titleLineHeight,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: _highlightText(
                                                  context,
                                                  text: chat.showName ?? '',
                                                  style: _titleStyle(context),
                                                ),
                                              ),
                                              if (StringUtil.isNotBlank(
                                                chat.companyName,
                                              ))
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    left: rpx(context, 3),
                                                  ),
                                                  child: Text(
                                                    '@${chat.companyName}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textHeightBehavior:
                                                        _textHeightBehavior,
                                                    style:
                                                        _previewStyle(
                                                          context,
                                                        ).copyWith(
                                                          color: ImColors
                                                              .companyTag,
                                                        ),
                                                  ),
                                                ),
                                              if (chat.type == ChatType.system)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    left: rpx(context, 8),
                                                  ),
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: rpx(
                                                            context,
                                                            10,
                                                          ),
                                                          vertical: rpx(
                                                            context,
                                                            1,
                                                          ),
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: ImColors.danger,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            rpx(context, 20),
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '官方',
                                                      textHeightBehavior:
                                                          _textHeightBehavior,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: rpx(
                                                          context,
                                                          20,
                                                        ),
                                                        height: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              if (chat.isTop)
                                                Padding(
                                                  padding: EdgeInsets.only(
                                                    left: rpx(context, 8),
                                                  ),
                                                  child: const _TopLabel(),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(
                                            left: rpx(context, 20),
                                          ),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minWidth: rpx(context, 80),
                                            ),
                                            child: Text(
                                              DateUtil.formatSessionTime(
                                                chat.lastSendTime,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.right,
                                              textHeightBehavior:
                                                  _textHeightBehavior,
                                              style: _metaStyle(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: contentGap),
                                  SizedBox(
                                    height: previewLineHeight,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        if (_atText().isNotEmpty)
                                          Text(
                                            _atText(),
                                            maxLines: 1,
                                            textHeightBehavior:
                                                _textHeightBehavior,
                                            style: _previewStyle(
                                              context,
                                            ).copyWith(color: ImColors.danger),
                                          ),
                                        if (shouldShowChatItemSendName(
                                          type: chat.type,
                                          sendNickName: chat.sendNickName,
                                          lastMsgType: chat.lastMsgType,
                                        ))
                                          Flexible(
                                            child: Text(
                                              '${chat.sendNickName}: ',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textHeightBehavior:
                                                  _textHeightBehavior,
                                              style: _previewStyle(context),
                                            ),
                                          ),
                                        Expanded(
                                          child:
                                              isChatItemTextPreview(
                                                    chat.lastMsgType,
                                                  ) &&
                                                  !_enableKeywordHighlight &&
                                                  EmotionUtil.hasEmotion(
                                                    chat.lastContent,
                                                  )
                                              ? EmotionText(
                                                  text: chat.lastContent ?? '',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: _previewStyle(context),
                                                  emojiSize: rpx(
                                                    context,
                                                    _previewEmojiSizeRpx,
                                                  ),
                                                  emojiAlignment:
                                                      PlaceholderAlignment
                                                          .middle,
                                                )
                                              : _highlightText(
                                                  context,
                                                  text: chat.lastContent ?? '',
                                                  style: _previewStyle(context),
                                                ),
                                        ),
                                        if (chat.isDnd)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: rpx(context, 10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .notifications_off_outlined,
                                                  size: rpx(context, 32),
                                                  color: ImColors.textLighter,
                                                ),
                                                if (chat.unreadCount > 0)
                                                  _MutedUnreadBadge(
                                                    count: chat.unreadCount,
                                                  ),
                                              ],
                                            ),
                                          )
                                        else if (chat.unreadCount > 0)
                                          _UnreadBadge(count: chat.unreadCount),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (chat.isTop) const _TopCorner(),
                Positioned(
                  left: rpx(context, 140),
                  right: 0,
                  bottom: 0,
                  child: Container(height: hairline, color: ImColors.border),
                ),
              ],
            ),
          ),
        ),
        onLongPress,
      ),
    );
  }

  String _atText() {
    if (chat.atMe) return '[有人@我]';
    if (chat.atAll) return '[@全体成员]';
    return '';
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      margin: EdgeInsets.only(left: rpx(context, 10)),
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, count > 9 ? 8 : 10),
        vertical: rpx(context, 1),
      ),
      constraints: BoxConstraints(
        minWidth: rpx(context, 32),
        minHeight: rpx(context, 30),
      ),
      decoration: BoxDecoration(
        color: ImColors.danger,
        borderRadius: BorderRadius.circular(rpx(context, 16)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: rpx(context, 22),
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}

class _MutedUnreadBadge extends StatelessWidget {
  const _MutedUnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      margin: EdgeInsets.only(left: rpx(context, 8)),
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, count > 9 ? 8 : 10),
        vertical: rpx(context, 1),
      ),
      constraints: BoxConstraints(
        minWidth: rpx(context, 30),
        minHeight: rpx(context, 28),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7F0),
        borderRadius: BorderRadius.circular(rpx(context, 14)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: ImColors.textLight,
          fontSize: rpx(context, 20),
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
  }
}

class _TopLabel extends StatelessWidget {
  const _TopLabel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: rpx(context, 8),
        vertical: rpx(context, 1),
      ),
      decoration: BoxDecoration(
        color: ImColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(rpx(context, 8)),
        border: Border.all(color: ImColors.accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        '置顶',
        textHeightBehavior: ChatItem._textHeightBehavior,
        style: TextStyle(
          color: ImColors.accent,
          fontSize: rpx(context, 20),
          height: 1.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TopCorner extends StatelessWidget {
  const _TopCorner();

  @override
  Widget build(BuildContext context) {
    final size = rpx(context, 35);
    final radius = rpx(context, 6);
    return Positioned(
      top: rpx(context, 3),
      right: rpx(context, 3),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
        child: CustomPaint(
          size: Size(size, size),
          painter: _TopCornerPainter(context),
        ),
      ),
    );
  }
}

class _TopCornerPainter extends CustomPainter {
  _TopCornerPainter(this.context);

  final BuildContext context;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(path, Paint()..color = ImColors.accent);
    canvas.drawPath(
      path,
      Paint()..shader = ImColors.topCornerGradient.createShader(rect),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: '↑',
        style: TextStyle(color: Colors.white, fontSize: rpx(context, 20)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, rpx(context, 2)));
  }

  @override
  bool shouldRepaint(covariant _TopCornerPainter oldDelegate) =>
      oldDelegate.context != context;
}
