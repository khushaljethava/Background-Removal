import 'package:flutter/material.dart';

/// Neon Laboratory design system color tokens.
///
/// All colors used in the app should reference these constants
/// rather than hardcoding hex values in widgets.
abstract final class AppColors {
  // --- Brand / Primary (Cyan) ---
  static const Color primary = Color(0xFFC3F5FF); // Light cyan (text on dark)
  static const Color primaryContainer = Color(0xFF00E5FF); // Bright cyan (CTAs, accents)
  static const Color primaryFixedDim = Color(0xFF00DAF3); // Teal variant
  static const Color onPrimary = Color(0xFF00363D); // Dark text on primary
  static const Color onPrimaryContainer = Color(0xFF00626E);

  // --- Secondary (Coral) ---
  static const Color secondary = Color(0xFFFFBB9D); // Coral accent
  static const Color secondaryContainer = Color(0xFFFF6B35); // Vibrant orange (destructive only)
  static const Color onSecondary = Color(0xFF3E1500);

  // --- Tertiary (Mint) ---
  static const Color tertiary = Color(0xFFA4FFD1); // Mint green
  static const Color tertiaryContainer = Color(0xFF1FECA6); // Bright mint
  static const Color tertiaryFixedDim = Color(0xFF00E29E);
  static const Color onTertiary = Color(0xFF003822);

  // --- Neon Laboratory Surfaces ---
  // Slightly warm-tinted darks for better perceived depth vs pure grey
  static const Color background = Color(0xFF0F1214); // Deep near-black with blue tint
  static const Color surface = Color(0xFF0F1214); // Level 0
  static const Color surfaceContainerLow = Color(0xFF181A1E);
  static const Color surfaceContainer = Color(0xFF1E2024); // Level 1 (cards)
  static const Color surfaceHigh = Color(0xFF272A2F); // Level 2 (interactions)
  static const Color surfaceHighest = Color(0xFF323538); // Level 3
  static const Color surfaceBright = Color(0xFF3C3F43); // Modals

  /// Alias for surfaceContainer (backwards compatibility).
  static const Color card = surfaceContainer;

  // --- Text ---
  static const Color textPrimary = Color(0xFFF1F3F5); // Brighter white for better contrast
  static const Color textMuted = Color(0xFF94A3B8); // Slate-400 — readable on dark surfaces

  // --- Outline / Borders (ghost borders) ---
  static const Color outline = Color(0xFF849396);
  static const Color outlineVariant = Color(0xFF3B494C);

  // --- Semantic ---
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFFFF5252);
  static const Color success = Color(0xFF1FECA6); // = tertiaryContainer
  static const Color warning = Color(0xFFFFB74D);

  // --- Dark ColorScheme ---
  static ColorScheme get darkColorScheme => const ColorScheme.dark(
        primary: primaryContainer,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        surface: surface,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceHigh,
        surfaceContainerHighest: surfaceHighest,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onSurface: textPrimary,
        onSurfaceVariant: textMuted,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        onError: Colors.white,
      );

  // --- Light theme colors ---
  // Tinted cool-white surfaces that complement the cyan accent
  static const Color lightBackground = Color(0xFFF8FAFB);
  static const Color lightSurface = Color(0xFFF8FAFB);
  static const Color lightSurfaceContainerLow = Color(0xFFF1F4F6);
  static const Color lightSurfaceContainer = Color(0xFFEBEEF2);
  static const Color lightSurfaceHigh = Color(0xFFE1E5EA);
  static const Color lightSurfaceHighest = Color(0xFFD4D9E0);
  static const Color lightOnSurface = Color(0xFF0F1419);
  static const Color lightOnSurfaceVariant = Color(0xFF4A5568);
  static const Color lightOutline = Color(0xFF8E99A4);
  static const Color lightOutlineVariant = Color(0xFFCBD2DA);

  // Darker cyan for light mode — ensures 4.5:1 contrast on white
  static const Color lightPrimary = Color(0xFF0097A7);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);

  // --- Light ColorScheme ---
  static ColorScheme get lightColorScheme => ColorScheme.light(
        primary: lightPrimary,
        primaryContainer: const Color(0xFF00BCD4),
        onPrimaryContainer: const Color(0xFF00363D),
        secondary: const Color(0xFFE65100),
        secondaryContainer: const Color(0xFFFFCCBC),
        tertiary: const Color(0xFF00897B),
        tertiaryContainer: const Color(0xFFB2DFDB),
        surface: lightSurface,
        surfaceContainerLow: lightSurfaceContainerLow,
        surfaceContainer: lightSurfaceContainer,
        surfaceContainerHigh: lightSurfaceHigh,
        surfaceContainerHighest: lightSurfaceHighest,
        onPrimary: lightOnPrimary,
        onSecondary: Colors.white,
        onSurface: lightOnSurface,
        onSurfaceVariant: lightOnSurfaceVariant,
        outline: lightOutline,
        outlineVariant: lightOutlineVariant,
        error: const Color(0xFFD32F2F),
        onError: Colors.white,
      );
}
