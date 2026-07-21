import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/pages/group/group_invite_page.dart';
import 'package:vortek/router/app_router.dart';
import 'package:vortek/stores/friend_store.dart';
import 'package:vortek/models/group.dart';
import 'package:vortek/models/group_member.dart';
import 'package:vortek/stores/group_store.dart';

void main() {
  test('group invite path is distinct from member/info routes', () {
    const id = 42;
    expect(AppRoutes.groupInvitePath(id), '/group/invite/$id');
    expect(AppRoutes.groupMemberPath(id), '/group/member/$id');
    expect(AppRoutes.groupInfoPath(id), '/group/info/$id');
    expect(AppRoutes.groupInvitePath(id), isNot(AppRoutes.groupMemberPath(id)));
  });

  testWidgets('GroupInvitePage first frame does not crash before load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendStoreProvider.overrideWith(_EmptyFriendStore.new),
          groupStoreProvider.overrideWith(_EmptyGroupStore.new),
        ],
        child: const MaterialApp(
          home: GroupInvitePage(groupId: 1),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('邀请'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('GroupInvitePage loads friends when store is empty', (
    tester,
  ) async {
    final friendStore = _EmptyFriendStore();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendStoreProvider.overrideWith(() => friendStore),
          groupStoreProvider.overrideWith(_EmptyGroupStore.new),
        ],
        child: const MaterialApp(
          home: GroupInvitePage(groupId: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(friendStore.loadFriendsCalled, isTrue);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyFriendStore extends FriendStore {
  bool loadFriendsCalled = false;

  @override
  FriendState build() => const FriendState();

  @override
  Future<void> loadFriends() async {
    loadFriendsCalled = true;
  }
}

class _EmptyGroupStore extends GroupStore {
  @override
  List<Group> build() => const [];

  @override
  Future<List<GroupMember>> loadMembers(int groupId, {int version = 0}) async =>
      const [];
}
