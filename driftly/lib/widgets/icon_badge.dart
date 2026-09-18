import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Tinted rounded-square badge holding either a Material [icon] or an
/// [emoji] string. Used for onboarding notification rows, pod badges, Home
/// stat-card icons, and Profile "MY SAILING" rows.
class IconBadge extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final Color backgroundColor;
  final Color? iconColor;
  final double size;
  final double borderRadius;

  const IconBadge({
    super.key,
    this.icon,
    this.emoji,
    this.backgroundColor = AppColors.teal,
    this.iconColor,
    this.size = 44,
    this.borderRadius = 12,
  }) : assert(
          icon != null || emoji != null,
          'IconBadge requires either an icon or an emoji',
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji!, style: TextStyle(fontSize: size * 0.5))
          : Icon(icon, color: iconColor ?? backgroundColor, size: size * 0.5),
    );
  }
}
