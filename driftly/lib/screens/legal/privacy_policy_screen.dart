import 'package:flutter/material.dart';

/// PrivacyPolicyScreen
///
/// Displays the app's privacy policy.
/// Required for App Store submission.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: February 2026',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: '1. Information We Collect',
              content: '''
When you use Driftly, we collect the following information:

Account Information: Name, email address, date of birth, and profile photos you provide during registration.

Cruise Information: Your selected cruise line, ship, sailing dates, and cabin preferences.

Usage Data: How you interact with the app, including pods joined, messages sent, and hangouts attended.

Device Information: Device type, operating system, and unique device identifiers for push notifications.

Location Data: Only when you use Hot Zones features, and only with your explicit permission.

Photos: Photos you upload for your profile and Cruise Memories feature.
''',
            ),

            _buildSection(
              context,
              title: '2. How We Use Your Information',
              content: '''
We use your information to:

- Create and manage your account
- Match you with compatible cruisers in your Tribe
- Enable communication through Pods and direct messages
- Send you notifications about your cruise, tribe matches, and app updates
- Improve our matching algorithms and app features
- Ensure safety and prevent fraud
- Comply with legal obligations
''',
            ),

            _buildSection(
              context,
              title: '3. Information Sharing',
              content: '''
We share your information in the following ways:

With Other Users: Your profile information, photos, and activity in pods are visible to other users on your sailing.

With Service Providers: We use third-party services for hosting, analytics, and push notifications (Firebase, Google Cloud).

For Legal Reasons: We may disclose information if required by law or to protect our rights and safety.

We do NOT sell your personal information to third parties.
''',
            ),

            _buildSection(
              context,
              title: '4. Data Storage and Security',
              content: '''
Your data is stored securely using Firebase/Google Cloud infrastructure with encryption in transit and at rest.

We retain your data for as long as your account is active. You can request deletion at any time through the app settings.

Photos are stored in secure cloud storage and are only accessible to users on your sailing.
''',
            ),

            _buildSection(
              context,
              title: '5. Your Rights',
              content: '''
You have the right to:

- Access your personal data
- Correct inaccurate data
- Delete your account and data
- Export your data
- Opt out of marketing communications
- Withdraw consent for location services

To exercise these rights, contact us at privacy@driftly.app or use the in-app settings.
''',
            ),

            _buildSection(
              context,
              title: '6. Age Requirements',
              content: '''
Driftly is intended for users aged 21 and older. We do not knowingly collect information from users under 21. If we learn that a user is under 21, we will delete their account and data.
''',
            ),

            _buildSection(
              context,
              title: '7. Push Notifications',
              content: '''
We send push notifications for:

- Daily photo reminders during your cruise
- Tribe matching updates
- New messages and hangout invitations
- Important app updates

You can disable notifications at any time in your device settings or app preferences.
''',
            ),

            _buildSection(
              context,
              title: '8. Changes to This Policy',
              content: '''
We may update this privacy policy from time to time. We will notify you of significant changes through the app or email.

Continued use of Driftly after changes constitutes acceptance of the updated policy.
''',
            ),

            _buildSection(
              context,
              title: '9. Contact Us',
              content: '''
If you have questions about this privacy policy or your data, contact us at:

Email: privacy@driftly.app
''',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: Colors.grey[300],
                ),
          ),
        ],
      ),
    );
  }
}
