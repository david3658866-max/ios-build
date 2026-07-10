/// WebSocket 顶层命令字。
///
/// 帧格式：`{ cmd: int, data: object }`（收发同构，对应后端 IMSendInfo/IMRecvInfo）。
/// 取值与后端 `IMCmdType` 及 im-uniapp 保持一致。
abstract final class CmdType {
  /// 登录 / 登录成功。连上后发 `{cmd:0, data:{accessToken, devId}}`，
  /// 收到后启动心跳、触发 onConnect、拉离线会话摘要。
  static const int login = 0;

  /// 心跳。每 20s 发 `{cmd:1, data:{}}`，收到后重置心跳定时器。
  /// 服务端用 READER_IDLE 空闲检测，必须按时发送，否则被主动断开。
  static const int heartbeat = 1;

  /// 强制下线（异地登录被踢）。收到后退出登录。
  static const int forceLogout = 2;

  /// 私聊消息。data = PrivateMessageVO。
  static const int privateMessage = 3;

  /// 群聊消息。data = GroupMessageVO。
  static const int groupMessage = 4;

  /// 系统消息。data = SystemMessageVO。
  static const int systemMessage = 5;
}
