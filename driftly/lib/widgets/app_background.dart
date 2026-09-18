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
/// splash/onboarding star-field texture in the Figma design.
class _Starfield extends StatelessWidget {
  const _Starfield();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarfieldPainter(),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  // Fixed seed so the dot placement is stable across rebuilds/frames.
  static final Random _random = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    const dotCount = 60;

    for (var i = 0; i < dotCount; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      final radius = 0.6 + _random.nextDouble() * 1.2;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) => false;
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
