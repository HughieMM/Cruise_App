import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Circular avatar with a progress arc traced around it and an optional
/// small percentage badge — used for Profile's completion indicator.
class AvatarWithProgressRing extends StatelessWidget {
  final String? imageUrl;
  final String fallbackInitial;
  final double percent; // 0.0 - 1.0
  final Color ringColor;
  final double size;
  final bool showBadge;

  const AvatarWithProgressRing({
    super.key,
    this.imageUrl,
    required this.fallbackInitial,
    required this.percent,
    this.ringColor = AppColors.teal,
    this.size = 100,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingPainter(percent: percent, color: ringColor),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: CircleAvatar(
                backgroundColor: AppColors.surfaceSolid,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl!) : null,
                child: imageUrl == null
                    ? Text(
                        fallbackInitial,
                        style: TextStyle(
                          fontSize: size * 0.32,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              top: -4,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ringColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${(percent * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color color;

  _RingPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.045;

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 0, 6.28319, false, backgroundPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -1.5708; // -90deg, start at top
    final sweepAngle = 6.28319 * percent.clamp(0.0, 1.0);
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}
