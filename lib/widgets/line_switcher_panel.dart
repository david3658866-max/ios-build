import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../core/line/line_config.dart';
import '../core/line/line_probe_outcome.dart';
import '../core/utils/line_switch_util.dart';
import '../core/ws/ws_event.dart';
import '../stores/config_store.dart';
import '../theme/im_colors.dart';
import '../theme/rpx.dart';
import 'im_toast.dart';
import 'line_auto_failover_offer.dart';

/// 线路面板对齐方式。对齐 line-switcher-panel `align`。
enum LinePanelAlign { left, right }

/// 在 chip 下方弹出线路选择面板（遮罩 + 下拉卡片）。
Future<void> showLineSwitcherPanel(
  BuildContext context,
  WidgetRef ref, {
  required GlobalKey anchorKey,
  LinePanelAlign align = LinePanelAlign.left,
}) async {
  ref.read(lineAutoFailoverProvider.notifier).cancel();
  final picked = await showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '关闭线路选择',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, __) {
      return _LineSwitcherPanelOverlay(
        anchorKey: anchorKey,
        align: align,
      );
    },
  );
  if (picked == null || !context.mounted) return;

  final outcome = await ref.read(lineProvider.notifier).switchTo(picked);
  if (!context.mounted) return;

  if (outcome.switched && outcome.success) {
    ImToast.show(context, LineSwitchUtil.successToast(outcome.line.name));
  } else if (!outcome.success) {
    // 换线失败 / 同线重连失败：统一走 3s 自动切可用线（消息页与登录页一致）。
    await ref.read(lineAutoFailoverProvider.notifier).schedule(
          context: context,
          failedLineId: picked,
        );
  }
}

class _LineSwitcherPanelOverlay extends ConsumerStatefulWidget {
  const _LineSwitcherPanelOverlay({
    required this.anchorKey,
    required this.align,
  });

  final GlobalKey anchorKey;
  final LinePanelAlign align;

  @override
  ConsumerState<_LineSwitcherPanelOverlay> createState() =>
      _LineSwitcherPanelOverlayState();
}

