import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/di/app_providers.dart';
import '../core/line/line_config.dart';
import '../core/utils/line_switch_util.dart';
import '../theme/im_colors.dart';
import '../theme/rpx.dart';
import 'im_toast.dart';

/// 线路面板对齐方式。对齐 line-switcher-panel `align`。
enum LinePanelAlign { left, right }

/// 在 chip 下方弹出线路选择面板（遮罩 + 下拉卡片）。
Future<void> showLineSwitcherPanel(
  BuildContext context,
  WidgetRef ref, {
  required GlobalKey anchorKey,
  LinePanelAlign align = LinePanelAlign.left,
}) async {
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
        current: ref.read(lineProvider),
      );
    },
  );
  if (picked == null || !context.mounted) return;

  final outcome = await ref.read(lineProvider.notifier).switchTo(picked);
  if (!context.mounted) return;

  if (outcome.switched && outcome.success) {
    ImToast.show(context, LineSwitchUtil.successToast(outcome.line.name));
  }
}

class _LineSwitcherPanelOverlay extends StatelessWidget {
  const _LineSwitcherPanelOverlay({
    required this.anchorKey,
    required this.align,
    required this.current,
  });

  final GlobalKey anchorKey;
  final LinePanelAlign align;
  final LineConfig current;

  @override
  Widget build(BuildContext context) {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final offset = box?.localToGlobal(Offset.zero);
    final size = box?.size;
    final panelWidth = rpx(context, 300);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final top = (offset?.dy ?? kToolbarHeight) + (size?.height ?? 0) - rpx(context, 6);

    double? left;
    double? right;
    double arrowLeft;
    if (align == LinePanelAlign.right) {
      right = rpx(context, 20);
      arrowLeft = panelWidth - rpx(context, 48) - rpx(context, 16);
    } else if (offset != null && size != null) {
      left = offset.dx.clamp(rpx(context, 20), screenWidth - panelWidth - rpx(context, 20));
      arrowLeft = rpx(context, 48);
    } else {
      left = rpx(context, 20);
      arrowLeft = rpx(context, 48);
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
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
              crossAxisAlignment: align == LinePanelAlign.right
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
                        padding: EdgeInsets.symmetric(
                          horizontal: rpx(context, 20),
                          vertical: rpx(context, 14),
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF2F2F2)),
                          ),
                        ),
                        child: Text(
                          '连接异常时可切换线路',
                          style: TextStyle(
                            fontSize: rpx(context, 20),
                            color: const Color(0xFF999999),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: rpx(context, 480)),
                        child: ListView(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          children: [
                            for (var i = 0; i < kVisibleLines.length; i++)
                              _LinePanelItem(
                                line: kVisibleLines[i],
                                selected: kVisibleLines[i].id == current.id,
                                showDivider: i < kVisibleLines.length - 1,
                                onTap: () => Navigator.of(context).pop(kVisibleLines[i].id),
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
  });

  final LineConfig line;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              if (selected)
                Icon(
                  Icons.check,
                  size: rpx(context, 36),
                  color: ImColors.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
