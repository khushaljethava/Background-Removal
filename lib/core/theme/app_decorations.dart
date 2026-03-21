import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

/// Shared decoration helpers for the Neon Laboratory design system.
///
/// **Static methods** use dark-mode colors directly (for use in initState, etc.)
/// **Context-aware methods** (prefixed with `of`) adapt to light/dark theme.
abstract final class AppDecorations {
  /// Ambient glow — the signature Neon Laboratory elevation effect.
  static List<BoxShadow> ambientGlow({
    Color? color,
    double blurRadius = 24,
    double opacity = 0.08,
  }) =>
      [
        BoxShadow(
          color: (color ?? AppColors.primaryContainer).withOpacity(opacity),
          blurRadius: blurRadius,
          spreadRadius: 0,
        ),
      ];

  /// Ghost border — subtle boundary without hard lines.
  static Border ghostBorder({
    double opacity = 0.20,
    double width = 1,
  }) =>
      Border.all(
        color: AppColors.outlineVariant.withOpacity(opacity),
        width: width,
      );

  /// Context-aware ghost border — uses colorScheme.outlineVariant.
  static Border ghostBorderOf(BuildContext context, {
    double opacity = 0.30,
    double width = 1,
  }) =>
      Border.all(
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(opacity),
        width: width,
      );

  /// Surface card decoration (dark mode default).
  static BoxDecoration surfaceCard({
    double radius = AppSpacing.radiusXl,
    Color? backgroundColor,
    bool withGlow = true,
  }) =>
      BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        border: ghostBorder(),
        boxShadow: withGlow ? ambientGlow() : null,
      );

  /// Context-aware surface card — adapts to light/dark theme.
  static BoxDecoration surfaceCardOf(BuildContext context, {
    double radius = AppSpacing.radiusXl,
    Color? backgroundColor,
    bool withGlow = true,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: backgroundColor ?? (isDark ? cs.surfaceContainer : Colors.white),
      borderRadius: BorderRadius.circular(radius),
      border: ghostBorderOf(context, opacity: isDark ? 0.20 : 0.40),
      boxShadow: withGlow
          ? (isDark
              ? ambientGlow()
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ])
          : null,
    );
  }

  /// Glass decoration — for glassmorphism overlays.
  static BoxDecoration glassCard({
    double radius = AppSpacing.radiusXl,
    double bgOpacity = 0.6,
  }) =>
      BoxDecoration(
        color: AppColors.surfaceContainer.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(radius),
        border: ghostBorder(opacity: 0.10),
      );

  /// Selected item decoration.
  static BoxDecoration selectedCard({
    double radius = AppSpacing.radiusXl,
  }) =>
      BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.primaryContainer.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: ambientGlow(opacity: 0.15),
      );

  /// Thermal gradient — the cyan-to-mint gradient for primary CTAs.
  static LinearGradient get thermalGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryContainer,
          AppColors.tertiaryContainer,
        ],
      );

  /// Thermal gradient for light mode — darker for contrast.
  static LinearGradient get thermalGradientLight => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.lightPrimary,
          Color(0xFF00897B),
        ],
      );

  /// Context-aware thermal gradient.
  static LinearGradient thermalGradientOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? thermalGradient
          : thermalGradientLight;

  /// Cold gradient — cyan tones for logo/branding.
  static LinearGradient get coldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryContainer,
          Color(0xFF00B8D4),
        ],
      );

  /// Context-aware cold gradient.
  static LinearGradient coldGradientOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? coldGradient
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lightPrimary,
                Color(0xFF00838F),
              ],
            );
}
