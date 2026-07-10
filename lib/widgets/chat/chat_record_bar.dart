import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/utils/chat_audio_record_util.dart';
import '../../core/utils/chat_media_util.dart';
import '../../core/utils/media_permission_util.dart';
import '../../theme/im_colors.dart';
import '../../theme/rpx.dart';

/// 按住说话录音条。对齐 chat-record.vue。
///
/// 交互：按下即反馈（变色/浮层/震动），松手发送，上滑取消。
/// 录音器异步启动期间若已松手，会在启动完成后按「太短」处理，避免卡在录音态。
class ChatRecordBar extends StatefulWidget {
  const ChatRecordBar({
    super.key,
    required this.onSend,
    required this.onToast,
  });

  /// `{duration, url}` 本地路径；上传在 chat_store（对齐 uniapp 先 upload 再发消息语义）。
  final ValueChanged<Map<String, dynamic>> onSend;

  /// 对齐 uniapp `uni.showToast`。
  final ValueChanged<String> onToast;

  @override
  State<ChatRecordBar> createState() => _ChatRecordBarState();
}

class _ChatRecordBarState extends State<ChatRecordBar> {
  final _recorder = AudioRecorder();
  final _barKey = GlobalKey();

  /// 手指仍按在条上。
  bool _pressing = false;

  /// 录音器已真正 start。
  bool _recording = false;

  /// start 异步进行中。
  bool _starting = false;

  bool _moveToCancel = false;
  int _duration = 0;
  DateTime? _startTime;
  Timer? _timer;
  String? _filePath;
  double _barTop = 0;
  OverlayEntry? _overlayEntry;
  Directory? _tempDir;

  /// 按下即展示「正在录音」态，不必等 recorder.start 完成。
  bool get _activeUi => _pressing || _recording || _starting;

  @override
  void initState() {
    super.initState();
    unawaited(_warmTempDir());
  }

  Future<void> _warmTempDir() async {
    _tempDir ??= await getTemporaryDirectory();
  }

