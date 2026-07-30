import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/line_switch_util.dart';
import 'im_toast.dart';

/// chip 旁展示的自动切线倒计时状态。
@immutable
class LineAutoFailoverUiState {
  const LineAutoFailoverUiState({
    this.secondsLeft,
    this.targetLineId,
    this.targetLineName,
    this.failedLineId,
  });

  final int? secondsLeft;
  final String? targetLineId;
  final String? targetLineName;
  final String? failedLineId;

  bool get active =>
      secondsLeft != null && secondsLeft! > 0 && targetLineId != null;

  static const empty = LineAutoFailoverUiState();
}

class LineAutoFailoverNotifier extends Notifier<LineAutoFailoverUiState> {
  Timer? _tick;
  int _token = 0;
  Completer<bool>? _wait;
  DateTime? _lastOfferAt;
  String? _lastFailedLineId;

  static const _debounce = Duration(seconds: 30);

  @override
  LineAutoFailoverUiState build() {
    ref.onDispose(_clearTimers);
    return LineAutoFailoverUiState.empty;
  }

  void _clearTimers() {
    _tick?.cancel();
    _tick = null;
  }

  /// 取消倒计时。打开面板 / 点刷新 / 点秒数 时调用。
  void cancel() {
    _token++;
    _clearTimers();
    final waiting = _wait;
    _wait = null;
    if (waiting != null && !waiting.isCompleted) {
      waiting.complete(true);
    }
    if (state.active) {
      state = LineAutoFailoverUiState.empty;
    }
  }

  /// 手切失败后：在 chip「连接失败」旁倒计时，到点自动切可用线。
  Future<void> schedule({
    required BuildContext context,
    required String failedLineId,
  }) async {
    var target = ref
        .read(lineProvider.notifier)
        .bestHealthyCandidate(excludeId: failedLineId);
    // 消息页往往没做过 probeAll，缓存里没有其它可用线 → 先静默补探再决定。
    if (target == null) {
      await ref.read(lineProvider.notifier).refreshHealthyLines();
      if (!context.mounted) return;
      target = ref
          .read(lineProvider.notifier)
          .bestHealthyCandidate(excludeId: failedLineId);
    }
    if (target == null) {
      if (context.mounted) {
        ImToast.show(context, LineSwitchUtil.switchFailedToast);
      }
      return;
    }

    final now = DateTime.now();
    if (_lastFailedLineId == failedLineId &&
        _lastOfferAt != null &&
        now.difference(_lastOfferAt!) < _debounce) {
      if (context.mounted) {
        ImToast.show(context, LineSwitchUtil.switchFailedToast);
      }
      return;
    }
    _lastFailedLineId = failedLineId;
    _lastOfferAt = now;

    cancel();
    final token = ++_token;
    final wait = Completer<bool>();
    _wait = wait;
    final targetLine = target;

    var secondsLeft = LineSwitchUtil.autoFailoverCountdownSeconds;
    log.i(
      '[Line] autofailover countdown start ${secondsLeft}s '
      'fail=$failedLineId -> ${targetLine.id}',
    );
    state = LineAutoFailoverUiState(
      secondsLeft: secondsLeft,
      targetLineId: targetLine.id,
      targetLineName: targetLine.name,
      failedLineId: failedLineId,
    );

    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (token != _token) {
        timer.cancel();
        return;
      }
      secondsLeft--;
      log.i('[Line] autofailover tick ${secondsLeft}s -> ${targetLine.id}');
      if (secondsLeft <= 0) {
        _clearTimers();
        state = LineAutoFailoverUiState.empty;
        if (!wait.isCompleted) wait.complete(false);
        return;
      }
      state = LineAutoFailoverUiState(
        secondsLeft: secondsLeft,
        targetLineId: targetLine.id,
        targetLineName: targetLine.name,
        failedLineId: failedLineId,
      );
    });

    final wasCancelled = await wait.future;
    if (wasCancelled || token != _token) {
      log.i('[Line] autofailover cancelled fail=$failedLineId');
      return;
    }
    if (!context.mounted) return;

    // 目标线刚探通过：直接采用，不再 probe（否则 chip 又闪「连接中」）。
    log.i('[Line] autofailover adopt ${targetLine.id}');
    final outcome =
        await ref.read(lineProvider.notifier).adoptHealthyLine(targetLine.id);
    if (!context.mounted) return;
    if (outcome.switched && outcome.success) {
      // 自动切线静默，不提示「已切换至xx」。
    } else if (!outcome.success) {
      ImToast.show(context, LineSwitchUtil.switchFailedToast);
    }
  }
}

final lineAutoFailoverProvider =
    NotifierProvider<LineAutoFailoverNotifier, LineAutoFailoverUiState>(
  LineAutoFailoverNotifier.new,
);