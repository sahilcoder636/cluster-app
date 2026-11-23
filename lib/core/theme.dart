import 'package:flutter/material.dart';

/// Central color palette, design tokens, and theme definitions for Cluster.
///
/// Features a printed editorial aesthetic with tactile depth:
/// - Light theme: paper (#F4EFE6), warm surface (#FBF8F2), ink (#1B1A17),
///   muted secondary (#6F6A5F), hairline borders (#D9D2C3), terracotta accent (#C2452D).
/// - Dark theme: warm charcoal bg (#171512), elevated surface (#211E1A),
///   cream ink (#EFE9DD), warm muted (#9E9789), hairline (#332F28), terracotta accent (#C2452D).
/// - Group colors (muted printed ink): mustard (#E0B04A), sage (#8FAF8A),
///   dusty blue (#7FA3C7), terracotta (#C77D6B).
/// - Typography: Fraunces for display (wordmark, headings, group titles),
///   Instrument Sans for UI and tiles.
class AppColors {
  AppColors._();

  // ── Light Theme Tokens ─────────────────────────────────────────
  static const Color paper = Color(0xFFF4EFE6);
  static const Color surfaceLight = Color(0xFFFBF8F2);
  static const Color ink = Color(0xFF1B1A17);
  static const Color muted = Color(0xFF6F6A5F);
  static const Color hairline = Color(0xFFD9D2C3);
  static const Color accentColor = Color(0xFFC2452D);

  // ── Group Colors (Muted Printed Ink) ───────────────────────────
  static const Color mustard = Color(0xFFD9B04C);
  static const Color sage = Color(0xFFA3C09B);
  static const Color dustyBlue = Color(0xFF8FB0CF);
  static const Color terracotta = Color(0xFFD9907F);

  // ── Dark Theme Tokens (Warm Charcoal) ──────────────────────────
  static const Color darkBg = Color(0xFF171512);
  static const Color darkSurface = Color(0xFF211E1A);
  static const Color darkInk = Color(0xFFEFE9DD);
  static const Color darkMuted = Color(0xFF9E9789);
  static const Color darkHairline = Color(0xFF332F28);
  static const Color darkAccent = Color(0xFFC2452D);

  // Darkened group hues for dark mode:
  static const Color darkMustard = Color(0xFFC69735);
  static const Color darkSage = Color(0xFF72936D);
  static const Color darkDustyBlue = Color(0xFF6488AC);
  static const Color darkTerracotta = Color(0xFFAF6351);

  // ── Compatibility Accessors ────────────────────────────────────
  static const Color background = paper;
  static const Color surface = surfaceLight;
  static const Color surfaceElevated = hairline;
  static const Color surfaceTile = Color(0xFFEAE4D9);

  static const Color onBackground = ink;
  static const Color onSurface = muted;
  static const Color onTile = ink;

  static const Color accent = accentColor;
  static const Color accentLight = Color(0xFFD96B54);
  static const Color tileSelected = ink;
  static const Color tileSelectedBorder = ink;

  static const Color diff1 = mustard;
  static const Color diff2 = sage;
  static const Color diff3 = dustyBlue;
  static const Color diff4 = terracotta;

  static const Color mistakeUsed = accentColor;
  static const Color mistakeEmpty = hairline;

