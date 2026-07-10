/// 会话类型。与 im-uniapp chatInfo.type / 后端 ChatSessionSummaryVO 一致。
abstract final class ChatType {
  static const String private = 'PRIVATE';
  static const String group = 'GROUP';
  static const String system = 'SYSTEM';
}
