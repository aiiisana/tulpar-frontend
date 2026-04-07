import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF2D4F3C);
  static const Color background = Color(0xFFF3F2ED);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color border = Color(0xFFD6D6D6);
  static const Color chipFill = Color(0xFFE8F0DC);
  static const Color calendarDayBg = Color(0xFFE4E2DA);
  static const Color learningCardBg = Color(0xFFDEDAD2);
  static const Color learningTileBg = Color(0xFFEBE8E0);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
    );
  }
}
