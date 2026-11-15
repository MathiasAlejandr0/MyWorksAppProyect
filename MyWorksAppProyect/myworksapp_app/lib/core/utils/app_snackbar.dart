import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppSnackBarType { info, success, warning, error }

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackBarType type = AppSnackBarType.info,
}) {
  final color = switch (type) {
    AppSnackBarType.success => AppColors.success,
    AppSnackBarType.warning => AppColors.warning,
    AppSnackBarType.error => AppColors.error,
    AppSnackBarType.info => AppColors.brandNavy,
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
