import '../enums/message_type.dart';

/// 消息失败重发规则。对齐 uniapp chat-box `onResendMessage`。
abstract final class MessageResendUtil {
  static const unsupportedAutoResendHint =
      '该消息不支持自动重新发送，建议手动重新发送';

  /// uniapp 旁侧/自动重发仅 TEXT。
  static bool canUniappAutoResend(int type) => type == MessageType.text;

  /// Flutter 旁侧失败图标支持的类型（图/视频/文件可通过遮罩重发）。
  static bool supportsSideResend(int type, {bool sideFailForMedia = false}) {
    if (type == MessageType.text || type == MessageType.audio) return true;
    return sideFailForMedia &&
        (type == MessageType.image ||
            type == MessageType.video ||
            type == MessageType.file);
  }
}
