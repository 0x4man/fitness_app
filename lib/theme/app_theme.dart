import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium dark palette — warm charcoal base with a coral → hot-pink
/// gradient and an electric lime accent. Deliberately avoids the
/// generic blue/indigo "AI SaaS" gradient in favor of a warmer,
/// higher-contrast athletic-brand feel (think Nike/Gymshark/Whoop).
class AppColors {
  // Base surfaces
  static const Color background =
      Color(0xFF0B0D11); // near-black, warm undertone
  static const Color surface = Color(0xFF16191F); // card background
  static const Color surfaceElevated = Color(0xFF1D2129); // sheets/dialogs
  static const Color surfaceBorder = Color(0xFF262B33);

  // Brand accents
  static const Color primary = Color(0xFFFF6B4A); // vivid coral
  static const Color primaryDark =
      Color(0xFFC7431F); // deep rust (shadows/gradient anchor)
  static const Color accent =
      Color(0xFFD4FF3D); // electric lime — energy/success/streak
  static const Color magenta =
      Color(0xFFFF3E7F); // hot pink — gradient partner & highlights

  // Text
  static const Color textPrimary = Color(0xFFF5F6F8);
  static const Color textSecondary = Color(0xFF9AA0AC);

  // Status
  static const Color error = Color(0xFFFF4D5E);
  static const Color cardShadow = Color(0x66000000);

  // Hero gradient used on CTA/branding elements — coral to hot pink.
  static const List<Color> heroGradient = [
    Color(0xFFFF6B4A),
    Color(0xFFFF3E7F),
  ];
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
