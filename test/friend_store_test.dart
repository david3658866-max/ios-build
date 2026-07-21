import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/enums/message_type.dart';
import 'package:vortek/models/friend_request.dart';
import 'package:vortek/stores/friend_store.dart';

void main() {
  group('FriendStore.isPendingRequest', () {
    test('仅匹配待处理且目标为 recvId 的申请', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(friendStoreProvider.notifier);
      store.addRequest(
        const FriendRequest(
          id: 1,
          sendId: 10,
          recvId: 20,
          status: RequestStatus.pending,
        ),
      );
      store.addRequest(
        const FriendRequest(
          id: 2,
          sendId: 10,
          recvId: 30,
          status: RequestStatus.rejected,
        ),
      );

      expect(store.isPendingRequest(20), isTrue);
      expect(store.isPendingRequest(30), isFalse);
      expect(store.isPendingRequest(10), isFalse);
    });
  });

  group('FriendStore.addRequest', () {
    test('按 id 去重', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final store = container.read(friendStoreProvider.notifier);
      const req = FriendRequest(id: 1, sendId: 1, recvId: 2);
      store.addRequest(req);
      store.addRequest(req);
      expect(container.read(friendStoreProvider).requests.length, 1);
    });
  });
}
