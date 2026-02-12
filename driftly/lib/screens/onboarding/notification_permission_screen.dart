import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Notification icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active,
                  size: 60,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Stay Connected',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Enable notifications to never miss a moment with your cruise crew!',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[400],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Benefits list
              _buildBenefitItem(
                icon: Icons.photo_camera,
                title: 'Daily Photo Reminders',
                description: 'Capture memories at the perfect time',
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.diversity_3,
                title: 'Tribe Updates',
                description: 'Know when you\'re matched with your group',
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.location_on,
                title: 'Hangout Alerts',
                description: 'Get notified about meetups nearby',
              ),
              const SizedBox(height: 16),
              _buildBenefitItem(
                icon: Icons.chat_bubble,
                title: 'Messages',
                description: 'Stay in the loop with your pods',
              ),

              const Spacer(),

              // Enable button
              FilledButton(
                onPressed: _isRequesting ? null : _requestPermission,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isRequesting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Enable Notifications',
                        style: TextStyle(fontSize: 16),
                      ),
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
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 24,
          ),
        ),
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
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[500],
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