  // Gradients
  static const Gradient streakGradient = LinearGradient(
    colors: [Color(0xFFC2452D), Color(0xFFD96B54)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient dailyGradient = LinearGradient(
    colors: [Color(0xFFFBF8F2), Color(0xFFF3ECE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Returns the fill color for a given difficulty (1-4).
  static Color difficultyColor(int difficulty, [Brightness brightness = Brightness.light]) {
    switch (difficulty) {
      case 1:
        return mustard;
      case 2:
        return sage;
      case 3:
        return dustyBlue;
      case 4:
        return terracotta;
      default:
        return mustard;
    }
  }

  /// Returns the emoji square for a given difficulty (1–4).
  static String difficultyEmoji(int difficulty) {
    switch (difficulty) {
      case 1:
        return '🟨';
      case 2:
        return '🟩';
      case 3:
        return '🟦';
      case 4:
        return '🟥';
      default:
        return '⬜';
    }
  }

  // ── Context Helpers ────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardBg(BuildContext context) =>
      isDark(context) ? darkSurface : surfaceLight;

  static Color textColor(BuildContext context) =>
      isDark(context) ? darkInk : ink;

  static Color mutedColor(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF332F28) : hairline;

  static Color tileBg(BuildContext context, {bool isSelected = false}) {
    if (isSelected) {
      return isDark(context) ? const Color(0xFF3B3327) : const Color(0xFF28241D);
    }
    return isDark(context) ? const Color(0xFF25211B) : const Color(0xFFFAF6EE);
  }

  static Color tileBorder(BuildContext context, {bool isSelected = false}) {
    if (isSelected) return accent;
    return isDark(context) ? const Color(0xFF3D362C) : const Color(0xFFD6CEBD);
  }

  static Color tileText(BuildContext context, {bool isSelected = false}) {
    if (isSelected) return Colors.white;
    return isDark(context) ? const Color(0xFFEDE5D5) : ink;
  }
}

/// Font family constants.
class AppFonts {
  AppFonts._();

  /// Display font for wordmark, headings, and group titles.
  static const String display = 'Fraunces';

  /// Clean, readable sans-serif for UI, buttons, body, and tiles.
  static const String ui = 'Instrument Sans';
}

/// Builds the light [ThemeData] (primary theme).
ThemeData buildLightTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.mustard,
    onSecondary: AppColors.ink,
    error: AppColors.terracotta,
    onError: Colors.white,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.ink,
    outline: AppColors.hairline,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.paper,
    fontFamily: AppFonts.ui,
    useMaterial3: true,

    // ── AppBar ──────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    ),

    // ── Card ────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.hairline, width: 1.5),
      ),
    ),

    // ── ElevatedButton ──────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppColors.accent.withValues(alpha: 0.35),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: AppColors.hairline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Typography ──────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.ink,
        fontSize: 44,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
      displayMedium: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.ink,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
      displaySmall: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.ink,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.ink,
        fontSize: 15,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.muted,
        fontSize: 13,
      ),
      labelLarge: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),

    // ── Divider ─────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.hairline,
      thickness: 1,
    ),

    // ── Dialog ──────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.hairline, width: 1.5),
      ),
    ),

    // ── SnackBar ────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.paper,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Builds the dark [ThemeData] (warm charcoal theme).
ThemeData buildDarkTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkAccent,
    onPrimary: Colors.white,
    secondary: AppColors.darkMustard,
    onSecondary: AppColors.darkInk,
    error: AppColors.darkTerracotta,
    onError: Colors.white,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkInk,
    outline: AppColors.darkHairline,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBg,
    fontFamily: AppFonts.ui,
    useMaterial3: true,

    // ── AppBar ──────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      foregroundColor: AppColors.darkInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.darkInk,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    ),

    // ── Card ────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF332F28), width: 1.5),
      ),
    ),

    // ── ElevatedButton ──────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.white,
        elevation: 3,
        shadowColor: AppColors.darkAccent.withValues(alpha: 0.4),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    ),

    // ── OutlinedButton ──────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkInk,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: Color(0xFF453E34), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── TextButton ──────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentLight,
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Typography ──────────────────────────────────────────────
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.darkInk,
        fontSize: 44,
        fontWeight: FontWeight.w900,
        letterSpacing: 3,
      ),
      displayMedium: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.darkInk,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
      displaySmall: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.darkInk,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.darkInk,
        fontSize: 22,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontFamily: AppFonts.display,
        color: AppColors.darkInk,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.darkInk,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.darkInk,
        fontSize: 15,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.darkMuted,
        fontSize: 13,
      ),
      labelLarge: TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.darkInk,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),

    // ── Divider ─────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: Color(0xFF332F28),
      thickness: 1,
    ),

    // ── Dialog ──────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurface,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF332F28), width: 1.5),
      ),
    ),

    // ── SnackBar ────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.darkSurface,
      contentTextStyle: const TextStyle(
        fontFamily: AppFonts.ui,
        color: AppColors.darkInk,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF332F28), width: 1.5),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Backward compatibility alias — returns the primary light theme.
ThemeData buildAppTheme() => buildLightTheme();
