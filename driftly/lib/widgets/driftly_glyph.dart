import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Teal wave glyph in a rounded square, with soft rippling rings that pulse
/// outward around it continuously — matches the splash/welcome icon
/// treatment in the Figma design. The wave icon itself never changes; only
/// the surrounding rings animate.
class DriftlyGlyph extends StatefulWidget {
  final double size;

  const DriftlyGlyph({super.key, this.size = 190});

  @override
  State<DriftlyGlyph> createState() => _DriftlyGlyphState();
}

class _DriftlyGlyphState extends State<DriftlyGlyph> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Ripple(controller: _controller, delay: 0.0, size: widget.size),
          _Ripple(controller: _controller, delay: 0.5, size: widget.size),
          Container(
            width: widget.size * 0.45,
            height: widget.size * 0.45,
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(widget.size * 0.11),
              border: Border.all(color: AppColors.teal, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.waves, color: AppColors.teal, size: widget.size * 0.2),
          ),
        ],
      ),
    );
  }
}

/// A single ring that grows outward and fades as it goes, looping forever.
/// Two of these offset by half a cycle give a continuous rippling effect.
class _Ripple extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final double size;

  const _Ripple({required this.controller, required this.delay, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = (controller.value + delay) % 1.0;
        final scale = 0.45 + t * 0.55;
        final opacity = (1.0 - t) * 0.6;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: size * scale,
            height: size * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.teal, width: 1.5),
            ),
          ),
        );
      },
    );
  }
}
