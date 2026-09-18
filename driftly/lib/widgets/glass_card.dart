import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Glass card widget with translucent, optionally-blurred background
/// Used across Home, Profile, Tribe and Hangouts tabs for a consistent
/// frosted-glass look. Pass [borderColor]/[tintColor] for the teal/coral/amber
/// -bordered variants seen throughout the design; leave them unset for the
/// neutral white-tinted glass look.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? tintColor;

  /// Skip the backdrop blur when the card sits over a flat solid background
  /// (no visible effect there, and blurring is not free). Keep it enabled
  /// when the card overlays a photo or gradient.
  final bool showBlur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.tintColor,
    this.showBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: tintColor ?? AppColors.glassTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1,
        ),
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (!showBlur) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: content,
      ),
    );
  }
}
