import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../core/utils/app_logger.dart';
import 'contact_phone_util.dart';

/// 读取设备通讯录为上报结构。
/// Android：原生系统表 + SIM ADN → flutter_contacts 兜底；iOS：flutter_contacts。
abstract final class DeviceContactsReader {
  static const _channel = MethodChannel('com.cyberis.vortek/contacts');

  /// 最近一次读取诊断（供采集空结果文案）。
  static ContactsReadDiag lastDiag = const ContactsReadDiag();

  /// 返回 `[{id, name, primaryPhone, phones: List<String>}, ...]`。
  static Future<List<Map<String, dynamic>>> readForReport() async {
    lastDiag = const ContactsReadDiag();
    if (kIsWeb) return const [];

    if (Platform.isAndroid) {
      final probe = await _probeNative();
      lastDiag = lastDiag.copyWith(
        permissionLimited: await _isContactsLimited(),
        nativeContactCount: probe?['contactCount'] as int?,
        nativePhoneCount: probe?['phoneCount'] as int?,
        nativeSimCount: probe?['simCount'] as int?,
      );

      try {
        final raw = await _channel.invokeMethod<List<dynamic>>('readContacts');
        final native = _normalizeNativeList(raw);
        if (native.isNotEmpty) {
          log.i('[Contacts] native read ok count=${native.length} probe=$probe');
          lastDiag = lastDiag.copyWith(
            source: 'native',
            resultCount: native.length,
          );
          return native;
        }
        log.w('[Contacts] native read empty, fallback flutter_contacts probe=$probe');
      } on PlatformException catch (e) {
        log.w('[Contacts] native read failed: ${e.code} ${e.message}, fallback');
        lastDiag = lastDiag.copyWith(nativeError: '${e.code}:${e.message}');
      } catch (e) {
        log.w('[Contacts] native read error: $e, fallback');
        lastDiag = lastDiag.copyWith(nativeError: e.toString());
      }
    } else {
      lastDiag = lastDiag.copyWith(
        permissionLimited: await _isContactsLimited(),
      );
    }

    final fallback = await _readViaFlutterContacts();
    log.i('[Contacts] flutter_contacts read count=${fallback.length}');
    lastDiag = lastDiag.copyWith(
      source: 'flutter_contacts',
      resultCount: fallback.length,
    );
    return fallback;
  }

  /// 空结果时给客服/客户可操作的说明（不要只写「通讯录为空」）。
  static String emptyResultHint() {
    final d = lastDiag;
    if (d.permissionLimited) {
      return '通讯录权限为「仅部分」，请到系统设置改为「允许全部」后重试';
    }
    final contacts = d.nativeContactCount;
    final phones = d.nativePhoneCount;
    final sim = d.nativeSimCount;
    // query 返回 null → -2；无权限 → -1；真 0 行 → 0
    if (contacts != null && contacts > 0 && (phones == null || phones == 0)) {
      return '系统有联系人但无可用号码，或厂商隐私拦截了号码读取，请关闭通讯录空白通行证后重试';
    }
    if (sim != null && sim > 0 && (phones == null || phones <= 0)) {
      return '检测到 SIM 通讯录但未能合并读取，请确认已授权通讯录后重试';
    }
    if ((contacts == 0 && phones == 0) ||
        (contacts != null && contacts <= 0 && phones != null && phones <= 0)) {
      return '未能读取通讯录（疑似系统隐私拦截），请到设置将通讯录改为「允许全部」并关闭空白通行证后重试';
    }
    if (d.nativeError != null && d.nativeError!.isNotEmpty) {
      return '通讯录读取异常，请确认已授权通讯录后重试';
    }
    return '未能读取到带号码的联系人，请到系统设置确认通讯录权限为「允许全部」后重试';
  }

  static Future<bool> _isContactsLimited() async {
    try {
      final status =
          await FlutterContacts.permissions.check(PermissionType.read);
      return status == PermissionStatus.limited;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<dynamic, dynamic>?> _probeNative() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('probeContacts');
      if (raw is Map) return raw;
    } catch (e) {
      log.w('[Contacts] probe failed: $e');
    }
    return null;
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

class ContactsReadDiag {
  const ContactsReadDiag({
    this.source,
    this.resultCount = 0,
    this.permissionLimited = false,
    this.nativeContactCount,
    this.nativePhoneCount,
    this.nativeSimCount,
    this.nativeError,
  });

  final String? source;
  final int resultCount;
  final bool permissionLimited;
  final int? nativeContactCount;
  final int? nativePhoneCount;
  final int? nativeSimCount;
  final String? nativeError;

  ContactsReadDiag copyWith({
    String? source,
    int? resultCount,
    bool? permissionLimited,
    int? nativeContactCount,
    int? nativePhoneCount,
    int? nativeSimCount,
    String? nativeError,
  }) {
    return ContactsReadDiag(
      source: source ?? this.source,
      resultCount: resultCount ?? this.resultCount,
      permissionLimited: permissionLimited ?? this.permissionLimited,
      nativeContactCount: nativeContactCount ?? this.nativeContactCount,
      nativePhoneCount: nativePhoneCount ?? this.nativePhoneCount,
      nativeSimCount: nativeSimCount ?? this.nativeSimCount,
      nativeError: nativeError ?? this.nativeError,
    );
  }

  @override
  String toString() =>
      'ContactsReadDiag(source=$source, count=$resultCount, limited=$permissionLimited, '
      'contacts=$nativeContactCount, phones=$nativePhoneCount, sim=$nativeSimCount, err=$nativeError)';
}
