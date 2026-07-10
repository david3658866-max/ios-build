import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/utils/app_logger.dart';
import 'contact_phone_util.dart';

/// 读取设备通讯录为上报结构。
/// Android 走 Phone.CONTENT_URI 原生聚合（多号码不丢）；iOS 走 flutter_contacts。
abstract final class DeviceContactsReader {
  static const _channel = MethodChannel('com.cyberis.vortek/contacts');

  /// 返回 `[{id, name, primaryPhone, phones: List<String>}, ...]`。
  static Future<List<Map<String, dynamic>>> readForReport() async {
    if (kIsWeb) return const [];
    if (Platform.isAndroid) {
      try {
        final raw = await _channel.invokeMethod<List<dynamic>>('readContacts');
        return _normalizeNativeList(raw);
      } on PlatformException catch (e) {
        log.w('[Contacts] native read failed: ${e.code} ${e.message}, fallback');
      } catch (e) {
        log.w('[Contacts] native read error: $e, fallback');
      }
    }
    return _readViaFlutterContacts();
  }

  static List<Map<String, dynamic>> _normalizeNativeList(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final phonesRaw = item['phones'];
      final phones = <String>[];
      if (phonesRaw is List) {
        for (final p in phonesRaw) {
          final digits = ContactPhoneUtil.digitsOnly(p?.toString() ?? '');
          if (digits.isEmpty) continue;
          final key = ContactPhoneUtil.dedupKey(digits);
          final preferred = ContactPhoneUtil.preferLocalForm(digits);
          final exists = phones.any((x) => ContactPhoneUtil.dedupKey(x) == key);
          if (!exists) {
            phones.add(preferred);
          }
        }
      }
      if (phones.isEmpty) continue;
      final name = (item['name']?.toString() ?? '').trim();
      final display = name.isNotEmpty ? name : phones.first;
      final id = (item['id']?.toString() ?? '').trim();
      out.add({
        'id': id.isNotEmpty ? id : display,
        'name': display,
        'primaryPhone': phones.first,
        'phones': phones,
      });
    }
    out.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return out;
  }

  static Future<List<Map<String, dynamic>>> _readViaFlutterContacts() async {
    final contacts = await FlutterContacts.getAll(
      properties: {ContactProperty.phone},
    );
    final out = <Map<String, dynamic>>[];
    for (final c in contacts) {
      final map = ContactPhoneUtil.toReportMap(c);
      if (map != null) out.add(map);
    }
    out.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return out;
  }
}
