import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'hot_zones_tab.dart';

/// Vibes Tab
///
/// Shows the Hot Zones vibe-voting content for the ship's locations.
class HangoutsTab extends StatelessWidget {
  const HangoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Vibes', style: AppTextStyles.displaySmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const SafeArea(child: HotZonesContent()),
    );
  }
}
