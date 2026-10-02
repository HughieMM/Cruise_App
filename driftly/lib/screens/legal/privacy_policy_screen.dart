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
              'Last updated: October 2026',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: '1. Information We Collect',
              content: '''
When you use Driftly, we collect the following information:

Account Information: Name, email address, age band, gender, and the interests you select during sign-up.

Photos: The profile photos you upload (a face photo, a "fun" photo, a wildcard photo, an optional cover photo), your verification selfie, and any photos you post to Cruise Memories, Sea Ya, or hangout photo galleries.

Cruise Information: Your selected cruise line, ship, and sailing dates.

Usage Data: How you interact with the app, including Pods and Tribes joined, messages sent, First Mates connections, and Vibes (Hot Zones) votes cast.

Device Information: Device type, operating system, and a device token used solely to deliver push notifications.

Moderation Data: If content you post is flagged by our automated moderation systems or reported by another user, we record that a violation occurred and how many you've had, so repeat violations can be enforced consistently.

We do not collect or use your device's GPS location. "Vibes" location data refers only to a fixed list of ship locations (e.g. Main Pool, Casino, Nightclub) that you select manually from a list — not your real-world position.
''',
            ),

            _buildSection(
              context,
              title: '2. How We Use Your Information',
              content: '''
We use your information to:

- Create and manage your account
- Match you with compatible cruisers in your Tribe, including honoring accepted sibling/friend requests to sail together where possible
- Enable communication through Pods, Tribe chat, and First Mates (private 1:1 messaging between two people who connect through a Pod)
- Automatically screen uploaded photos and messages for content that violates our Community Guidelines (see Section 3)
- Send you notifications about your cruise, tribe matches, Sea Ya prompts, and app updates
- Improve our matching algorithms and app features
- Ensure safety and prevent fraud or abuse
- Comply with legal obligations
''',
            ),

            _buildSection(
              context,
              title: '3. Content Moderation',
              content: '''
To help keep Driftly safe, we use a combination of automated systems and user reports:

Automated Photo Screening: Every photo you upload is automatically scanned using Google Cloud Vision's content-safety detection before it's shown to anyone else. Photos identified as containing explicit, violent, or otherwise prohibited content are removed automatically.

Automated Text Screening: Messages are automatically checked for slurs, hate speech, and language inciting self-harm or violence before they're sent.

User Reporting and Blocking: You can report content or another user, and you can block anyone you no longer want to see or hear from — blocking is immediate and entirely within your control.

Strikes and Suspension: Violating our Community Guidelines (via either automated detection or a confirmed user report) adds a strike to your account. After repeated violations, your account is automatically suspended.

We do not use facial recognition to confirm your identity. Our onboarding verification step only checks, on your own device, that your photo contains a visible face — that check never leaves your phone or is sent to us.
''',
            ),

            _buildSection(
              context,
              title: '4. Information Sharing',
              content: '''
We share your information in the following ways:

With Other Users: Your profile information and photos are visible to other users on your sailing. Messages you send in Pods or Tribe chat are visible to other members of that group; First Mates messages are visible only to the two people in that conversation.

With Service Providers: We use Firebase and Google Cloud (Google LLC) for hosting, authentication, data storage, push notifications, and automated content-safety scanning (Google Cloud Vision).

For Legal Reasons: We may disclose information if required by law, or to protect the safety of our users.

We do NOT sell your personal information to third parties.
''',
            ),

            _buildSection(
              context,
              title: '5. Data Storage and Security',
              content: '''
Your data is stored using Firebase/Google Cloud infrastructure with encryption in transit and at rest.

We retain your data for as long as your account is active. You can permanently delete your account and associated data at any time through the app's Profile settings.

Photos are stored in secure cloud storage and are only accessible to users on your sailing (or, for First Mates photos shared privately, only to the two people in that conversation).
''',
            ),

            _buildSection(
              context,
              title: '6. Your Rights',
              content: '''
You have the right to:

- Access your personal data
- Correct inaccurate data
- Delete your account and data, at any time, directly in the app
- Export your data
- Opt out of push notifications

To exercise these rights, contact us at privacy@driftly.app or use the in-app settings.
''',
            ),

            _buildSection(
              context,
              title: '7. Age Requirements',
              content: '''
Driftly is intended for users aged 16 and older. We do not knowingly collect information from anyone under 16, including children under 13. If we learn that a user is under 16, we will delete their account and data.

Users aged 16-17 are matched, grouped, and able to message only with other users in the same 16-17 age group — this applies to Tribes, Pods, and First Mates alike — and cannot access gambling-related or nightlife-oriented features (such as the "High Rollers" pod or the "18+ Pool" Vibes location), which require users to be at least 18.
''',
            ),

            _buildSection(
              context,
              title: '8. Push Notifications',
              content: '''
We send push notifications for:

- Daily photo reminders and the random Sea Ya prompt during your cruise
- Tribe matching updates
- New messages in your Pods, Tribe chat, or First Mates
- Important app updates

You can disable notifications at any time in your device settings or app preferences.
''',
            ),

            _buildSection(
              context,
              title: '9. Changes to This Policy',
              content: '''
We may update this privacy policy from time to time. We will notify you of significant changes through the app or email.

Continued use of Driftly after changes constitutes acceptance of the updated policy.
''',
            ),

            _buildSection(
              context,
              title: '10. Contact Us',
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
