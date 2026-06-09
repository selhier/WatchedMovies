import 'dart:ui';

/// WatchedMovies Premium Color Palette — "Midnight Cinema"
/// A sophisticated dark theme with warm gold accents
class AppColors {
  AppColors._();

  // ─── Primary Brand ────────────────────────────────────────
  static const Color primary = Color(0xFFE8B800);        // Rich gold
  static const Color primaryLight = Color(0xFFFFD54F);   // Light gold
  static const Color primaryDark = Color(0xFFB8860B);    // Dark gold
  static const Color primarySurface = Color(0x1AE8B800); // Gold at 10% opacity

  // ─── Backgrounds ──────────────────────────────────────────
  static const Color background = Color(0xFF0A0A0F);     // Deep midnight
  static const Color surface = Color(0xFF12121A);         // Card surface
  static const Color surfaceLight = Color(0xFF1A1A28);   // Elevated surface
  static const Color surfaceHighlight = Color(0xFF222236); // Highlight surface

  // ─── Text ─────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF9E9EB8);
  static const Color textTertiary = Color(0xFF6B6B80);
  static const Color textOnPrimary = Color(0xFF0A0A0F);

  // ─── Status Colors ────────────────────────────────────────
  static const Color watched = Color(0xFF4CAF50);         // Green - Watched
  static const Color pending = Color(0xFF42A5F5);         // Blue - Pending
  static const Color abandoned = Color(0xFFEF5350);       // Red - Abandoned
  static const Color error = Color(0xFFEF5350);           // Red - Error / Likes
  static const Color watching = Color(0xFFAB47BC);        // Purple - Watching

  // ─── Rating Colors ────────────────────────────────────────
  static const Color ratingHigh = Color(0xFF66BB6A);      // 8-10
  static const Color ratingMedium = Color(0xFFFFCA28);    // 5-7
  static const Color ratingLow = Color(0xFFEF5350);       // 1-4

  // ─── Misc ─────────────────────────────────────────────────
  static const Color divider = Color(0xFF2A2A3E);
  static const Color shimmerBase = Color(0xFF1A1A28);
  static const Color shimmerHighlight = Color(0xFF2A2A3E);
  static const Color overlay = Color(0xCC000000);         // 80% black
  static const Color scrim = Color(0x80000000);           // 50% black

  /// Returns a color based on the movie score (1-10)
  static Color scoreColor(int score) {
    if (score >= 8) return ratingHigh;
    if (score >= 5) return ratingMedium;
    return ratingLow;
  }

  /// Returns a color based on movie status
  static Color statusColor(String status) {
    switch (status) {
      case 'watched':
        return watched;
      case 'pending':
        return pending;
      case 'abandoned':
        return abandoned;
      case 'watching':
        return watching;
      default:
        return textSecondary;
    }
  }
}
