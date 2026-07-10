import 'package:flutter/material.dart';

import '../theme/im_colors.dart';
import '../theme/rpx.dart';
import 'im_switch.dart';

/// 圆角卡片菜单组。对应 bar-group.vue。
class ImBarGroup extends StatelessWidget {
  const ImBarGroup({
    super.key,
    required this.children,
    this.dividerIndent = 96,
  });

  final List<Widget> children;
  final double dividerIndent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        rpx(context, 24),
        0,
        rpx(context, 24),
        rpx(context, 24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(rpx(context, 24)),
        boxShadow: [
          BoxShadow(
            color: ImColors.accent.withValues(alpha: 0.06),
            blurRadius: rpx(context, 24),
            offset: Offset(0, rpx(context, 6)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: rpx(context, dividerIndent),
                color: ImColors.formDivider.withValues(alpha: 0.8),
              ),
          ],
        ],
      ),
    );
  }
}

/// 带开关菜单行。对应 switch-bar.vue。
class ImSwitchBar extends StatelessWidget {
  const ImSwitchBar({
    super.key,
    required this.title,
    required this.value,
    this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: rpx(context, 104),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: rpx(context, 24)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: rpx(context, 32),
                    color: ImColors.text,
                  ),
                ),
              ),
              ImSwitch(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 全宽按钮行。对应 btn-bar.vue（danger 退出登录等）。
class ImBtnBar extends StatelessWidget {
  const ImBtnBar({
    super.key,
    required this.title,
    this.danger = false,
    this.onTap,
  });

  final String title;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? ImColors.danger : ImColors.accent;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: rpx(context, 104),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: rpx(context, 32),
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 带箭头菜单行。对应 arrow-bar.vue。
class ImArrowBar extends StatelessWidget {
  const ImArrowBar({
    super.key,
    required this.title,
    this.icon,
    this.iconColor = ImColors.accent,
    this.trailing,
    this.onTap,
  });

  final String title;
  final IconData? icon;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = iconColor.withValues(alpha: 0.14);
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: rpx(context, 104),
          padding: EdgeInsets.symmetric(horizontal: rpx(context, 24)),
          decoration: const BoxDecoration(),
          child: Row(
            children: [
              if (icon != null)
                Container(
                  width: rpx(context, 56),
                  height: rpx(context, 56),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(rpx(context, 16)),
                  ),
                  child: Icon(icon, size: rpx(context, 38), color: iconColor),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: rpx(context, 20)),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: rpx(context, 32),
                      color: ImColors.text,
                    ),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
              Icon(
                Icons.chevron_right,
                size: rpx(context, 30),
                color: const Color(0xFFC4C4D0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// bar-group 内嵌实心主按钮。对齐 friend-apply.vue `bar-group > button[type=primary]`。
class ImBarPrimaryButton extends StatelessWidget {
  const ImBarPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Material(
      color: enabled ? ImColors.accent : ImColors.accent.withValues(alpha: 0.5),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: SizedBox(
          height: rpx(context, 88),
          width: double.infinity,
          child: Center(
            child: loading
                ? SizedBox(
                    width: rpx(context, 32),
                    height: rpx(context, 32),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: rpx(context, 32),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
