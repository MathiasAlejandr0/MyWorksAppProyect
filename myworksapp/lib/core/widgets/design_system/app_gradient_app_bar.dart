import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';

/// AppBar adaptativa: gradiente en Android, estilo Cupertino en iOS.
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
    if (_useCupertino(context)) {
      return _CupertinoBar(
        title: title,
        actions: actions,
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        bottom: bottom,
      );
    }

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      centerTitle: centerTitle,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: AppDecorations.headerGradient,
          boxShadow: AppDecorations.headerShadow,
        ),
      ),
      title: title,
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
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final nav = CupertinoNavigationBar(
      backgroundColor: Colors.transparent,
      border: null,
      middle: title != null
          ? DefaultTextStyle(
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 17,
                decoration: TextDecoration.none,
              ),
              child: title!,
            )
          : null,
      leading: leading ??
          (automaticallyImplyLeading && Navigator.canPop(context)
              ? CupertinoNavigationBarBackButton(
                  color: AppColors.white,
                  onPressed: () => Navigator.maybePop(context),
                )
              : null),
      trailing: actions != null && actions!.isNotEmpty
          ? IconTheme(
              data: const IconThemeData(color: AppColors.white),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
            )
          : null,
    );

    final bar = Container(
      decoration: BoxDecoration(
        gradient: AppDecorations.headerGradient,
        boxShadow: AppDecorations.headerShadow,
      ),
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

    return Material(
      color: Colors.transparent,
      child: bar,
    );
  }
}
