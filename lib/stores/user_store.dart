import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../core/di/app_providers.dart';
import '../models/user.dart';

class UserStore extends Notifier<User?> {
  @override
  User? build() {
    final cached = ref.read(kvStoreProvider).getUserInfo();
    if (cached == null) return null;
    try {
      return User.fromJson(cached);
    } catch (_) {
      return null;
    }
  }

  /// 鎷夊彇褰撳墠鐢ㄦ埛淇℃伅骞剁紦瀛橈拷?
  Future<User> loadSelf() async {
    final user = await ref.read(userApiProvider).self();
    setUser(user);
    return user;
  }

  Future<void> updateProfile(User user) async {
    await ref.read(userApiProvider).update(user);
    await loadSelf();
  }

  void setUser(User? user) {
    state = user;
    final kv = ref.read(kvStoreProvider);
    if (user == null) {
      kv.clearUserInfo();
    } else {
      kv.setUserInfo(user.toJson());
    }
  }

  void clear() {
    
    setUser(null);
  }

  int? get currentUserId => state?.id;
}

final userStoreProvider =
    NotifierProvider<UserStore, User?>(UserStore.new);

