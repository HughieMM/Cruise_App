import 'package:flutter/material.dart';

/// Driftly design tokens — navy/teal/coral/amber palette
///
/// Single source of truth for the app's color palette. Screens should
/// reference these instead of hardcoding hex values, so the whole app
/// stays visually consistent and easy to re-tune.
class AppColors {
  AppColors._();

  // ==================== Core Palette ====================

  static const Color background = Color(0xFF030C1A);

  /// Card surface — rgba(10,22,40,0.6)
  static const Color surface = Color(0x990A1628);

  /// Non-transparent fallback for surfaces that shouldn't blur/composite
  static const Color surfaceSolid = Color(0xFF0A1628);

  static const Color teal = Color(0xFF2DD4BF);
  static const Color coral = Color(0xFFFF6B47);
  static const Color amber = Color(0xFFFFAA3B);

  /// Casino/high-roller accent — used for the High Rollers pod.
  static const Color gold = Color(0xFFD4AF37);

  /// Coldest stop on the Hot Zones vibe gradient ("Taking an L").
  static const Color frost = Color(0xFF5AC8FA);

  /// Neon glassy pink — used for Profile's Achievement Badges/My Sailing.
  static const Color pink = Color(0xFFFF2E9A);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAEB6C2);

  static const Color divider = Colors.white12;

  // ==================== Derived Tints & Borders ====================
  //
  // Used for the colored-glass-card look (teal/coral/amber-bordered cards
  // with a faint matching tint behind them).

  static Color tealTint = teal.withValues(alpha: 0.12);
  static Color tealBorder = teal.withValues(alpha: 0.4);

  static Color coralTint = coral.withValues(alpha: 0.12);
  static Color coralBorder = coral.withValues(alpha: 0.4);

  static Color amberTint = amber.withValues(alpha: 0.12);
  static Color amberBorder = amber.withValues(alpha: 0.4);

  static Color goldTint = gold.withValues(alpha: 0.12);
  static Color goldBorder = gold.withValues(alpha: 0.4);

  static Color frostTint = frost.withValues(alpha: 0.12);
  static Color frostBorder = frost.withValues(alpha: 0.4);

  static Color pinkTint = pink.withValues(alpha: 0.16);
  static Color pinkBorder = pink.withValues(alpha: 0.5);

  static Color glassTint = Colors.white.withValues(alpha: 0.1);
  static Color glassBorder = Colors.white.withValues(alpha: 0.2);
}
