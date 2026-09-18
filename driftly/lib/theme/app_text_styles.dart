import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Driftly typography — Fraunces for display headers, system font for body
class AppTextStyles {
  AppTextStyles._();

  static const String displayFontFamily = 'Fraunces';

  // ==================== Display (Fraunces) ====================
  //
  // Fraunces ships as a variable font (weight + optical-size axes). We
  // bundle one upright and one italic instance and select the specific
  // weight/optical-size via `fontVariations` rather than via separate
  // static files per weight.

  static const TextStyle displayLarge = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 72)],
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle displayLargeItalic = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 72)],
    color: AppColors.textPrimary,
    height: 1.15,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 36)],
    color: AppColors.textPrimary,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 36)],
    color: AppColors.textPrimary,
  );

  /// A display style with an italic run for a single emphasized word/phrase —
  /// build the TextSpan yourself and apply [displayItalicSpan] to that span.
  static const TextStyle displayItalicSpan = TextStyle(
    fontFamily: displayFontFamily,
    fontStyle: FontStyle.italic,
    fontVariations: [FontVariation('wght', 600), FontVariation('opsz', 36)],
  );

  // ==================== Body (system font) ====================

  static const TextStyle body = TextStyle(
    fontSize: 15,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  // ==================== Small Caps ====================
  //
  // Flutter's cross-platform support for true OpenType small-caps (the
  // `smcp` font feature) is inconsistent, especially with custom fonts on
  // Android. Instead we uppercase the string and use wide letter-spacing,
  // which reproduces the tracked-out label look seen throughout the design
  // ("STEP 1 OF 3", "DAY 1 · CARIBBEAN", "INTERESTS", etc.) reliably on
  // every platform.

  static TextStyle smallCaps({
    Color color = AppColors.textSecondary,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: 2.2,
    );
  }
}
