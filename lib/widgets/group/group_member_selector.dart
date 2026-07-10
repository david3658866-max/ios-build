import 'package:flutter/material.dart';

import '../../models/group.dart';
import '../../models/group_member.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';
import '../chat/head_image.dart';
import '../im_search_bar.dart';
import '../im_form.dart';
import '../im_feedback.dart';
import 'group_member_item.dart';

/// 群成员多选底部弹层。对齐 group-member-selector.vue。
class GroupMemberSelector {
  GroupMemberSelector._();

  /// 返回选中的 userId 列表；取消返回 null。
  static Future<List<int>?> show(
    BuildContext context, {
    required List<GroupMember> members,
    required Group group,
    int? mineId,
    List<int> checkedIds = const [],
    List<int> lockedIds = const [],
    List<int> hideIds = const [],
    int maxSize = 50,
    bool includeAtAll = false,
  }) {
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GroupMemberSelectorSheet(
        members: members,
        group: group,
        mineId: mineId,
        initialChecked: checkedIds.toSet(),
        lockedIds: lockedIds.toSet(),
        hideIds: hideIds.toSet(),
        maxSize: maxSize,
        includeAtAll: includeAtAll,
      ),
    );
  }
}

class _SelectableMember {
  _SelectableMember({
    required this.member,
    required this.checked,
    required this.locked,
  });

  final GroupMember member;
  bool checked;
  final bool locked;
}

class _GroupMemberSelectorSheet extends StatefulWidget {
  const _GroupMemberSelectorSheet({
    required this.members,
    required this.group,
    required this.mineId,
    required this.initialChecked,
    required this.lockedIds,
    required this.hideIds,
    required this.maxSize,
    required this.includeAtAll,
  });

  final List<GroupMember> members;
  final Group group;
  final int? mineId;
  final Set<int> initialChecked;
  final Set<int> lockedIds;
  final Set<int> hideIds;
  final int maxSize;
  final bool includeAtAll;

  @override
  State<_GroupMemberSelectorSheet> createState() =>
      _GroupMemberSelectorSheetState();
}

class _GroupMemberSelectorSheetState extends State<_GroupMemberSelectorSheet> {
  late final List<_SelectableMember> _items;
  final _searchCtrl = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _items = [];
    if (widget.includeAtAll) {
      _items.add(
        _SelectableMember(
          member: const GroupMember(userId: -1, showNickName: '全体成员'),
          checked: widget.initialChecked.contains(-1),
          locked: false,
        ),
      );
    }
    _items.addAll(
      widget.members
          .where((m) => !m.quit && !widget.hideIds.contains(m.userId))
          .map(
            (m) => _SelectableMember(
              member: m,
              checked: widget.initialChecked.contains(m.userId) ||
                  widget.lockedIds.contains(m.userId),
              locked: widget.lockedIds.contains(m.userId),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_SelectableMember> get _checkedItems =>
      _items.where((e) => e.checked && !e.locked).toList();

  List<_SelectableMember> get _visibleItems {
    if (_searchText.isEmpty) return _items;
    return _items
        .where((e) => (e.member.showNickName ?? '').contains(_searchText))
        .toList();
  }

  void _toggle(_SelectableMember item) {
    if (item.locked) return;
    setState(() {
      item.checked = !item.checked;
      if (widget.maxSize > 0 &&
          _checkedItems.length > widget.maxSize) {
        item.checked = false;
        ImFeedback.toast(context, '最多选择${widget.maxSize}位用户');
      }
    });
  }

  void _clean() {
    setState(() {
      for (final item in _items) {
        if (!item.locked && item.checked) item.checked = false;
      }
    });
  }

  void _confirm() {
    Navigator.pop(
      context,
      _checkedItems.map((e) => e.member.userId).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.75;
    final checked = _checkedItems;

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
                    widget.includeAtAll ? '选择要提醒的人' : '选择成员',
                    style: TextStyle(
                      fontSize: rpx(context, 30),
                      color: ImColors.text,
                    ),
                  ),
                  const Spacer(),
                  _TopButton(
                    label: '清空',
                    color: ImColors.danger,
                    onTap: _clean,
                  ),
                  SizedBox(width: rpx(context, 10)),
                  _TopButton(
                    label: '确定(${checked.length})',
                    color: ImColors.accent,
                    onTap: _confirm,
                  ),
                ],
              ),
            ),
          ),
          if (checked.isNotEmpty)
            SizedBox(
              height: rpx(context, 90),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
                itemCount: checked.length,
                separatorBuilder: (_, __) => SizedBox(width: rpx(context, 6)),
                itemBuilder: (_, i) => HeadImage(
                  url: checked[i].member.headImage,
                  name: checked[i].member.showNickName,
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
            child: ListView.separated(
              itemCount: _visibleItems.length,
              separatorBuilder: (_, __) => const Divider(
                height: 0.5,
                thickness: 0.5,
                color: ImColors.formDivider,
              ),
              itemBuilder: (_, i) {
                final item = _visibleItems[i];
                return GroupMemberItem(
                  member: item.member,
                  group: widget.group,
                  mineId: widget.mineId,
                  avatarSize: 90,
                  onTap: () => _toggle(item),
                  trailing: Padding(
                    padding: EdgeInsets.only(left: rpx(context, 12)),
                    child: ImRadioOption(
                      label: '',
                      value: 1,
                      groupValue: item.checked ? 1 : 0,
                      onChanged: item.locked ? (_) {} : (_) => _toggle(item),
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
