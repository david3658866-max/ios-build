import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/chat_type.dart';
import '../../core/storage/app_database.dart';
import '../../core/utils/string_util.dart';
import '../../stores/chat_store.dart';
import '../../stores/friend_store.dart';
import '../../stores/group_store.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../im_form.dart';
import '../im_search_bar.dart';
import 'head_image.dart';

/// 最近会话选择底部弹层。对齐 im-uniapp components/chat-selector。
class ChatPickerSheet {
  ChatPickerSheet._();

  /// 返回选中的会话列表；取消返回 null。
  static Future<List<Chat>?> show(
    BuildContext context, {
    String title = '选择最近联系人',
    bool multiSelect = true,
  }) {
    return showModalBottomSheet<List<Chat>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChatPickerSheet(
        title: title,
        multiSelect: multiSelect,
      ),
    );
  }
}

class _SelectableChat {
  _SelectableChat({required this.chat, this.checked = false});

  final Chat chat;
  bool checked;
}

class _ChatPickerSheet extends ConsumerStatefulWidget {
  const _ChatPickerSheet({
    required this.title,
    required this.multiSelect,
  });

  final String title;
  final bool multiSelect;

  @override
  ConsumerState<_ChatPickerSheet> createState() => _ChatPickerSheetState();
}

class _ChatPickerSheetState extends ConsumerState<_ChatPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _searchText = '';
  final List<_SelectableChat> _checked = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isValidChat(Chat chat) {
    if (chat.type == ChatType.system) return false;
    if (chat.type == ChatType.private) {
      return ref.read(friendStoreProvider.notifier).isFriend(chat.targetId);
    }
    if (chat.type == ChatType.group) {
      return ref.read(groupStoreProvider.notifier).isGroup(chat.targetId);
    }
    return false;
  }

  List<Chat> _sourceChats() {
    final chats = ref.watch(chatListStreamProvider).value ?? const [];
    return chats.where(_isValidChat).toList();
  }

  List<Chat> _visibleChats() {
    final list = _sourceChats();
    if (_searchText.isEmpty) return list;
    return list
        .where((c) => (c.showName ?? '').contains(_searchText))
        .toList();
  }

  bool _isChecked(Chat chat) {
    return _checked.any(
      (e) => e.chat.type == chat.type && e.chat.targetId == chat.targetId,
    );
  }

  void _toggle(Chat chat) {
    if (!widget.multiSelect) {
      Navigator.pop(context, [chat]);
      return;
    }
    setState(() {
      final idx = _checked.indexWhere(
        (e) => e.chat.type == chat.type && e.chat.targetId == chat.targetId,
      );
      if (idx >= 0) {
        _checked.removeAt(idx);
      } else {
        _checked.add(_SelectableChat(chat: chat, checked: true));
      }
    });
  }

  void _clean() => setState(() => _checked.clear());

  void _confirm() {
    Navigator.pop(
      context,
      _checked.map((e) => e.chat).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final visible = _visibleChats();

    return Container(
      height: maxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(rpx(context, 30)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: rpx(context, 90),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: rpx(context, 30)),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: rpx(context, 30),
                      color: ImColors.text,
                    ),
                  ),
                  const Spacer(),
                  if (widget.multiSelect) ...[
                    _TopButton(
                      label: '清空',
                      color: ImColors.danger,
                      onTap: _clean,
                    ),
                    SizedBox(width: rpx(context, 10)),
                    _TopButton(
                      label: '确定(${_checked.length})',
                      color: ImColors.accent,
                      onTap: _confirm,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (widget.multiSelect && _checked.isNotEmpty)
            SizedBox(
              height: rpx(context, 90),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
                itemCount: _checked.length,
                separatorBuilder: (_, __) => SizedBox(width: rpx(context, 6)),
                itemBuilder: (_, i) => HeadImage(
                  url: _checked[i].chat.headImage,
                  name: _checked[i].chat.showName,
                  size: 60,
                ),
              ),
            ),
          ImSearchBar(
            controller: _searchCtrl,
            placeholder: '搜索',
            autofocus: false,
            onChanged: (v) => setState(() => _searchText = v),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Text(
                      '暂无会话',
                      style: TextStyle(
                        fontSize: rpx(context, 28),
                        color: ImColors.textLight,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: ImColors.formDivider,
                    ),
                    itemBuilder: (_, i) {
                      final chat = visible[i];
                      final checked = _isChecked(chat);
                      return InkWell(
                        onTap: () => _toggle(chat),
                        child: SizedBox(
                          height: rpx(context, 120),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: rpx(context, 20),
                            ),
                            child: Row(
                              children: [
                                HeadImage(
                                  url: chat.headImage,
                                  name: chat.showName,
                                  size: 90,
                                ),
                                SizedBox(width: rpx(context, 20)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              chat.showName ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: rpx(context, 30),
                                                color: ImColors.text,
                                              ),
                                            ),
                                          ),
                                          if (StringUtil.isNotBlank(
                                            chat.companyName,
                                          ))
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: rpx(context, 8),
                                              ),
                                              child: Text(
                                                '@${chat.companyName}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: rpx(context, 22),
                                                  color: ImColors.textLight,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: rpx(context, 8)),
                                      Text(
                                        chat.lastContent ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: rpx(context, 24),
                                          color: ImColors.textLighter,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: rpx(context, 12),
                                  ),
                                  child: ImRadioOption(
                                    label: '',
                                    value: 1,
                                    groupValue: checked ? 1 : 0,
                                    onChanged: (_) => _toggle(chat),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: rpx(context, 16),
          vertical: rpx(context, 8),
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(rpx(context, 8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: rpx(context, 24),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
