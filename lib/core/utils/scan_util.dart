import 'dart:convert';

/// 扫码结果解析。对齐 chat.vue onScanOk。
enum ScanActionType {
  loginQr,
  userProfile,
  groupInfo,
  externalLink,
  plainText,
}

class ScanAction {
  const ScanAction({
    required this.type,
    this.qrCode,
    this.userId,
    this.groupId,
    this.url,
    this.text,
  });

  final ScanActionType type;
  final String? qrCode;
  final int? userId;
  final int? groupId;
  final String? url;
  final String? text;
}

abstract final class ScanUtil {
  ScanUtil._();

  static ScanAction parse(String raw) {
    final val = raw.trim();
    if (val.isEmpty) {
      return ScanAction(type: ScanActionType.plainText, text: val);
    }

    try {
      final json = jsonDecode(val);
      if (json is Map<String, dynamic>) {
        if (json['type'] == 'login' && json['qrCode'] != null) {
          return ScanAction(
            type: ScanActionType.loginQr,
            qrCode: json['qrCode'].toString(),
          );
        }
      }
    } catch (_) {}

    final uri = Uri.tryParse(val);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      final params = uri.queryParameters;
      if (params['scan'] == '1' && params['userId'] != null) {
        return ScanAction(
          type: ScanActionType.userProfile,
          userId: int.tryParse(params['userId']!),
        );
      }
      if (params['scan'] == '1' && params['groupId'] != null) {
        return ScanAction(
          type: ScanActionType.groupInfo,
          groupId: int.tryParse(params['groupId']!),
        );
      }
      return ScanAction(type: ScanActionType.externalLink, url: val);
    }

    return ScanAction(type: ScanActionType.plainText, text: val);
  }
}
