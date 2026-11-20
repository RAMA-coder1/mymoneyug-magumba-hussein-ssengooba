import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette taken from the sketches: navy headers, pale-blue action areas.
class AppColors {
  static const navy = Color(0xFF1A3A5C);
  static const paleBlue = Color(0xFFC8E4EC);
  static const surface = Color(0xFFF6F8FC);
  static const income = Color(0xFF1B7F4B);
  static const expense = Color(0xFFB3261E);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondaryContainer: AppColors.paleBlue,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: GoogleFonts.inter().fontFamily,
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
      fillColor: Colors.white,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      indicatorColor: AppColors.paleBlue,
      backgroundColor: Colors.white,
    ),
  );
}
