/// 聊天消息虚拟窗口。对齐 chat-box.vue `pageSize` / `preloadStep` / `maxRenderCount`。
abstract final class ChatMessageWindowConfig {
  static const int pageSize = 15;
  static const int preloadStep = 10;
  static const int maxRenderCount = 220;

  /// 进聊天 / 按会话离线拉取条数（与服务端 size 对齐）。
  static const int initialPullSize = pageSize;

  /// 定位/@/引用时从本地扩读的上限，避免一次拉入数千条。
  static const int locateMaxLimit = 500;

  /// 上拉历史时 `_messageLimit` 上限（仅本地，不打服务端）。
  static const int historyMaxLimit = 500;

  /// 贴顶触发阈值。适当放宽，减少轻微回弹导致的误触发历史加载。
  static const double scrollTopThreshold = 28;
}
/// 当前渲染窗口下标。`showMaxIdx < 0` 表示渲染到末尾。
class ChatMessageWindowState {
  const ChatMessageWindowState({
    this.showMinIdx = 0,
    this.showMaxIdx = -1,
  });

  final int showMinIdx;
  final int showMaxIdx;

  /// 进入会话或回到底部：渲染最后一页。
  static ChatMessageWindowState bottomPage(int totalSize) {
    if (totalSize <= 0) {
      return const ChatMessageWindowState();
    }
    final min = totalSize > ChatMessageWindowConfig.pageSize
        ? totalSize - ChatMessageWindowConfig.pageSize
        : 0;
    return ChatMessageWindowState(showMinIdx: min, showMaxIdx: -1);
  }

  /// 上拉触顶：向上扩展窗口。
  ChatMessageWindowState expandHistory({required int totalSize}) {
    if (showMinIdx <= 0) return this;
    final step = ChatMessageWindowConfig.preloadStep;
    final newMin = showMinIdx > step ? showMinIdx - step : 0;
    return normalizeMessageWindow(
      showMinIdx: newMin,
      showMaxIdx: showMaxIdx,
      totalSize: totalSize,
      anchorIdx: newMin,
    );
  }

  /// 已贴顶且 showMinIdx=0 时，向下扩展可见上界（避免 maxIdx=-1 一次渲染全部）。
  ChatMessageWindowState expandFromTop({required int totalSize}) {
    final step = ChatMessageWindowConfig.preloadStep;
    final pageSize = ChatMessageWindowConfig.pageSize;
    final currentEnd = showMaxIdx > 0 ? showMaxIdx : pageSize.clamp(0, totalSize);
    final newMax = (currentEnd + step).clamp(0, totalSize);
    return normalizeMessageWindow(
      showMinIdx: 0,
      showMaxIdx: newMax,
      totalSize: totalSize,
      anchorIdx: 0,
    );
  }

  /// 贴顶浏览历史时初始化窗口（只渲染最早一页，而非整表）。
  static ChatMessageWindowState topPage(int totalSize) {
    if (totalSize <= 0) {
      return const ChatMessageWindowState();
    }
    final end = totalSize > ChatMessageWindowConfig.pageSize
        ? ChatMessageWindowConfig.pageSize
        : totalSize;
    return ChatMessageWindowState(showMinIdx: 0, showMaxIdx: end);
  }

  /// 定位消息：以目标为中心开窗口。
  static ChatMessageWindowState forLocate({
    required int index,
    required int totalSize,
  }) {
    final pageSize = ChatMessageWindowConfig.pageSize;
    final half = pageSize ~/ 2;
    var minIdx = index - half;
    if (minIdx < 0) minIdx = 0;
    var maxIdx = minIdx + pageSize;
    if (maxIdx > totalSize) {
      maxIdx = totalSize;
      minIdx = totalSize > pageSize ? totalSize - pageSize : 0;
    }
    return normalizeMessageWindow(
      showMinIdx: minIdx,
      showMaxIdx: maxIdx,
      totalSize: totalSize,
      anchorIdx: index,
    );
  }

  ChatMessageWindowState normalize({
    required int totalSize,
    int? anchorIdx,
  }) =>
      normalizeMessageWindow(
        showMinIdx: showMinIdx,
        showMaxIdx: showMaxIdx,
        totalSize: totalSize,
        anchorIdx: anchorIdx,
      );

  int windowSize(int totalSize) {
    final end = showMaxIdx > 0 ? showMaxIdx : totalSize;
    return end - showMinIdx;
  }
}

/// 裁剪窗口，防止 DOM/列表项过多。对齐 `normalizeWindow`。
ChatMessageWindowState normalizeMessageWindow({
  required int showMinIdx,
  required int showMaxIdx,
  required int totalSize,
  int? anchorIdx,
}) {
  if (totalSize <= 0) {
    return const ChatMessageWindowState();
  }
  final maxCount = ChatMessageWindowConfig.maxRenderCount;
  var minIdx = showMinIdx < 0 ? 0 : showMinIdx;
  var maxIdx = showMaxIdx > 0 ? showMaxIdx : totalSize;
  if (minIdx > totalSize) minIdx = totalSize;
  if (maxIdx > totalSize) maxIdx = totalSize;
  final windowSize = maxIdx - minIdx;
  if (windowSize <= maxCount) {
    return ChatMessageWindowState(
      showMinIdx: minIdx,
      showMaxIdx: showMaxIdx > 0 ? maxIdx : -1,
    );
  }
  var anchor = anchorIdx ?? maxIdx - 1;
  if (anchor < minIdx) anchor = minIdx;
  if (anchor >= maxIdx) anchor = maxIdx - 1;
  final half = maxCount ~/ 2;
  var newMin = anchor - half;
  var newMax = anchor + (maxCount - half);
  if (newMin < 0) {
    newMin = 0;
    newMax = maxCount;
  }
  if (newMax > totalSize) {
    newMax = totalSize;
    newMin = totalSize > maxCount ? totalSize - maxCount : 0;
  }
  return ChatMessageWindowState(showMinIdx: newMin, showMaxIdx: newMax);
}

List<T> sliceMessages<T>({
  required List<T> messages,
  required ChatMessageWindowState window,
}) {
  if (messages.isEmpty) return const [];
  final min = window.showMinIdx.clamp(0, messages.length);
  if (window.showMaxIdx < 0) {
    return min == 0 ? messages : messages.sublist(min);
  }
  final max = window.showMaxIdx.clamp(min, messages.length);
  return messages.sublist(min, max);
}

/// 定位/补拉历史时每次扩窗步长。
int locateHistoryFetchStep() => ChatMessageWindowConfig.pageSize;

/// 定位扩读上限。
int locateHistoryMaxLimit() => ChatMessageWindowConfig.locateMaxLimit;
