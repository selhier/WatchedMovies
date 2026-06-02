import 'package:flutter/material.dart';

/// Helper class for responsive design breakpoints and utilities
class ResponsiveHelper {
  ResponsiveHelper._();

  // ─── Breakpoints ──────────────────────────────────────────
  static const double mobileMaxSize = 600;
  static const double tabletMaxSize = 900;
  static const double desktopMinSize = 901;

  // ─── Device Type Checkers ──────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMaxSize;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > mobileMaxSize &&
      MediaQuery.of(context).size.width <= tabletMaxSize;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopMinSize;

  // ─── Grid Helpers ──────────────────────────────────────────
  static int getGridCrossAxisCount(BuildContext context, {int mobile = 3, int tablet = 4, int desktop = 6}) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
