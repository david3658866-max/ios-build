import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// 新消息提示音。对齐 im-uniapp App.vue playAudioTip()。
class TipSoundService {
  final AudioPlayer _player = AudioPlayer();
  int _lastPlayMs = 0;
  bool _loaded = false;

  /// 播放间隔须大于 1s（与 uniapp 一致）。
  Future<void> play() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPlayMs <= 1000) return;
    _lastPlayMs = now;
    try {
      if (!_loaded) {
        await _player.setAsset('assets/audio/tip-crisp.wav');
        _loaded = true;
      }
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {}
  }

  void dispose() {
    _player.dispose();
  }
}

final tipSoundServiceProvider = Provider<TipSoundService>((ref) {
  final service = TipSoundService();
  ref.onDispose(service.dispose);
  return service;
});
