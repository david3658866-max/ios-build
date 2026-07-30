import 'package:flutter_test/flutter_test.dart';
import 'package:vortek/core/utils/rtc_call_util.dart';
import 'package:vortek/models/friend.dart';
import 'package:vortek/models/user.dart';
import 'package:vortek/stores/config_store.dart';

void main() {
  test('enableRtcCallFromConfig iOS always off', () {
    expect(
      enableRtcCallFromConfig({
        'webrtc': {'enable': true},
      }),
      isFalse,
    );
    expect(
      enableRtcCallFromConfig({
        'enableRtcCall': true,
      }),
      isFalse,
    );
    expect(enableRtcCallFromConfig(null), isFalse);
  });

  test('RtcCallUtil.webrtcMaxChannel 对齐 maxChannel', () {
    expect(
      RtcCallUtil.webrtcMaxChannel({
        'webrtc': {'maxChannel': 6},
      }),
      6,
    );
    expect(RtcCallUtil.webrtcMaxChannel(null), 9);
  });

  test('RtcCallUtil.friendForCall 合并用户头像昵称', () {
    const base = Friend(
      id: 1,
      nickName: 'old',
      showNickName: '备注名',
      remarkNickName: '备注名',
      headImage: 'old.jpg',
    );
    const user = User(
      id: 1,
      nickName: 'new',
      headImage: 'big.jpg',
      headImageThumb: 'thumb.jpg',
    );
    final merged = RtcCallUtil.friendForCall(base: base, user: user);
    expect(merged.showNickName, '备注名');
    expect(merged.headImage, 'thumb.jpg');
  });
}
