import '../../models/friend.dart';
import 'pinyin_util.dart';

/// 通讯录好友分组（拼音 / 在线）。对齐 friend.vue friendGroupMap。
typedef FriendGroup = ({
  String anchor,
  String indexKey,
  List<Friend> friends,
});

bool hasVisibleFriends(List<Friend> friends) =>
    friends.any((f) => !f.deleted);

List<FriendGroup> groupFriendsByPinyin(
  List<Friend> friends,
  String searchText,
) {
  final map = <String, List<Friend>>{};
  for (final f in friends) {
    if (f.deleted) continue;
    final name = f.showNickName ?? '';
    if (searchText.isNotEmpty && !name.contains(searchText)) continue;

    var letter = PinyinUtil.firstLetter(name);
    if (f.online) letter = '*';
    map.putIfAbsent(letter, () => []).add(f);
  }

  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a == '#' || b == '#') return b.compareTo(a);
      return a.compareTo(b);
    });

  return [
    for (final k in keys)
      (
        anchor: k == '*' ? '在线好友' : k,
        indexKey: k,
        friends: map[k]!,
      ),
  ];
}
