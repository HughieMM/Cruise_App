import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

enum PillVariant { filled, outlined }

/// Which roundness convention to use — the design uses two: fully-rounded
/// pills (gender toggles, interest chips, CTA buttons) and moderately
/// -rounded chips (age band, cruise duration, discover-pod rows).
enum PillShape { pill, chip }

/// Shared button used for every rounded control in the redesign: filled CTAs
/// ("Board the Ship", "Add Photos"), outlined actions ("Join", "+ Join with a
/// Friend"), and selectable toggle rows (Gender, Age Band, Interests).
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final PillShape shape;
  final Color color;

  /// Only used for [PillVariant.filled] — defaults to black, matching the
  /// design's teal/amber-pill-with-black-text convention.
  final Color textColor;
  final IconData? icon;
  final String? emoji;
  final bool dashed;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillVariant.filled,
    this.shape = PillShape.pill,
    this.color = AppColors.teal,
    this.textColor = Colors.black,
    this.icon,
    this.emoji,
    this.dashed = false,
  });

  double get _radius =>
      shape == PillShape.pill ? AppConstants.pillRadius : AppConstants.cardBorderRadius;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: _foreground(disabled)),
          const SizedBox(width: 8),
        ],
        if (emoji != null) ...[
          Text(emoji!, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            color: _foreground(disabled),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );

    final button = Material(
      color: _background(disabled),
      shape: dashed
          ? null
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_radius),
              side: variant == PillVariant.outlined
                  ? BorderSide(color: _borderColor(disabled))
                  : BorderSide.none,
            ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(widthFactor: 1, child: content),
        ),
      ),
    );

    if (!dashed) return button;

    return CustomPaint(
      painter: _DashedBorderPainter(
        color: _borderColor(disabled),
        radius: _radius,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: button,
      ),
    );
  }

  Color _background(bool disabled) {
    if (variant == PillVariant.outlined) return Colors.transparent;
    if (disabled) return Colors.grey.withValues(alpha: 0.2);
    return color;
  }

  Color _foreground(bool disabled) {
    if (disabled) return Colors.grey;
    if (variant == PillVariant.outlined) return color;
    return textColor;
  }

  Color _borderColor(bool disabled) {
    if (disabled) return Colors.grey.withValues(alpha: 0.4);
    return color.withValues(alpha: 0.6);
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius > size.height ? size.height / 2 : radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
