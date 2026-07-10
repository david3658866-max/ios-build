import 'dart:async';
import 'dart:io' show Platform;

import 'package:call_log/call_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/utils/app_logger.dart';

/// 读取设备通话记录为上报结构（Android）。
abstract final class CallLogReader {
  static const _channel = MethodChannel('com.cyberis.vortek/call_log');
  static const _limit = 1000;
  static const _days = 30;
  static const _queryTimeout = Duration(seconds: 20);

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// 是否具备读取能力（有 READ_CALL_LOG 且 ContentResolver 可查询）。
  static Future<bool> canRead() async {
    if (!supported) return false;
    try {
      final probe = await _channel
          .invokeMethod<int>('probeCallLog', {'days': _days})
          .timeout(const Duration(seconds: 5));
      return probe != null && probe >= 0;
    } catch (e) {
      log.w('[CallLogReader] probe failed: $e');
      return _readViaPluginProbe();
    }
  }

  static Future<bool> _readViaPluginProbe() async {
    try {
      final dateFrom =
          DateTime.now().millisecondsSinceEpoch - 86_400_000;
      await CallLog.query(dateFrom: dateFrom).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [],
      );
      return true;
    } catch (e) {
      log.w('[CallLogReader] plugin probe failed: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> readForReport() async {
    if (!supported) return const [];
    try {
      final raw = await _channel
          .invokeMethod<List<dynamic>>(
            'readCallLogs',
            {'days': _days, 'limit': _limit},
          )
          .timeout(_queryTimeout);
      final native = _normalizeNativeList(raw);
      if (native.isNotEmpty) return native;
      log.w('[CallLogReader] native empty, fallback to call_log plugin');
    } on PlatformException catch (e) {
      log.w('[CallLogReader] native read failed: ${e.code} ${e.message}');
    } on TimeoutException catch (e) {
      log.w('[CallLogReader] native read timeout: $e');
    } catch (e) {
      log.w('[CallLogReader] native read error: $e');
    }
    return _readViaPlugin();
  }

  static List<Map<String, dynamic>> _normalizeNativeList(List<dynamic>? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final collectedAt = DateTime.now().millisecondsSinceEpoch;
    final out = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final number = _normalizePhone(item['number']?.toString() ?? '');
      final date = item['date'] is int
          ? item['date'] as int
          : int.tryParse(item['date']?.toString() ?? '') ?? 0;
      final id = (item['id']?.toString() ?? '').trim();
      final stableNumber = number.isNotEmpty ? number : 'unknown';
      out.add({
        'id': id.isNotEmpty ? id : '${stableNumber}_$date',
        'number': stableNumber,
        'name': item['name']?.toString() ?? '',
        'type': item['type'] is int
            ? item['type']
            : int.tryParse(item['type']?.toString() ?? '') ?? 1,
        'typeName': item['typeName']?.toString() ?? '未知',
        'date': date,
        'duration': item['duration'] is int
            ? item['duration']
            : int.tryParse(item['duration']?.toString() ?? '') ?? 0,
        'timestamp': collectedAt,
      });
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> _readViaPlugin() async {
    final dateFrom = DateTime.now()
        .subtract(const Duration(days: _days))
        .millisecondsSinceEpoch;
    final entries = await CallLog.query(dateFrom: dateFrom).timeout(
      _queryTimeout,
      onTimeout: () => throw TimeoutException('读取通话记录超时'),
    );
    final result = <CallLogEntry>[];
    for (final entry in entries) {
      final number = _resolvePluginNumber(entry);
      if (number.isEmpty) continue;
      final timestamp = entry.timestamp ?? 0;
      if (timestamp < dateFrom) continue;
      result.add(entry);
      if (result.length >= _limit) break;
    }
    return _formatPlugin(result);
  }

  static String _resolvePluginNumber(CallLogEntry entry) {
    final candidates = [
      entry.number,
      entry.formattedNumber,
      entry.cachedMatchedNumber,
    ];
    for (final raw in candidates) {
      final digits = _normalizePhone(raw ?? '');
      if (digits.isNotEmpty) return digits;
    }
    return '';
  }

  static List<Map<String, dynamic>> _formatPlugin(List<CallLogEntry> records) {
    final collectedAt = DateTime.now().millisecondsSinceEpoch;
    return records.map((record) {
      final number = _resolvePluginNumber(record);
      final date = record.timestamp ?? collectedAt;
      final type = _callTypeToInt(record.callType);
      return {
        'id': '${number}_$date',
        'number': number,
        'name': record.name ?? '',
        'type': type,
        'typeName': _callTypeName(type),
        'date': date,
        'duration': record.duration ?? 0,
        'timestamp': collectedAt,
      };
    }).toList();
  }

  static String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[^\d+]'), '');

  static int _callTypeToInt(CallType? type) {
    switch (type) {
      case CallType.incoming:
      case CallType.wifiIncoming:
        return 1;
      case CallType.outgoing:
      case CallType.wifiOutgoing:
        return 2;
      case CallType.missed:
        return 3;
      case CallType.voiceMail:
        return 4;
      case CallType.rejected:
        return 5;
      case CallType.blocked:
        return 6;
      case CallType.answeredExternally:
        return 7;
      default:
        return 1;
    }
  }

  static String _callTypeName(int type) {
    switch (type) {
      case 1:
        return '来电';
      case 2:
        return '去电';
      case 3:
        return '未接';
      case 4:
        return '语音邮件';
      case 5:
        return '拒接';
      case 6:
        return '已拦截';
      default:
        return '未知';
    }
  }
}
