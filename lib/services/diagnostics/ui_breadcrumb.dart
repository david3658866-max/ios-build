import 'dart:async';
import 'dart:convert';

import '../../core/config/app_constants.dart';
import '../../core/storage/kv_store.dart';
import '../../core/utils/app_logger.dart';

/// 关键 UI 操作面包屑（环形缓冲，落盘以便闪退后下次启动仍可读）。
abstract final class UiBreadcrumb {
  static const int maxItems = 30;
  static KvStore? _kv;
  static final List<Map<String, dynamic>> _mem = <Map<String, dynamic>>[];

  static void bind(KvStore kv) {
    _kv = kv;
    _load();
  }

  static void add(String action, {String? detail}) {
    final a = action.trim();
    if (a.isEmpty) return;
    final item = <String, dynamic>{
      't': DateTime.now().millisecondsSinceEpoch,
      'a': a.length > 48 ? a.substring(0, 48) : a,
      if (detail != null && detail.trim().isNotEmpty)
        'd': detail.trim().length > 80
            ? detail.trim().substring(0, 80)
            : detail.trim(),
    };
    _mem.add(item);
    while (_mem.length > maxItems) {
      _mem.removeAt(0);
    }
    _persist();
  }

  static List<Map<String, dynamic>> snapshot() =>
      List<Map<String, dynamic>>.from(_mem);

  static void clear() {
    _mem.clear();
    final kv = _kv;
    if (kv == null) return;
    unawaited(() async {
      try {
        await kv.set(StorageKeys.uiBreadcrumbRing, '[]');
        await kv.flush();
      } catch (e) {
        log.w('[UiBreadcrumb] clear failed: $e');
      }
    }());
  }

  static void _load() {
    _mem.clear();
    final kv = _kv;
    if (kv == null) return;
    final raw = kv.get<String>(StorageKeys.uiBreadcrumbRing);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return;
      for (final e in list) {
        if (e is Map) {
          _mem.add(e.cast<String, dynamic>());
        }
      }
      while (_mem.length > maxItems) {
        _mem.removeAt(0);
      }
    } catch (_) {}
  }

  static void _persist() {
    final kv = _kv;
    if (kv == null) return;
    unawaited(() async {
      try {
        await kv.set(StorageKeys.uiBreadcrumbRing, jsonEncode(_mem));
        await kv.flush();
      } catch (e) {
        log.w('[UiBreadcrumb] persist failed: $e');
      }
    }());
  }
}