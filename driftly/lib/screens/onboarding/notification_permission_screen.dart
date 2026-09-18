import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_background.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/pill_button.dart';

/// NotificationPermissionScreen
///
/// Asks user for notification permission during onboarding.
/// Explains why notifications are important for the cruise experience.
class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen> {
  final _notificationService = NotificationService();
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    try {
      await _notificationService.requestPermission();
    } catch (e) {
      // Continue even if permission request fails
    }

    setState(() => _isRequesting = false);
    _navigateToNext();
  }

  void _skipPermission() {
    _navigateToNext();
  }

  void _navigateToNext() {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppBackground(
        variant: BackgroundVariant.starfield,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),

              // Notification icon with glowing ring + coral count badge
              Center(
                child: SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.tealBorder),
                        ),
                      ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.tealTint,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.teal, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.notifications,
                          size: 44,
                          color: AppColors.teal,
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '3',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Stay '),
                    TextSpan(text: 'Connected', style: AppTextStyles.displayItalicSpan),
                  ],
                ),
                style: AppTextStyles.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Enable notifications to never miss a moment with your cruise crew!',
                style: TextStyle(fontSize: 15, color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Benefits list
              _buildBenefitItem(
                icon: Icons.photo_camera,
                color: AppColors.coral,
                title: 'Daily Photo Reminders',
                description: 'Capture memories at the perfect time',
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.diversity_3,
                color: AppColors.teal,
                title: 'Tribe Updates',
                description: 'Know when you\'re matched with your group',
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.location_on,
                color: AppColors.coral,
                title: 'Hangout Alerts',
                description: 'Get notified about meetups nearby',
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.chat_bubble,
                color: AppColors.teal,
                title: 'Messages',
                description: 'Stay in the loop with your pods',
              ),

              const Spacer(),

              // Enable button
              PillButton(
                label: _isRequesting ? '...' : 'Enable Notifications',
                color: AppColors.teal,
                onPressed: _isRequesting ? null : _requestPermission,
              ),
              const SizedBox(height: 12),

              // Skip button
              TextButton(
                onPressed: _skipPermission,
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        IconBadge(icon: icon, backgroundColor: color, size: 48),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
