import 'package:flutter/material.dart';

/// TermsOfServiceScreen
///
/// Displays the app's terms of service.
/// Required for App Store submission.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              title: '1. Acceptance of Terms',
              content: '''
By downloading, installing, or using Driftly ("the App"), you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, do not use the App.

Driftly is a social networking application designed to connect cruise passengers aged 16 and older.
''',
            ),

            _buildSection(
              context,
              title: '2. Eligibility',
              content: '''
To use Driftly, you must:

- Be at least 16 years of age
- Have a valid email address
- Have booked or plan to book a cruise
- Agree to these Terms of Service and our Privacy Policy

By using the App, you represent and warrant that you meet all eligibility requirements and that the age you provide is accurate.

Age-based restrictions: Users aged 16-17 are only matched, grouped, and able to message with other users in the same 16-17 age group — this applies across Tribes, Pods, and First Mates — and cannot access gambling-related features (such as the "High Rollers" pod) or nightlife-oriented content (such as the "18+ Pool" Vibes location). Those features require users to be at least 18 years of age.
''',
            ),

            _buildSection(
              context,
              title: '3. Account Registration',
              content: '''
You must create an account to use Driftly. You agree to:

- Provide accurate, current, and complete information, including your real age
- Maintain the security of your account credentials
- Notify us immediately of any unauthorized access
- Accept responsibility for all activities under your account

As part of account setup, you'll be asked to take a verification selfie. We check, entirely on your device, that the photo contains a visible face — we do not perform facial recognition or confirm it is the same person as your other photos.

We reserve the right to suspend or terminate accounts that violate these terms.
''',
            ),

            _buildSection(
              context,
              title: '4. User Conduct',
              content: '''
You agree NOT to:

- Harass, bully, or intimidate other users
- Post content that is offensive, abusive, hateful, or inappropriate, including slurs, hate speech, or language encouraging self-harm or violence
- Post sexually explicit, graphic, or otherwise inappropriate photos
- Impersonate another person or misrepresent your identity or age
- Use the App for illegal purposes
- Spam or send unsolicited messages
- Attempt to hack or disrupt the App's functionality
- Discriminate against others based on race, gender, religion, or other protected characteristics
- Engage in any commercial activities without our permission

We use a combination of automated screening and user reports to enforce these rules — see Section 5. Violations may result in content removal, a strike on your account, or immediate termination for severe violations, at our discretion.
''',
            ),

            _buildSection(
              context,
              title: '5. Content, Reporting, and Enforcement',
              content: '''
User Content: You retain ownership of content you post (photos, messages, etc.), but grant Driftly a non-exclusive license to use, display, and distribute this content within the App for as long as it remains posted.

Automated Screening: Photos are automatically scanned for prohibited content before other users can see them. Messages are automatically checked for slurs, hate speech, and language encouraging self-harm or violence before they're sent. Content that fails these checks is blocked or removed automatically.

Reporting: You can report any piece of content or any user directly in the App.

Blocking: You can block any other user at any time; once blocked, that person can no longer message or otherwise interact with you. Blocking is entirely within your control and takes effect immediately.

Strikes and Suspension: Confirmed violations — whether caught automatically or through a user report — add a strike to your account. Repeated violations result in your account being automatically suspended. We may also remove content or terminate an account directly for severe violations without prior warning.
''',
            ),

            _buildSection(
              context,
              title: '6. Tribe, Pod, and First Mates Matching',
              content: '''
Driftly uses algorithms to match users into "Tribes" based on factors including age band, shared interests, and (where both people have opted in) accepted sibling/friend requests.

- Matches, Pods, and First Mates connections are provided as suggestions and tools only
- We do not guarantee compatibility or successful friendships
- Tribe assignments are final for each sailing, though a separate matching pass applies to anyone who joins after the main matching has already run
- First Mates (private 1:1 messaging) is only ever initiated from a Pod — it is intentionally not available from Tribe chat, so no one is left out of the group
- Users must treat all Tribe, Pod, and First Mates members with respect
''',
            ),

            _buildSection(
              context,
              title: '7. Safety and Meetings',
              content: '''
When meeting other users in person:

- Meet in public areas of the cruise ship
- Inform others of your plans
- Trust your instincts and leave if uncomfortable
- Report any concerning behavior to ship security and our support team, and use the in-app Report/Block tools

Driftly performs automated and user-driven content moderation, but does not verify the real-world identity of any user. Driftly is not responsible for interactions that occur outside the App or for any harm resulting from in-person meetings.
''',
            ),

            _buildSection(
              context,
              title: '8. Intellectual Property',
              content: '''
The Driftly name, logo, and all related graphics, software, and content are owned by Driftly and protected by intellectual property laws.

You may not copy, modify, distribute, or create derivative works from any part of the App without our written permission.
''',
            ),

            _buildSection(
              context,
              title: '9. Disclaimers',
              content: '''
THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND.

We do not guarantee:
- Uninterrupted or error-free service
- That matches will lead to friendships
- The accuracy of other users' information, including their stated age
- The behavior of other users
- That our automated content moderation will catch every violation

USE THE APP AT YOUR OWN RISK.
''',
            ),

            _buildSection(
              context,
              title: '10. Limitation of Liability',
              content: '''
To the maximum extent permitted by law, Driftly shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App.

Our total liability shall not exceed the amount you paid to use the App (if any) in the past 12 months.
''',
            ),

            _buildSection(
              context,
              title: '11. Indemnification',
              content: '''
You agree to indemnify and hold harmless Driftly and its employees from any claims, damages, or expenses arising from:

- Your use of the App
- Your violation of these Terms
- Your violation of any third-party rights
''',
            ),

            _buildSection(
              context,
              title: '12. Termination',
              content: '''
You may delete your account at any time through the App settings.

We may suspend or terminate your account at any time for violation of these Terms — including reaching the strike threshold described in Section 5 — or for any other reason at our discretion.

Upon termination, your right to use the App ceases immediately.
''',
            ),

            _buildSection(
              context,
              title: '13. Changes to Terms',
              content: '''
We may modify these Terms at any time. We will notify you of material changes through the App or email.

Continued use of the App after changes constitutes acceptance of the new Terms.
''',
            ),

            _buildSection(
              context,
              title: '14. Governing Law',
              content: '''
These Terms are governed by the laws of the State of Florida, United States, without regard to conflict of law principles.

Any disputes shall be resolved in the courts of Florida.
''',
            ),

            _buildSection(
              context,
              title: '15. Contact Us',
              content: '''
If you have questions about these Terms, or need to report a safety concern, contact us at:

Email: support@driftly.app
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
