import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const primary = Color(0xFFF47020);
  static const secondary = Color(0xFFF99F72);

  static ThemeData get light => _theme(Brightness.light);

  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFFFFB68A) : primary,
      onPrimary: isDark ? const Color(0xFF5C2800) : Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF7A3A10)
          : const Color(0xFFFFDBCC),
      onPrimaryContainer: isDark
          ? const Color(0xFFFFDBCC)
          : const Color(0xFF3D1600),
      secondary: isDark ? const Color(0xFFFFB59A) : secondary,
      onSecondary: isDark ? const Color(0xFF5C2A1A) : const Color(0xFF3D2218),
      surface: isDark ? const Color(0xFF1A120E) : const Color(0xFFFFF8F6),
      onSurface: isDark ? const Color(0xFFF6EDE8) : const Color(0xFF221913),
      outline: isDark ? const Color(0xFFA08B80) : const Color(0xFF85746C),
    );
    final radius = BorderRadius.circular(12);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
