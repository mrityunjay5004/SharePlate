import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // SharePlate Signature Palette
  static const Color primaryGreen = Color(0xFF1B5E3C);
  static const Color primaryGreenDark = Color(0xFF0F3E26);
  static const Color primaryGreenLight = Color(0xFF388E5E);
  static const Color primaryGreenContainer = Color(0xFFD4ECD8);
  static const Color onPrimaryGreenContainer = Color(0xFF09371D);

  static const Color creamBackground = Color(0xFFFBF9F5);
  static const Color creamSurface = Color(0xFFFFFFFF);
  static const Color creamCard = Color(0xFFFFFFFF);
  static const Color creamAccent = Color(0xFFF3EEE2);
  static const Color creamBorder = Color(0xFFE5DFD1);

  static const Color amberUrgent = Color(0xFFD97706);
  static const Color amberUrgentBg = Color(0xFFFEF3C7);
  static const Color redCritical = Color(0xFFDC2626);
  static const Color redCriticalBg = Color(0xFFFEE2E2);
  static const Color blueInfo = Color(0xFF0284C7);
  static const Color blueInfoBg = Color(0xFFE0F2FE);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: primaryGreenContainer,
      onPrimaryContainer: onPrimaryGreenContainer,
      secondary: const Color(0xFF5D7A68),
      secondaryContainer: creamAccent,
      onSecondaryContainer: const Color(0xFF263D2E),
      surface: creamSurface,
      onSurface: const Color(0xFF1C241E),
      onSurfaceVariant: const Color(0xFF536357),
      outline: const Color(0xFFB8C2B8),
      outlineVariant: creamBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: creamBackground,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: creamSurface,
        foregroundColor: const Color(0xFF14291B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withAlpha(12),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF14291B),
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: creamCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: creamBorder, width: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: creamBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: creamBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 1.8),
        ),
        filled: true,
        fillColor: creamSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: primaryGreen, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
    );
  }
}
