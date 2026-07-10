/// Riverpod stores 聚合导出（契约入口，仅主 agent 维护）。
///
/// 对应原 Pinia 六个 store：user / chat / friend / group / config / line。
/// line（lineProvider）定义在 core/di/app_providers.dart，此处统一再导出。
library;

export '../core/di/app_providers.dart' show lineProvider, LineNotifier;
export 'chat_store.dart';
export 'config_store.dart';
export 'friend_store.dart';
export 'group_store.dart';
export 'user_store.dart';
