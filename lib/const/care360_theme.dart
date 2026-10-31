import 'package:flutter/material.dart';

import 'Palette.dart';

/// Shared Care360 Patient visual language.
///
/// This is deliberately a visual-only theme: navigation, authentication,
/// network clients and payment behaviour are owned by their existing modules.
class Care360Theme {
  Care360Theme._();

  static const Color canvas = Color(0xFFF6F9FD);
  static const Color ink = Color(0xFF102B48);
  static const Color muted = Color(0xFF576E86);
  static const Color border = Color(0xFFE0EAF5);
  static const Color softBlue = Color(0xFFEAF4FF);
  static const Color highlight = Color(0xFF19B7B0);

  static ThemeData get light {
    final colors = ColorScheme.fromSeed(
      seedColor: Palette.blue,
      primary: Palette.dark_blue,
      secondary: Palette.blue,
      surface: Palette.white,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: false, // Keep legacy Care360 navigation and dialogs stable.
      colorScheme: colors,
      primaryColor: Palette.blue,
      scaffoldBackgroundColor: canvas,
      splashColor: Palette.blue.withOpacity(0.07),
      highlightColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.white,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.white,
        hintStyle: const TextStyle(color: muted, fontSize: 15),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Palette.blue, width: 1.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.dark_blue,
          foregroundColor: Palette.white,
          minimumSize: const Size(44, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.dark_blue,
          minimumSize: const Size(44, 52),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.9,
          height: 1.14,
        ),
        titleLarge: TextStyle(color: ink, fontSize: 21, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(color: muted, fontSize: 15, height: 1.5),
      ),
    );
  }
}
