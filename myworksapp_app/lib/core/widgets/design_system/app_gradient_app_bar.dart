import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// AppBar limpia y adaptativa estilo Apple HIG con translucidez y tipografía Navy/White.
class AppGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppGradientAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.centerTitle = false,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  bool _useCupertino(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fgColor = isDark ? AppColors.white : AppColors.brandNavy;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    if (_useCupertino(context)) {
      return _CupertinoBar(
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
        isDark: isDark,
        fgColor: fgColor,
      );
    }

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      iconTheme: IconThemeData(color: fgColor),
      actionsIconTheme: IconThemeData(color: fgColor),
      centerTitle: centerTitle,
      title: title != null
          ? DefaultTextStyle(
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              child: title!,
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }
}

class _CupertinoBar extends StatelessWidget implements PreferredSizeWidget {
  const _CupertinoBar({
    this.title,
    this.actions,
    this.leading,
    required this.automaticallyImplyLeading,
    this.bottom,
    required this.isDark,
    required this.fgColor,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final bool isDark;
  final Color fgColor;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    final nav = CupertinoNavigationBar(
      backgroundColor: bgColor,
      border: Border(
        bottom: BorderSide(
          color: isDark
              ? AppColors.grayBorder.withValues(alpha: 0.12)
              : AppColors.grayBorder.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      middle: title != null
          ? DefaultTextStyle(
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                decoration: TextDecoration.none,
              ),
              child: title!,
            )
          : null,
      leading: leading ??
          (automaticallyImplyLeading && Navigator.canPop(context)
              ? CupertinoNavigationBarBackButton(
                  color: fgColor,
                  onPressed: () => Navigator.maybePop(context),
                )
              : null),
      trailing: actions != null && actions!.isNotEmpty
          ? IconTheme(
              data: IconThemeData(color: fgColor),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
            )
          : null,
    );

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: bottom == null
            ? nav
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  nav,
                  bottom!,
                ],
              ),
      ),
    );
  }
}

