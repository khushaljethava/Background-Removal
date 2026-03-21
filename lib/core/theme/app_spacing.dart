import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Spacing scale and layout constants for consistent sizing across the app.
abstract final class AppSpacing {
  // --- Spacing scale (4px base) ---
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  // --- Border radius ---
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 24;
  static const double radiusRound = 28;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusXxl => BorderRadius.circular(radiusXxl);
  static BorderRadius get borderRadiusRound => BorderRadius.circular(radiusRound);

  // --- Common EdgeInsets ---
  static const EdgeInsets paddingAllSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingAllMd = EdgeInsets.all(md);
  static const EdgeInsets paddingAllLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingAllXl = EdgeInsets.all(xl);
  static const EdgeInsets paddingAllXxl = EdgeInsets.all(xxl);

  static const EdgeInsets paddingHorizontalXl =
      EdgeInsets.symmetric(horizontal: xl);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);

  static const EdgeInsets screenPadding = EdgeInsets.all(xl);
  static const EdgeInsets cardPadding = EdgeInsets.all(xl);

  // --- Neon Laboratory: Glow & blur constants ---
  static const double glowBlurRadius = 24.0;
  static const double glowOpacity = 0.08;
  static const double ghostBorderOpacity = 0.20;
  static const double radiusFull = 999.0; // Pill shapes
  static const double radiusSheet = 32.0; // Bottom sheets

  static BorderRadius get borderRadiusFull => BorderRadius.circular(radiusFull);
  static BorderRadius get borderRadiusSheet => BorderRadius.circular(radiusSheet);
}

/// Responsive sizing utilities that scale based on screen dimensions.
///
/// Usage: `final s = ResponsiveSize.of(context);`
class ResponsiveSize {
  final double width;
  final double height;

  ResponsiveSize._(this.width, this.height);

  factory ResponsiveSize.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ResponsiveSize._(size.width, size.height);
  }

  // Scale factor: 1.0 at 375dp (iPhone SE), scales proportionally.
  double get _wScale => (width / 375).clamp(0.8, 1.4);
  double get _hScale => (height / 812).clamp(0.75, 1.3);

  // --- Responsive button padding ---
  EdgeInsets get buttonPadding => EdgeInsets.symmetric(
        vertical: (14 * _wScale).roundToDouble(),
        horizontal: (24 * _wScale).roundToDouble(),
      );

  EdgeInsets get buttonPaddingCompact => EdgeInsets.symmetric(
        vertical: (10 * _wScale).roundToDouble(),
        horizontal: (16 * _wScale).roundToDouble(),
      );

  // --- Responsive icon button size ---
  double get iconButtonSize => (40 * _wScale).clamp(36, 52).roundToDouble();
  double get iconButtonPadding =>
      (12 * _wScale).clamp(8, 16).roundToDouble();

  // --- Responsive font sizes ---
  double get buttonFontSize => (14 * _wScale).clamp(12, 17).roundToDouble();
  double get labelFontSize => (12 * _wScale).clamp(10, 15).roundToDouble();

  // --- Responsive upload zone padding ---
  double get uploadZonePadding =>
      (math.min(width, height) * 0.08).clamp(24, 48).roundToDouble();

  // --- Responsive image preview height ---
  double get imagePreviewHeight =>
      (height * 0.25 * _hScale).clamp(140, 280).roundToDouble();

  // --- Responsive screen padding ---
  EdgeInsets get screenPadding => EdgeInsets.all(
        (16 * _wScale).clamp(12, 24).roundToDouble(),
      );

  // --- Responsive horizontal padding ---
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(
        horizontal: (20 * _wScale).clamp(14, 28).roundToDouble(),
      );

  // --- Small screen detection ---
  bool get isCompact => width < 360;
  bool get isShort => height < 680;
}
