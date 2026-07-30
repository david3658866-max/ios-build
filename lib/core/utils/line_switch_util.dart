import '../line/line_config.dart';
import '../line/line_probe_outcome.dart';
import '../ws/ws_event.dart';

/// 线路切换结果。对齐 uniapp `switchLine()` 返回值语义。
class LineSwitchOutcome {
  const LineSwitchOutcome({
    required this.success,
    required this.switched,
    required this.line,
  });

  final bool success;
  final bool switched;
  final LineConfig line;
}

/// 线路切换辅助。对齐 im-uniapp line-manager / line-switcher。
abstract final class LineSwitchUtil {
  static String successToast(String lineName) => '已切换到$lineName';

  /// 登录/注册页探活后自动切线。
  static String autoSwitchToast(String lineName) => '已切换至$lineName';

  /// 登录/注册页并发探活全部不可用。
  static const allLinesFailedToast = '网络异常，请稍后重试或手动切换线路';

  static const probeFailedToast = '该线路连接失败，请换一条试试';

  static const switchFailedToast = '切换失败，该线路暂不可用';

  static const reconnectFailedToast = '重连失败，请换一条线路或稍后重试';

  static const retryProbeToast = '正在重新检测线路…';

  static const retryProbeOkToast = '线路检测完成';

  static const retryProbeAllFailedToast = '仍无法连接，请检查网络后重试';

  /// API 连接失败自动切线成功后的冷却，避免短时间反复跳线。
  static const apiConnectionFailoverCooldown = Duration(seconds: 30);

  /// 自动切线只采信近期探活，过期缓存不 adopt（避免切到早已不通的线）。
  static const apiFailoverProbeMaxAge = Duration(minutes: 5);

  /// 同一波 API 失败最多自动切线次数（再多只重试当前 baseUrl，不连跳）。
  static const apiFailoverMaxSwitchesPerWave = 1;

  /// WS 连续断开（本波未达 connected）达到此次数后自动切备用线。
  static const wsDisconnectFailoverThreshold = 2;

  /// WS 自动切线成功后的冷却，避免短时间反复跳线。
  static const wsDisconnectFailoverCooldown = Duration(seconds: 60);

  /// chip：已登录、HTTPS 探活通、但真实 WS 已断开。
  static const messageChannelDegradedLabel = '消息异常';

  /// 探活缓存是否仍可用于自动切线。
  static bool isProbeFreshForApiFailover(
    LineProbeCacheEntry entry, {
    DateTime? now,
    Duration maxAge = apiFailoverProbeMaxAge,
  }) {
    if (!entry.ok) return false;
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final age = nowMs - entry.checkedAtMs;
    return age >= 0 && age <= maxAge.inMilliseconds;
  }

  /// 是否应跳过本次 API 连接失败自动切线（无网 / 冷却且非本波续切）。
  static bool shouldSkipApiConnectionFailover({
    required bool deviceOffline,
    required bool hasTriedInWave,
    required DateTime? cooldownUntil,
    DateTime? now,
  }) {
    if (deviceOffline) return true;
    if (hasTriedInWave) return false;
    final until = cooldownUntil;
    if (until == null) return false;
    return (now ?? DateTime.now()).isBefore(until);
  }

  /// 手切失败后倒计时自动切线。
  static const autoFailoverCountdownSeconds = 3;

  static const autoFailoverCancelLabel = '取消';

  /// chip「连接失败」旁的秒数，如 `3s`。
  static String autoFailoverChipSeconds(int seconds) => '${seconds}s';

  static String autoFailoverCountdown(String lineName, int seconds) =>
      '该线路不可用，$seconds 秒后切换到$lineName';

  static const autoFailoverCancelledToast = '已取消自动切换';

  /// 面板展示：通 120ms / 不通 / 未检测
  static String probeStatusLabel(LineProbeCacheEntry? entry) {
    if (entry == null) return '未检测';
    if (entry.ok) {
      final ms = entry.latencyMs;
      return ms == null ? '通' : '通 ${ms}ms';
    }
    return '不通';
  }

  /// 启动预探成功后，登录页可复用的最长时间。
  static const authWarmupReuseTtl = Duration(minutes: 2);

