import '../../models/friend.dart';
import '../../models/user.dart';
import '../../stores/config_store.dart';

/// 音视频通话辅助。对齐 uniapp chat-box onPrivite* / onGroupVideo。
abstract final class RtcCallUtil {
  /// 群通话选人上限。对齐 configStore.webrtc.maxChannel。
  static int webrtcMaxChannel(Map<String, dynamic>? systemConfig,
      {int fallback = 9}) {
    final webrtc = systemConfig?['webrtc'];
    if (webrtc is Map) {
      final v = webrtc['maxChannel'];
      if (v is num && v > 0) return v.toInt();
    }
    return fallback;
  }

  /// 合并好友资料与 /user/find 结果。对齐 updateFriendInfo。
  static Friend friendForCall({
    required Friend base,
    User? user,
  }) {
    if (user == null) return base;
    final remark = base.remarkNickName;
    final showNick = (remark != null && remark.isNotEmpty)
        ? remark
        : (user.nickName ?? base.showNickName ?? base.nickName);
    return Friend(
      id: base.id,
      nickName: user.nickName ?? base.nickName,
      showNickName: showNick,
      remarkNickName: base.remarkNickName,
      headImage: user.headImageThumb ?? user.headImage ?? base.headImage,
      companyName: base.companyName,
      isDnd: base.isDnd,
      isTop: base.isTop,
      deleted: base.deleted,
      online: base.online,
      onlineWeb: base.onlineWeb,
      onlineApp: base.onlineApp,
    );
  }

  /// 是否允许展示/发起 RTC。
  static bool isRtcEnabled(Map<String, dynamic>? systemConfig) =>
      enableRtcCallFromConfig(systemConfig);
}
