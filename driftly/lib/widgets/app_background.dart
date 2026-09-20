import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Which visual treatment [AppBackground] renders.
enum BackgroundVariant {
  /// Full-bleed photo + dark overlay (original behavior).
  photo,

  /// Flat navy background scattered with small white dots, used for
  /// Splash/Onboarding/Notification-permission screens.
  starfield,
}

/// Reusable ocean-themed background for the entire app
class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showOverlay;
  final double overlayOpacity;
  final BackgroundVariant variant;

  const AppBackground({
    super.key,
    required this.child,
    this.showOverlay = true,
    this.overlayOpacity = 0.3,
    this.variant = BackgroundVariant.photo,
  });

  @override
  Widget build(BuildContext context) {
    if (variant == BackgroundVariant.starfield) {
      return Container(
        color: AppColors.background,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: _Starfield()),
            child,
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: showOverlay
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: overlayOpacity),
              ),
              child: child,
            )
          : child,
    );
  }
}

/// Scattered small white dots over the flat navy background, matching the
/// splash/onboarding star-field texture in the Figma design. Each dot drifts
/// slowly and continuously in place, so the field never jumps or resets —
/// it just keeps floating regardless of what else is happening on screen.
class _Starfield extends StatefulWidget {
  const _Starfield();

  @override
  State<_Starfield> createState() => _StarfieldState();
}

class _StarfieldState extends State<_Starfield> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarfieldPainter(_controller),
    );
  }
}

class _StarDot {
  factory _StarDot(int seed) {
    final random = Random(seed);
    return _StarDot._(
      baseX: random.nextDouble(),
      baseY: random.nextDouble(),
      radius: 0.6 + random.nextDouble() * 1.2,
      driftAngle: random.nextDouble() * 2 * pi,
      driftSpeed: 0.3 + random.nextDouble() * 0.5,
    );
  }

  _StarDot._({
    required this.baseX,
    required this.baseY,
    required this.radius,
    required this.driftAngle,
    required this.driftSpeed,
  });

  final double baseX;
  final double baseY;
  final double radius;
  final double driftAngle;
  final double driftSpeed;
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  static const _dotCount = 60;
  static final List<_StarDot> _dots =
      List.generate(_dotCount, (i) => _StarDot(i));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    // Small, slow drift so movement always reads as smooth and ambient.
    const driftRadius = 6.0;
    final t = animation.value;

    for (final dot in _dots) {
      final phase = t * 2 * pi * dot.driftSpeed + dot.driftAngle;
      final dx = dot.baseX * size.width + sin(phase) * driftRadius;
      final dy = dot.baseY * size.height + cos(phase) * driftRadius;
      canvas.drawCircle(Offset(dx, dy), dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => true;
}

/// Scaffold with the app background built-in
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showOverlay;
  final double overlayOpacity;
  final bool extendBodyBehindAppBar;
  final BackgroundVariant variant;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showOverlay = true,
    this.overlayOpacity = 0.3,
    this.extendBodyBehindAppBar = false,
    this.variant = BackgroundVariant.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: AppBackground(
        showOverlay: showOverlay,
        overlayOpacity: overlayOpacity,
        variant: variant,
        child: body,
      ),
    );
  }
}