  /// 闪屏内等待登录探路的上限（超时仍进登录页，探路可后台继续）。
  static const authWarmupSplashWait = Duration(milliseconds: 2500);

  /// 启动预探结果是否仍可被登录页直接复用（避免二次全量探）。
  static bool shouldReuseAuthWarmup({
    required bool lastOk,
    required DateTime? completedAt,
    required bool hasHealthyLines,
    DateTime? now,
    Duration ttl = authWarmupReuseTtl,
  }) {
    if (!lastOk || !hasHealthyLines || completedAt == null) return false;
    final age = (now ?? DateTime.now()).difference(completedAt);
    return !age.isNegative && age <= ttl;
  }

  /// 冷启动内置池过大时，面板只展示优先池 / 当前线 / 已探通，避免刷 400+。
  static const panelSoftCap = 48;

  /// 构造线路面板列表：运行时表较小时原样排序；过大则收束到可选手动线。
  static List<LineConfig> linesForSwitcherPanel({
    required List<LineConfig> runtimeLines,
    required String currentId,
    required Map<String, LineProbeCacheEntry?> probeCache,
    int softCap = panelSoftCap,
    bool Function(String id) isPreferred = isPreferredBuiltinLine,
  }) {
    final source = runtimeLines.length <= softCap
        ? runtimeLines
        : () {
            final picked = <String, LineConfig>{};
            for (final line in runtimeLines) {
              if (line.id == currentId || isPreferred(line.id)) {
                picked[line.id] = line;
                continue;
              }
              final entry = probeCache[line.id];
              if (entry != null && entry.ok) {
                picked[line.id] = line;
              }
            }
            if (picked.isEmpty) {
              return runtimeLines.take(softCap).toList(growable: false);
            }
            return picked.values.toList(growable: false);
          }();
    return orderLinesForPanel(
      lines: source,
      currentId: currentId,
      probeCache: probeCache,
    );
  }

  /// 探活选线：优先落在远程启用表内的通线；启用表全挂才用种子通线。
  static LineConfig pickProbeSelectTarget({
    required LineConfig current,
    required List<LineConfig> healthySortedByLatency,
    required Set<String> productionIds,
  }) {
    if (healthySortedByLatency.isEmpty) return current;
    final inProduction = healthySortedByLatency
        .where((e) => productionIds.contains(e.id))
        .toList(growable: false);
    final pool =
        inProduction.isNotEmpty ? inProduction : healthySortedByLatency;
    if (pool.any((e) => e.id == current.id)) return current;
    return pool.first;
  }

