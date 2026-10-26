import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors (From your image)
  static const lightPrimary = Color(0xFF2D5A3D); // Deep Leaf Green
  static const lightBg = Color(0xFFF9FBF9); // Off-white
  static const lightSurface = Colors.white; // Pure white card
  static const lightInput = Color(0xFFDDE9DE); // Mint input fill
  static const lightText = Color(0xFF1A2E1F); // Very dark green text
  static const lightTextMuted = Color(0xFF7A8D7F); // Muted green text

  // Dark Theme Colors (Adapted)
  static const darkPrimary = Color(0xFF4A8265); // Lighter green for contrast
  static const darkBg = Color(0xFF101913); // Very dark green/black
  static const darkSurface = Color(0xFF1B2A20); // Dark card background
  static const darkInput = Color(0xFF233B2B); // Dark mint input
  static const darkText = Color(0xFFE8F0EA); // Soft white text
  static const darkTextMuted = Color(0xFF8DA695); // Muted gray-green

  static const danger = Color(0xFFE63946);
  static const success = Color(0xFF2A9D8F);

  // Legacy aliases for other screens (will map to light by default)
  static const primary = lightPrimary;
  static const primaryLight = Color(0xFF4A8265);
  static const accent = lightPrimary;
  static const bg = lightBg;
  static const surface = lightSurface;
  static const textMain = lightText;
  static const textMuted = lightTextMuted;
  static const forest = lightPrimary;
  static const leaf = lightPrimary;
  static const mint = lightInput;
  static const ink = lightText;
  static const inkMuted = lightTextMuted;
  static const white = Colors.white;
  static const cream = lightBg;
  static const gold = lightPrimary;
}

ThemeData buildTheme(bool isDark) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
  );

  return base.copyWith(
    scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
    colorScheme: base.colorScheme.copyWith(
      primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      secondary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      error: AppColors.danger,
    ),
    textTheme: base.textTheme.apply(
        bodyColor: isDark ? AppColors.darkText : AppColors.lightText,
        displayColor: isDark ? AppColors.darkText : AppColors.lightText),
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(
          color: isDark ? AppColors.darkText : AppColors.lightText),
      titleTextStyle: TextStyle(
        color: isDark ? AppColors.darkText : AppColors.lightText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkInput : AppColors.lightInput,
      hintStyle: TextStyle(
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          fontSize: 14),
      prefixIconColor:
          isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      suffixIconColor:
          isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(
            color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            width: 2),
      ),
    ),
  );
}
