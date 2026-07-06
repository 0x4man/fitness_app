import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Viora" premium dark palette — deep charcoal base with a heavy
/// burgundy/maroon accent. Deliberately avoids bright "fitness-app
/// standard" colors in favor of a weightier, more elite feel (think
/// premium athletic gear rather than a generic SaaS gradient).
class AppColors {
  // Base surfaces
  static const Color background = Color(0xFF090B0D); // deep charcoal
  static const Color surface = Color(0xFF15171B); // card background
  static const Color surfaceElevated = Color(0xFF1C1F24); // sheets/dialogs
  static const Color surfaceBorder =
      Color(0xFF2A2C30); // subtle ~10%-white-on-charcoal edge

  // Brand accents
  static const Color primary = Color(0xFF7A1E1E); // deep burgundy/maroon
  static const Color primaryDark =
      Color(0xFF3D0F0F); // near-black maroon (gradient/shadow anchor)
  static const Color accent =
      Color(0xFFC9A227); // muted gold — success/streak, premium not flashy
  static const Color magenta =
      Color(0xFF8C2F3A); // deep rose — secondary highlight, same family

  // Text
  static const Color textPrimary = Color(0xFFF4F4F4); // off-white
  static const Color textSecondary = Color(0xFF888888); // soft grey

  // Status
  static const Color error = Color(0xFFE5484D);
  static const Color cardShadow = Color(0x80000000);

  // Hero gradient used on CTA/branding elements — burgundy anchoring
  // into the charcoal background, so cards feel grounded rather than
  // floating on top of the page.
  static const List<Color> heroGradient = [
    Color(0xFF7A1E1E),
    Color(0xFF090B0D),
  ];
}

/// Reusable text style helpers that encode the app's typographic
/// hierarchy: muted, letter-spaced labels vs. bold, tight-kerned
/// values. Use these instead of ad-hoc TextStyles so every screen
/// stays visually consistent.
class AppTypography {
  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      );

  static TextStyle get value => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      );

  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );
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
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme)
              .apply(
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
          textStyle: GoogleFonts.plusJakartaSans(
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