  /// 线路面板排序：当前线 → 已通（快到慢）→ 未检测 → 不通。
  ///
  /// 避免前排域名 DNS 挂时，用户一打开面板只看到「全不通」。
  static List<LineConfig> orderLinesForPanel({
    required List<LineConfig> lines,
    required String currentId,
    required Map<String, LineProbeCacheEntry?> probeCache,
  }) {
    int rank(LineConfig line) {
      if (line.id == currentId) return 0;
      final entry = probeCache[line.id];
      if (entry == null) return 2;
      if (entry.ok) return 1;
      return 3;
    }

    final sorted = List<LineConfig>.from(lines);
    sorted.sort((a, b) {
      final ra = rank(a);
      final rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      if (ra == 1) {
        final ma = probeCache[a.id]?.latencyMs ?? 1 << 30;
        final mb = probeCache[b.id]?.latencyMs ?? 1 << 30;
        final byMs = ma.compareTo(mb);
        if (byMs != 0) return byMs;
      }
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  /// 桥接种子线：远程表未包含当前线，但探活仍新鲜 → 暂留，避免刚救活又被踢回坏线。
  static const seedBridgeKeepMaxAge = Duration(minutes: 10);

  static bool shouldKeepSeedBridgeLine({
    required LineProbeCacheEntry? probe,
    DateTime? now,
    Duration maxAge = seedBridgeKeepMaxAge,
  }) {
    final entry = probe;
    if (entry == null || !entry.ok) return false;
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final age = nowMs - entry.checkedAtMs;
    return age >= 0 && age <= maxAge.inMilliseconds;
  }

  /// 线路 chip 状态。
  ///
  /// - 未登录：只看 HTTPS 探活 [lineStatus]
  /// - 已登录：探活不通/探活中仍看 [lineStatus]；探活通则反映真实 [wsStatus]
  static WsStatus chipStatus({
    required bool isAuthenticated,
    required WsStatus lineStatus,
    required WsStatus wsStatus,
  }) {
    if (!isAuthenticated) return lineStatus;
    if (lineStatus == WsStatus.connecting ||
        lineStatus == WsStatus.authing ||
        lineStatus == WsStatus.disconnected) {
      return lineStatus;
    }
    // HTTPS 探活已通：chip 跟真实 WS，避免「已通」掩盖消息通道挂掉。
    return wsStatus;
  }

  /// 已登录 + HTTP 通 + WS 断 → chip 显示「消息异常」（非红字「连接失败」）。
  static bool isMessageChannelDegraded({
    required bool isAuthenticated,
    required WsStatus lineStatus,
    required WsStatus wsStatus,
  }) =>
      isAuthenticated &&
      lineStatus == WsStatus.connected &&
      wsStatus == WsStatus.disconnected;

  /// 是否展示线路入口（chip / 面板）。
  ///
  /// - 已连通：隐藏
  /// - 未登录探活中（连接中/鉴权中）：隐藏，避免登录页干等焦虑
  /// - 失败 / 已登录探活中 / 消息通道异常：展示，便于手切
  static bool shouldShowSwitcherEntry({
    required bool isAuthenticated,
    required WsStatus lineStatus,
    required WsStatus wsStatus,
  }) {
    if (isMessageChannelDegraded(
      isAuthenticated: isAuthenticated,
      lineStatus: lineStatus,
      wsStatus: wsStatus,
    )) {
      return true;
    }
    final status = chipStatus(
      isAuthenticated: isAuthenticated,
      lineStatus: lineStatus,
      wsStatus: wsStatus,
    );
    if (status == WsStatus.connected) return false;
    // 登录/注册页：连接中不露芯片，只在失败时出现。
    if (!isAuthenticated &&
        (status == WsStatus.connecting || status == WsStatus.authing)) {
      return false;
    }
    return true;
  }
  /// 是否应触发 WS 连续断开自动切线。
  static bool shouldTriggerWsDisconnectFailover({
    required int consecutiveDisconnectsWithoutConnect,
    required bool deviceOffline,
    required DateTime? cooldownUntil,
    int threshold = wsDisconnectFailoverThreshold,
    DateTime? now,
  }) {
    if (deviceOffline) return false;
    if (consecutiveDisconnectsWithoutConnect < threshold) return false;
    final until = cooldownUntil;
    if (until != null && (now ?? DateTime.now()).isBefore(until)) {
      return false;
    }
    return true;
  }

  /// 同线路再次选择且 WS 失败时，对齐 panel `afterLineSwitch` + `onLineSwitched`。
  static bool shouldReconnectSameLine({
    required bool isAuthenticated,
    required WsStatus chipStatus,
  }) =>
      isAuthenticated && chipStatus == WsStatus.disconnected;

  /// 注册/登录网络失败换线：从已探通列表里排除已试过的，按延迟顺序取下一条。
  static LineConfig? nextHealthyCandidate({
    required List<LineConfig> healthySortedByLatency,
    required Set<String> triedIds,
  }) {
    for (final line in healthySortedByLatency) {
      if (!triedIds.contains(line.id)) return line;
    }
    return null;
  }

  /// 登录/注册前是否可跳过全量探活。
  ///
  /// chip 已连通，且当前线路近期探活成功 → 直接请求，避免再闪「连接中」。
  static bool shouldSkipAuthPreProbe({
    required WsStatus lineStatus,
    required LineProbeCacheEntry? currentLineProbe,
    Duration maxAge = const Duration(minutes: 2),
    int? nowMs,
  }) {
    if (lineStatus != WsStatus.connected) return false;
    final entry = currentLineProbe;
    if (entry == null || !entry.ok) return false;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final age = now - entry.checkedAtMs;
    return age >= 0 && age <= maxAge.inMilliseconds;
  }
}
