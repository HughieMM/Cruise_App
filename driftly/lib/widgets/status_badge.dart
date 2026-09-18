import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/constants.dart';

/// Hangout status: drives the color of [StatusBadge].
enum HangoutStatus { now, soon, tomorrow }

extension HangoutStatusLabel on HangoutStatus {
  String get label {
    switch (this) {
      case HangoutStatus.now:
        return 'NOW';
      case HangoutStatus.soon:
        return 'SOON';
      case HangoutStatus.tomorrow:
        return 'TOMORROW';
    }
  }

  Color get color => AppConstants.hangoutStatusColors[label] ?? AppColors.teal;
}

/// Small solid pill badge overlaid on hangout photo cards — "NOW" (coral),
/// "SOON" (amber), "TOMORROW" (teal). Also usable as a generic tag (e.g.
/// Home's "🔥 TONIGHT · HOT") via the custom [label]/[color] constructor.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor = Colors.black,
  });

  factory StatusBadge.forStatus(HangoutStatus status) {
    return StatusBadge(label: status.label, color: status.color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.smallCaps(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
