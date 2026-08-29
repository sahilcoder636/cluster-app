import 'package:flutter/material.dart';

/// Central color palette and theme for Cluster.
///
/// Dark-first design: deep navy background, muted surfaces,
/// vivid difficulty colors, indigo accent.
class AppColors {
  AppColors._();

  // ── Background layers ──────────────────────────────────────────
  static const Color background = Color(0xFF0D0D1F);
  static const Color surface = Color(0xFF16162A);
  static const Color surfaceElevated = Color(0xFF1F1F38);
  static const Color surfaceTile = Color(0xFF252547);

  // ── Text ───────────────────────────────────────────────────────
  static const Color onBackground = Color(0xFFE8E8F5);
  static const Color onSurface = Color(0xFFB0B0CC);
  static const Color onTile = Color(0xFFFFFFFF);

  // ── Accent ─────────────────────────────────────────────────────
  static const Color accent = Color(0xFF7B6CF6);
  static const Color accentLight = Color(0xFF9D91F8);
  static const Color tileSelected = Color(0xFF5C54D4);
  static const Color tileSelectedBorder = Color(0xFF7B6CF6);

  // ── Difficulty colors ──────────────────────────────────────────
  /// Difficulty 1 → green
  static const Color diff1 = Color(0xFF4CAF50);

  /// Difficulty 2 → blue
  static const Color diff2 = Color(0xFF2196F3);

  /// Difficulty 3 → amber/yellow
  static const Color diff3 = Color(0xFFFFC107);

  /// Difficulty 4 → red
  static const Color diff4 = Color(0xFFEF5350);

  // ── Mistakes ───────────────────────────────────────────────────
  static const Color mistakeUsed = Color(0xFFEF5350);
  static const Color mistakeEmpty = Color(0xFF3A3A5C);

  // ── Streak card gradient ───────────────────────────────────────
  static const Gradient streakGradient = LinearGradient(
    colors: [Color(0xFF7B6CF6), Color(0xFFB06CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Daily card gradient ────────────────────────────────────────
  static const Gradient dailyGradient = LinearGradient(
    colors: [Color(0xFF1F1F38), Color(0xFF2A2A50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the fill color for a given difficulty (1–4).
  static Color difficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return diff1;
      case 2:
        return diff2;
      case 3:
        return diff3;
      case 4:
        return diff4;
      default:
        return diff1;
    }
  }

  /// Returns the emoji square for a given difficulty (1–4).
  static String difficultyEmoji(int difficulty) {
    switch (difficulty) {
      case 1:
        return '🟩';
      case 2:
        return '🟦';
      case 3:
        return '🟨';
      case 4:
        return '🟥';
      default:
        return '⬜';
    }
  }
}

/// Builds the app-wide [ThemeData].
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.accentLight,
    onSecondary: Colors.white,
    error: AppColors.diff4,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,

    // ── AppBar ──────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onBackground,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.onBackground,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    ),

    // ── Card ────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ── ElevatedButton ──────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accentLight),
    ),

    // ── Text ────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.onBackground,
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
      ),
      displayMedium: TextStyle(
        color: AppColors.onBackground,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
      titleLarge: TextStyle(
        color: AppColors.onBackground,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: AppColors.onBackground,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AppColors.onSurface, fontSize: 15),
      bodyMedium: TextStyle(color: AppColors.onSurface, fontSize: 13),
      labelLarge: TextStyle(
        color: AppColors.onBackground,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),

    // ── Divider ─────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2A2A48),
      thickness: 1,
    ),

    // ── SnackBar ─────────────────────────────────────────────────
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      contentTextStyle: TextStyle(color: AppColors.onBackground),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
