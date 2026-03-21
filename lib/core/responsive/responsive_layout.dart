import 'package:flutter/material.dart';

/// Responsive breakpoints and layout utilities.
///
/// Usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileView(),
///   tablet: TabletView(),   // optional
/// )
///
/// // Or via extension:
/// if (context.isMobile) { ... }
/// final cols = context.responsiveGridColumns;
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= mobileBreakpoint && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

/// Extension methods for responsive queries on BuildContext.
extension ResponsiveExtension on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < ResponsiveLayout.mobileBreakpoint;
  bool get isTablet =>
      screenWidth >= ResponsiveLayout.mobileBreakpoint &&
      screenWidth < ResponsiveLayout.tabletBreakpoint;
  bool get isDesktop => screenWidth >= ResponsiveLayout.tabletBreakpoint;

  /// Grid columns: 3 on mobile, 4 on small tablet, 5 on large tablet.
  int get responsiveGridColumns {
    if (screenWidth >= 900) return 5;
    if (screenWidth >= ResponsiveLayout.mobileBreakpoint) return 4;
    return 3;
  }

  /// Screen horizontal padding: 20 on mobile, 32 on tablet.
  double get responsivePadding {
    if (screenWidth >= ResponsiveLayout.mobileBreakpoint) return 32;
    return 20;
  }
}
