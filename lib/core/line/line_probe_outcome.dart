/// 单条线路探活结果（含失败分类，供 UI 缓存与上报）。
class LineProbeOutcome {
  const LineProbeOutcome({
    this.latencyMs,
    this.errorCategory,
    this.errorMessage,
    this.httpStatus,
  });

  final int? latencyMs;
  final String? errorCategory;
  final String? errorMessage;
  final int? httpStatus;

  bool get ok => latencyMs != null;

  static const failedUnknown = LineProbeOutcome(errorCategory: 'unknown');
}

/// 面板展示用的探活缓存项。
class LineProbeCacheEntry {
  const LineProbeCacheEntry({
    required this.ok,
    required this.checkedAtMs,
    this.latencyMs,
    this.errorCategory,
  });

  final bool ok;
  final int checkedAtMs;
  final int? latencyMs;
  final String? errorCategory;

  factory LineProbeCacheEntry.fromOutcome(LineProbeOutcome outcome) {
    return LineProbeCacheEntry(
      ok: outcome.ok,
      latencyMs: outcome.latencyMs,
      errorCategory: outcome.errorCategory,
      checkedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }
}