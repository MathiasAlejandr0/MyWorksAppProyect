import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Estilos de texto del Design System con Plus Jakarta Sans.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle displayLarge({Color? color}) => _getTextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.grayDark,
        letterSpacing: -1,
        height: 1.2,
      );

  static TextStyle displayMedium({Color? color}) => _getTextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color ?? AppColors.grayDark,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle displaySmall({Color? color}) => _getTextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.grayDark,
        letterSpacing: -0.5,
        height: 1.3,
      );

  static TextStyle headlineLarge({Color? color}) => _getTextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.grayDark,
        letterSpacing: -0.5,
        height: 1.3,
      );

  static TextStyle headlineMedium({Color? color}) => _getTextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.grayDark,
        letterSpacing: -0.5,
        height: 1.3,
      );

  static TextStyle headlineSmall({Color? color}) => _getTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.grayDark,
        height: 1.4,
      );

  static TextStyle titleLarge({Color? color}) => _getTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.grayDark,
        height: 1.4,
      );

  static TextStyle titleMedium({Color? color}) => _getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.grayDark,
        height: 1.4,
      );

  static TextStyle titleSmall({Color? color}) => _getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.grayDark,
        height: 1.4,
      );

  static TextStyle bodyLarge({Color? color}) => _getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.grayDark,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color? color}) => _getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.grayDark,
        height: 1.5,
      );

  static TextStyle bodySmall({Color? color}) => _getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.grayMedium,
        height: 1.4,
      );

  static TextStyle labelLarge({Color? color}) => _getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.grayDark,
        letterSpacing: 0.1,
      );

  static TextStyle labelMedium({Color? color}) => _getTextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.grayDark,
        letterSpacing: 0.1,
      );

  static TextStyle labelSmall({Color? color}) => _getTextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.grayMedium,
        letterSpacing: 0.1,
      );

  static TextStyle buttonPrimary({Color? color}) => _getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.white,
        letterSpacing: 0.3,
      );

  static TextStyle buttonSecondary({Color? color}) => _getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.primaryLight,
        letterSpacing: 0.3,
      );

  static TextStyle inputLabel({Color? color}) => _getTextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.grayMedium,
      );

  static TextStyle inputHint({Color? color}) => _getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.grayMedium,
      );
}
