import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage/app_database.dart' hide FriendRequest;
import '../models/friend_request.dart';
import '../stores/chat_store.dart';
import '../stores/friend_store.dart';
import '../stores/user_store.dart';

class BadgeCountsNotifier extends Notifier<List<int>> {
  @override
  List<int> build() => const [0, 0];

  void setChatTabCount(int count) {
    if (state[0] == count) return;
    state = [count, state[1]];
  }

  void setFriendTabCount(int count) {
    if (state[1] == count) return;
    state = [state[0], count];
  }
}

int computeChatTabBadge(Iterable<Chat> chats) {
  var count = 0;
  for (final chat in chats) {
    if (!chat.isDnd) {
      count += chat.unreadCount;
    }
  }
  return count;
}

int computeFriendTabBadge(List<FriendRequest> requests, int? userId) {
  if (userId == null) return 0;
  return requests.where((r) => r.recvId == userId).length;
}

final badgeCountsProvider =
    NotifierProvider<BadgeCountsNotifier, List<int>>(BadgeCountsNotifier.new);

void refreshChatBadge(WidgetRef ref) {
  final count = ref.read(chatBadgeUnreadCountProvider).value ?? 0;
  ref.read(badgeCountsProvider.notifier).setChatTabCount(count);
  setDesktopBadge(count);
}

void refreshChatBadgeFromRef(Ref ref) {
  final count = ref.read(chatBadgeUnreadCountProvider).value ?? 0;
  ref.read(badgeCountsProvider.notifier).setChatTabCount(count);
  setDesktopBadge(count);
}

void refreshFriendBadge(WidgetRef ref) {
  final userId = ref.read(userStoreProvider)?.id;
  final requests = ref.read(friendStoreProvider).requests;
  final count = computeFriendTabBadge(requests, userId);
  ref.read(badgeCountsProvider.notifier).setFriendTabCount(count);
}

void refreshFriendBadgeFromRef(Ref ref) {
  final userId = ref.read(userStoreProvider)?.id;
  final requests = ref.read(friendStoreProvider).requests;
  final count = computeFriendTabBadge(requests, userId);
  ref.read(badgeCountsProvider.notifier).setFriendTabCount(count);
}

void refreshAllBadges(WidgetRef ref) {
  refreshChatBadge(ref);
  refreshFriendBadge(ref);
}

void refreshAllBadgesFromRef(Ref ref) {
  refreshChatBadgeFromRef(ref);
  refreshFriendBadgeFromRef(ref);
}

void bindBadgeAutoRefresh(WidgetRef ref) {
  ref.listen(chatBadgeUnreadCountProvider, (_, _) => refreshChatBadge(ref));
  ref.listen(friendStoreProvider, (_, _) => refreshFriendBadge(ref));
}

Future<void> setDesktopBadge(int count) async {
  try {
    if (count > 0) {
      if (await AppBadgePlus.isSupported()) {
        await AppBadgePlus.updateBadge(count);
      }
    } else {
      await AppBadgePlus.updateBadge(0);
    }
  } catch (e) {
    // Desktop badge 在部分平台不支持，忽略即可。
  }
}