class _LineSwitcherPanelOverlayState
    extends ConsumerState<_LineSwitcherPanelOverlay> {
  bool _retrying = false;

  Future<void> _retryProbeInPanel() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    ImToast.show(context, LineSwitchUtil.retryProbeToast);
    try {
      final ok = await ref
          .read(lineProvider.notifier)
          .checkCurrentLineStatus(
            allowFallback: true,
            exhaustiveProbe: true,
          );
      if (!mounted) return;
      ImToast.show(
        context,
        ok
            ? LineSwitchUtil.retryProbeOkToast
            : LineSwitchUtil.retryProbeAllFailedToast,
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final box =
        widget.anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = box?.localToGlobal(Offset.zero);
    final size = box?.size;
    final panelWidth = rpx(context, 340);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final top =
        (offset?.dy ?? kToolbarHeight) + (size?.height ?? 0) - rpx(context, 6);
    final probeCache = ref.watch(lineProbeCacheProvider);
    final currentLine = ref.watch(lineProvider);
    final lineStatus = ref.watch(configStoreProvider).lineStatus;
    final probing = _retrying ||
        lineStatus == WsStatus.connecting ||
        lineStatus == WsStatus.authing;
    final panelLines = LineSwitchUtil.linesForSwitcherPanel(
      runtimeLines: kVisibleLines,
      currentId: currentLine.id,
      probeCache: probeCache,
    );

    double? left;
    double? right;
    double arrowLeft;
    if (widget.align == LinePanelAlign.right) {
      right = rpx(context, 20);
      arrowLeft = panelWidth - rpx(context, 48) - rpx(context, 16);
    } else if (offset != null && size != null) {
      left = offset.dx.clamp(
        rpx(context, 20),
        screenWidth - panelWidth - rpx(context, 20),
      );
      arrowLeft = rpx(context, 48);
    } else {
      left = rpx(context, 20);
      arrowLeft = rpx(context, 48);
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 遮罩始终可关：探活中若禁用会点不掉（本地线超时等 connecting 很长）。
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Positioned(
            top: top,
            left: left,
            right: right,
            width: left != null || right != null ? panelWidth : null,
            child: Column(
              crossAxisAlignment: widget.align == LinePanelAlign.right
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: arrowLeft),
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: rpx(context, 16),
                      height: rpx(context, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: rpx(context, 6),
                            offset: Offset(-rpx(context, 2), -rpx(context, 2)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: panelWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(rpx(context, 14)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: rpx(context, 28),
                        offset: Offset(0, rpx(context, 8)),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          rpx(context, 12),
                          rpx(context, 8),
                          rpx(context, 4),
                          rpx(context, 8),
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF2F2F2)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '连接异常时可切换线路',
                                style: TextStyle(
                                  fontSize: rpx(context, 20),
                                  color: const Color(0xFF999999),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                // 扩大热区：整块可点，避免只点到图标/文字才响应。
                                onTap: probing
                                    ? null
                                    : () => unawaited(_retryProbeInPanel()),
                                borderRadius:
                                    BorderRadius.circular(rpx(context, 8)),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: rpx(context, 12),
                                    vertical: rpx(context, 10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (probing)
                                        SizedBox(
                                          width: rpx(context, 22),
                                          height: rpx(context, 22),
                                          child: CircularProgressIndicator(
                                            strokeWidth: rpx(context, 2),
                                            color: ImColors.accent,
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.refresh,
                                          size: rpx(context, 28),
                                          color: ImColors.accent,
                                        ),
                                      SizedBox(width: rpx(context, 4)),
                                      Text(
                                        probing ? '检测中' : '重新检测',
                                        style: TextStyle(
                                          fontSize: rpx(context, 22),
                                          color: ImColors.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius:
                                    BorderRadius.circular(rpx(context, 8)),
                                child: Padding(
                                  padding: EdgeInsets.all(rpx(context, 10)),
                                  child: Icon(
                                    Icons.close,
                                    size: rpx(context, 28),
                                    color: const Color(0xFF999999),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ConstrainedBox(
                        constraints:
                            BoxConstraints(maxHeight: rpx(context, 480)),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            for (var i = 0; i < panelLines.length; i++)
                              _LinePanelItem(
                                line: panelLines[i],
                                selected: panelLines[i].id == currentLine.id,
                                showDivider: i < panelLines.length - 1,
                                probe: probeCache[panelLines[i].id],
                                // 探活中仍可选线并关闭；仅「重新检测」防重复点。
                                onTap: () => Navigator.of(context)
                                    .pop(panelLines[i].id),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinePanelItem extends StatelessWidget {
  const _LinePanelItem({
    required this.line,
    required this.selected,
    required this.showDivider,
    required this.onTap,
    this.probe,
  });

  final LineConfig line;
  final bool selected;
  final bool showDivider;
  final VoidCallback? onTap;
  final LineProbeCacheEntry? probe;

  @override
  Widget build(BuildContext context) {
    final statusText = LineSwitchUtil.probeStatusLabel(probe);
    final statusColor = probe == null
        ? const Color(0xFFBBBBBB)
        : (probe!.ok ? const Color(0xFF2BA471) : const Color(0xFFE43D33));

    return Material(
      color: selected ? ImColors.messageHighlightBg : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: rpx(context, 20),
            vertical: rpx(context, 18),
          ),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(bottom: BorderSide(color: Color(0xFFF5F5F5)))
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  line.name,
                  style: TextStyle(
                    fontSize: rpx(context, 26),
                    color: ImColors.text,
                  ),
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: rpx(context, 22),
                  color: statusColor,
                ),
              ),
              if (selected) ...[
                SizedBox(width: rpx(context, 8)),
                Icon(
                  Icons.check,
                  size: rpx(context, 36),
                  color: ImColors.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
