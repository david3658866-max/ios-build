/// WebSocket 连接状态。
enum WsStatus {
  /// 未连接。
  disconnected,

  /// TCP/WS 握手中。
  connecting,

  /// 已建立连接、已发送登录包(cmd0)、等待服务端登录成功响应。
  authing,

  /// 登录成功(收到 cmd0)，心跳运行中。
  connected,
}

/// 服务端下行业务消息事件（cmd >= 2，登录/心跳在管理器内部消化）。
///
/// 对应 wssocket.js 的 `messageCallBack(cmd, data)`。
class WsEvent {
  const WsEvent(this.cmd, this.data);

  /// 顶层命令字，见 CmdType。
  final int cmd;

  /// 业务负载（PrivateMessageVO / GroupMessageVO / SystemMessageVO）。
  final dynamic data;

  @override
  String toString() => 'WsEvent(cmd: $cmd, data: $data)';
}
