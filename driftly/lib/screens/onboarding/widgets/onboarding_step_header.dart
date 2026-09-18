import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/small_caps_label.dart';

/// Shared header for the 3-step onboarding flow (About You / Photos /
/// Select Sailing): back chevron, "STEP X OF 3" + title, "Driftly" wordmark,
/// and a segmented progress bar.
class OnboardingStepHeader extends StatelessWidget {
  final int step; // 1-based
  final int totalSteps;
  final String title;
  final VoidCallback? onBack;

  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.title,
    this.totalSteps = 3,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (onBack != null)
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: onBack,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SmallCapsLabel('Step $step of $totalSteps', color: AppColors.teal),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTextStyles.displaySmall,
                  ),
                ],
              ),
            ),
            Text(
              'Driftly',
              style: AppTextStyles.displaySmall.copyWith(
                color: AppColors.teal,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: List.generate(totalSteps, (index) {
            final isFilled = index < step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
                height: 4,
                decoration: BoxDecoration(
                  color: isFilled ? AppColors.teal : Colors.grey[800],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
