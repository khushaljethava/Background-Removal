import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Neon Laboratory typography tokens.
///
/// - **Syne**: Display, headlines, titles (premium branding, geometric character)
/// - **DM Sans**: Body text (highly readable humanist sans-serif)
/// - **JetBrains Mono**: Labels, metadata, stats (technical data, uppercase)
///
/// Labels should be used with `.toUpperCase()` at the call site.
abstract final class AppTypography {
  static TextTheme get textTheme => TextTheme(
        // --- Display (Syne, extrabold, tight tracking) ---
        displayLarge: GoogleFonts.syne(
          fontSize: 48,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.96,
          height: 1.1,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.syne(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.72,
          height: 1.15,
          color: AppColors.textPrimary,
        ),

        // --- Headlines (Syne, bold) ---
        headlineLarge: GoogleFonts.syne(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.syne(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          height: 1.2,
          color: AppColors.textPrimary,
        ),
        headlineSmall: GoogleFonts.syne(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.25,
          color: AppColors.textPrimary,
        ),

        // --- Titles (Syne, semibold-bold) ---
        titleLarge: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.3,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AppColors.textPrimary,
        ),
        titleSmall: GoogleFonts.jetBrainsMono(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          height: 1.4,
          color: AppColors.textMuted,
        ),

        // --- Body (DM Sans — readable humanist sans-serif) ---
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.55,
          color: AppColors.textPrimary,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.textMuted,
        ),

        // --- Labels (JetBrains Mono, moderate tracking) ---
        labelLarge: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          height: 1.4,
          color: AppColors.textPrimary,
        ),
        labelMedium: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
          height: 1.4,
          color: AppColors.textMuted,
        ),
        labelSmall: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.4,
          color: AppColors.textMuted,
        ),
      );
}
