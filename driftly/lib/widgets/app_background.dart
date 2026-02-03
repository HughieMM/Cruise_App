import 'package:flutter/material.dart';

/// AppBackground widget
///
/// Provides a consistent gradient background across the app
/// Can be customized with different colors for cruise line theming
class AppBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const AppBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  // Default ocean-inspired gradient
  static const List<Color> defaultColors = [
    Color(0xFFF5F7FA), // Light grey-white
    Color(0xFFE8F4FD), // Very light blue
    Color(0xFFD6EAF8), // Light ocean blue
  ];

  // Royal Caribbean theme
  static const List<Color> royalCaribbeanColors = [
    Color(0xFFF5F7FA),
    Color(0xFFE3F2FD),
    Color(0xFFBBDEFB), // Royal blue tint
  ];

  // Norwegian theme
  static const List<Color> norwegianColors = [
    Color(0xFFF5F7FA),
    Color(0xFFE8F5E9),
    Color(0xFFC8E6C9), // Green tint
  ];

  // Carnival theme
  static const List<Color> carnivalColors = [
    Color(0xFFFFF8E1),
    Color(0xFFFFECB3),
    Color(0xFFFFE082), // Warm yellow/gold tint
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ?? defaultColors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Wave decoration for bottom of screens
class WaveDecoration extends StatelessWidget {
  final Color color;
  final double height;

  const WaveDecoration({
    super.key,
    this.color = const Color(0x1A2196F3),
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width, height),
      painter: WavePainter(color: color),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.3,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.7,
      size.width, size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
