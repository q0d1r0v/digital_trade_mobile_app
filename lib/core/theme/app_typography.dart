import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'Roboto';

  static TextTheme textTheme({required bool dark}) {
    final fg = dark ? AppColors.white : AppColors.black;
    final muted = dark ? AppColors.gray400 : AppColors.gray600;

    TextStyle s(double size, FontWeight w, {Color? color}) => TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          fontWeight: w,
          color: color ?? fg,
          height: 1.3,
        );

    return TextTheme(
      displayLarge: s(32, FontWeight.w700),
      displayMedium: s(28, FontWeight.w700),
      displaySmall: s(24, FontWeight.w700),
      headlineLarge: s(22, FontWeight.w700),
      headlineMedium: s(20, FontWeight.w600),
      headlineSmall: s(18, FontWeight.w600),
      titleLarge: s(16, FontWeight.w600),
      titleMedium: s(15, FontWeight.w600),
      titleSmall: s(14, FontWeight.w600),
      bodyLarge: s(16, FontWeight.w400),
      bodyMedium: s(14, FontWeight.w400),
      bodySmall: s(12, FontWeight.w400, color: muted),
      labelLarge: s(14, FontWeight.w500),
      labelMedium: s(12, FontWeight.w500),
      labelSmall: s(11, FontWeight.w500, color: muted),
    );
  }
}
