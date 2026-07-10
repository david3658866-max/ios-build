/// 同步游标 key。对应 im-uniapp chatStore 的 privateMsgMaxId 等。
abstract final class SyncCursorKeys {
  static const privateMsgMaxId = 'privateMsgMaxId';
  static const groupMsgMaxId = 'groupMsgMaxId';
  static const systemMsgMaxSeqNo = 'systemMsgMaxSeqNo';
}
