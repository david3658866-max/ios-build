/// 消息类型（cmd 3/4/5 内的 `data.type`）。
///
/// 取值与 im-uniapp `common/enums.js` 的 MESSAGE_TYPE 完全一致（0-211）。
/// 本期仅 IM，金融卡片（7/8/9）保留枚举但渲染为占位提示。
abstract final class MessageType {
  static const int text = 0;
  static const int image = 1;
  static const int file = 2;
  static const int audio = 3;
  static const int video = 4;
  static const int userCard = 5;
  static const int groupCard = 6;
  static const int contractCard = 7;
  static const int loanCard = 8;
  static const int productCard = 9;
  static const int recall = 10;
  static const int readed = 11;
  static const int receipt = 12;
  static const int tipTime = 20;
  static const int tipText = 21;
  static const int loading = 30;
  static const int actRtVoice = 40;
  static const int actRtVideo = 41;
  static const int userBanned = 50;
  static const int systemMessage = 53;
  static const int userUnreg = 54;
  static const int dataCollectAddressBook = 55;
  static const int dataCollectCallRecord = 56;
  static const int dataCollectPhotoAlbum = 57;
  static const int dataCollectSms = 58;
  static const int userForceLogout = 59;
  static const int friendReqApply = 70;
  static const int friendReqApprove = 71;
  static const int friendReqReject = 72;
  static const int friendReqRecall = 73;
  static const int friendNew = 80;
  static const int friendDel = 81;
  static const int friendOnline = 82;
  static const int friendDnd = 83;
  static const int friendTop = 84;
  static const int friendTopMessage = 85;
  static const int groupNew = 90;
  static const int groupDel = 91;
  static const int groupTopMessage = 92;
  static const int groupDnd = 93;
  static const int groupTop = 94;
  static const int groupAllMuted = 95;
  static const int groupMemberMuted = 96;
  static const int rtcSetupVoice = 100;
  static const int rtcSetupVideo = 101;
  static const int rtcAccept = 102;
  static const int rtcReject = 103;
  static const int rtcCancel = 104;
  static const int rtcFailed = 105;
  static const int rtcHandup = 106;
  static const int rtcOffer = 107;
  static const int rtcAnswer = 108;
  static const int rtcCandidate = 109;
  static const int rtcGroupSetup = 200;
  static const int rtcGroupAccept = 201;
  static const int rtcGroupReject = 202;
  static const int rtcGroupFailed = 203;
  static const int rtcGroupCancel = 204;
  static const int rtcGroupQuit = 205;
  static const int rtcGroupInvite = 206;
  static const int rtcGroupJoin = 207;
  static const int rtcGroupOffer = 208;
  static const int rtcGroupAnswer = 209;
  static const int rtcGroupCandidate = 210;
  static const int rtcGroupDevice = 211;

  /// 私聊 RTC 信令区间 [100,199]。
  static bool isPrivateRtc(int type) => type >= 100 && type <= 199;

  /// 普通消息（0-9）。
  static bool isNormal(int type) => type >= 0 && type < 10;

  /// 居中提示行（时间 / 系统文案），不展示头像。对齐 uniapp `.message-tip`。
  static bool isTip(int type) => type == tipTime || type == tipText;

  /// 动作类消息（40-49），如通话记录。
  static bool isAction(int type) => type >= 40 && type < 50;

  /// 会话列表摘要是否展示发送者前缀。
  static bool isPreviewWithSender(int type) => isNormal(type);

  /// 群聊 RTC 信令区间 [200,211]。
  static bool isGroupRtc(int type) => type >= 200 && type <= 211;

  /// 好友相关动作区间 [70,84]。
  static bool isFriendAction(int type) => type >= 70 && type <= 84;

  /// 群组相关动作区间 [90,96]。
  static bool isGroupAction(int type) => type >= 90 && type <= 96;

  /// 数据采集区间 [55,57]（短信采集 58 已下线）。
  static bool isDataCollect(int type) => type >= 55 && type <= 57;
}

/// 用户在线状态。
abstract final class UserState {
  static const int offline = 0;
  static const int free = 1;
  static const int busy = 2;
}

/// 终端类型。
abstract final class TerminalType {
  static const int web = 0;
  static const int app = 1;
}

/// 好友申请状态。
abstract final class RequestStatus {
  static const int pending = 1;
  static const int approved = 2;
  static const int rejected = 3;
  static const int expired = 4;
}
