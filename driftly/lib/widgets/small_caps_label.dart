import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Tracked-out, uppercased label text — "STEP 1 OF 3", "DAY 1 · CARIBBEAN",
/// "INTERESTS", "ACCOUNT", etc. See [AppTextStyles.smallCaps] for why this
/// is implemented as uppercase + letter-spacing rather than true small-caps.
class SmallCapsLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  const SmallCapsLabel(
    this.text, {
    super.key,
    this.color = AppColors.textSecondary,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.smallCaps(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