  @override
  void dispose() {
    _hideRecordOverlay();
    _stopTimer();
    _recorder.dispose();
    super.dispose();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _duration = 0;
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _duration++);
      _overlayEntry?.markNeedsBuild();
      if (_duration >= ChatMediaUtil.maxAudioDurationSec) {
        unawaited(_finishRecord(forceCancel: false));
      }
    });
  }

  void _updateBarTop() {
    final box = _barKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      _barTop = box.localToGlobal(Offset.zero).dy;
    }
  }

  void _showRecordOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _updateBarTop();
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final screenH = MediaQuery.sizeOf(ctx).height;
        final bottom = screenH - _barTop + 12;
        return Positioned(
          left: 0,
          right: 0,
          bottom: bottom,
          child: _RecordOverlay(
            duration: _duration,
            cancel: _moveToCancel,
            onCancelTap: _onCancelTap,
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _hideRecordOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onCancelTap() {
    if (!_activeUi) return;
    _moveToCancel = true;
    _pressing = false;
    unawaited(_finishRecord(forceCancel: true));
  }

  void _onPointerDown(PointerDownEvent _) {
    if (_pressing || _starting || _recording) return;
    _pressing = true;
    _moveToCancel = false;
    _duration = 0;
    _startTime = DateTime.now();
    // 立即反馈，避免「按了半天没反应、松手才像点一下发送」的体感。
    HapticFeedback.mediumImpact();
    setState(() {});
    _showRecordOverlay();
    unawaited(_startRecorder());
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_activeUi) return;
    _updateBarTop();
    final cancel = e.position.dy < _barTop - 40;
    if (cancel != _moveToCancel) {
      setState(() => _moveToCancel = cancel);
      _overlayEntry?.markNeedsBuild();
    }
  }

  void _onPointerUp(PointerEvent _) {
    if (!_pressing && !_starting && !_recording) return;
    _pressing = false;
    if (_starting) {
      // start 尚未完成：等 start 结束后按松手处理，避免卡在录音态。
      return;
    }
    if (_recording) {
      unawaited(_finishRecord(forceCancel: false));
    } else {
      // start 失败后的松手，仅复位 UI。
      _resetUi();
    }
  }

  Future<void> _startRecorder() async {
    if (_starting || _recording) return;
    _starting = true;
    try {
      if (!await MediaPermissionUtil.ensureScenario(
        context,
        MediaPermissionScenario.chatVoiceMessage,
      )) {
        if (!mounted) return;
        _pressing = false;
        _starting = false;
        _resetUi();
        return;
      }

      await _warmTempDir();
      final dir = _tempDir ?? await getTemporaryDirectory();
      final path = ChatAudioRecordUtil.newTempPath(dir.path);

      await _recorder.start(
        ChatAudioRecordUtil.recordConfig(),
        path: path,
      );
      if (!mounted) return;

      _starting = false;
      _filePath = path;

      // 启动完成前已松手：按太短处理，不发送。
      if (!_pressing) {
        await _discardRecording(path);
        _resetUi();
        widget.onToast('说话时间太短');
        return;
      }

      _startTime ??= DateTime.now();
      setState(() => _recording = true);
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      _pressing = false;
      _starting = false;
      _recording = false;
      _resetUi();
      widget.onToast('录音失败');
    }
  }

  Future<void> _discardRecording(String? path) async {
    try {
      await _recorder.stop();
    } catch (_) {}
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
    _filePath = null;
    _startTime = null;
  }

  void _resetUi() {
    _stopTimer();
    _hideRecordOverlay();
    _recording = false;
    _starting = false;
    _duration = 0;
    if (mounted) setState(() {});
  }

  Future<void> _finishRecord({required bool forceCancel}) async {
    if (!_recording && !_starting) return;

    // 仍在 start：标记取消/结束，交给 _startRecorder 收尾。
    if (_starting) {
      _pressing = false;
      if (forceCancel) _moveToCancel = true;
      return;
    }
    if (!_recording) return;

    final cancel = forceCancel || _moveToCancel;
    final startedAt = _startTime;
    _stopTimer();
    _hideRecordOverlay();
    _recording = false;
    _pressing = false;
    if (mounted) setState(() {});

    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {}
    path ??= _filePath;

    if (cancel) {
      if (path != null && path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
      _startTime = null;
      _filePath = null;
      return;
    }
    if (path == null || path.isEmpty) return;

    final durationSec = startedAt == null
        ? _duration
        : ChatAudioRecordUtil.durationSeconds(startedAt, DateTime.now());

    if (durationSec <= ChatMediaUtil.minAudioDurationSec) {
      widget.onToast('说话时间太短');
      final f = File(path);
      if (await f.exists()) await f.delete();
      _startTime = null;
      _filePath = null;
      return;
    }

    _startTime = null;
    _filePath = null;
    HapticFeedback.lightImpact();
    widget.onSend({'duration': durationSec, 'url': path});
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeUi;
    return Listener(
      key: _barKey,
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          minHeight: rpx(context, 72),
        ),
        margin: EdgeInsets.all(rpx(context, 10)),
        padding: EdgeInsets.all(rpx(context, 10)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? ImColors.accent : ImColors.pageBg,
          borderRadius: BorderRadius.circular(rpx(context, 20)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
            ),
          ],
        ),
        child: Text(
          active
              ? (_moveToCancel ? '松手取消' : '正在录音')
              : '按住 说话',
          style: TextStyle(
            fontSize: rpx(context, 28),
            color: active ? Colors.white : ImColors.textLight,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _RecordOverlay extends StatelessWidget {
  const _RecordOverlay({
    required this.duration,
    required this.cancel,
    required this.onCancelTap,
  });

  final int duration;
  final bool cancel;
  final VoidCallback onCancelTap;

  @override
  Widget build(BuildContext context) {
    final tip = duration > 50
        ? '${ChatMediaUtil.maxAudioDurationSec - duration}s后将停止录音'
        : '录音时长:${duration}s';

    // Overlay 不在 MaterialApp 的 Material 子树内时，Text 会带默认黄色下划线。
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      child: Container(
        constraints: BoxConstraints(minHeight: rpx(context, 360)),
        padding: EdgeInsets.all(rpx(context, 30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: rpx(context, 80),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) => _WaveBar(delay: i)),
              ),
            ),
            SizedBox(height: rpx(context, 20)),
            Text(
              tip,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: rpx(context, 30),
                height: 1.2,
                color: ImColors.textLighter,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: rpx(context, 40)),
            GestureDetector(
              onTap: onCancelTap,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: rpx(context, 80),
                child: Center(
                  child: Icon(
                    Icons.cancel,
                    size: rpx(context, cancel ? 45 : 40),
                    color: cancel ? ImColors.danger : ImColors.text,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(rpx(context, 20)),
              child: Text(
                cancel ? '松手取消' : '松手发送,上划取消',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rpx(context, 30),
                  height: 1.2,
                  color: cancel ? ImColors.danger : ImColors.text,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveBar extends StatefulWidget {
  const _WaveBar({required this.delay});

  final int delay;

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    Future<void>.delayed(Duration(milliseconds: 100 * widget.delay), () {
      if (mounted) _ctrl.repeat();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barMax = rpx(context, 80) * 0.8;
    final barMin = rpx(context, 80) * 0.2;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final height = t < 0.5
            ? barMin + (barMax - barMin) * (t / 0.5)
            : barMax - (barMax - barMin) * ((t - 0.5) / 0.5);
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(rpx(context, 5)),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: t < 0.5
                  ? [ImColors.accentWaveLight, ImColors.accentWaveDark]
                  : [ImColors.accentWaveDark, ImColors.accentWaveLight],
            ),
          ),
        );
      },
    );
  }
}
