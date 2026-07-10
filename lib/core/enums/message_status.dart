/// 消息状态。取值与 im-uniapp `common/enums.js` 的 MESSAGE_STATUS 一致。
abstract final class MessageStatus {
  /// 发送失败。
  static const int failed = -2;

  /// 发送中（消息未到服务器）。
  static const int sending = -1;

  /// 未送达（已到服务器，对方未收到）。
  static const int pending = 0;

  /// 已送达（对方已收到，未读）。
  static const int delivered = 1;

  /// 已撤回。
  static const int recall = 2;

  /// 已读。
  static const int readed = 3;
}
