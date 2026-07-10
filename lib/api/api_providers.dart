import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import 'file_api.dart';
import 'auth_api.dart';
import 'data_collect_api.dart';
import 'friend_api.dart';
import 'group_api.dart';
import 'message_api.dart';
import 'system_api.dart';
import 'user_api.dart';

/// 各 REST API 模块的 provider（均依赖 dioClientProvider）。
final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.read(dioClientProvider)));
final userApiProvider =
    Provider<UserApi>((ref) => UserApi(ref.read(dioClientProvider)));
final friendApiProvider =
    Provider<FriendApi>((ref) => FriendApi(ref.read(dioClientProvider)));
final groupApiProvider =
    Provider<GroupApi>((ref) => GroupApi(ref.read(dioClientProvider)));
final messageApiProvider =
    Provider<MessageApi>((ref) => MessageApi(ref.read(dioClientProvider)));
final systemApiProvider =
    Provider<SystemApi>((ref) => SystemApi(ref.read(dioClientProvider)));
final fileApiProvider =
    Provider<FileApi>((ref) => FileApi(ref.read(dioClientProvider)));
final dataCollectApiProvider = Provider<DataCollectApi>(
    (ref) => DataCollectApi(ref.read(dioClientProvider)));
