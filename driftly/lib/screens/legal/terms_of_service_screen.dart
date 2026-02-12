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
              'Last updated: February 2026',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            _buildSection(
              context,
              title: '1. Acceptance of Terms',
              content: '''
By downloading, installing, or using Driftly ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the App.

Driftly is a social networking application designed to connect cruise passengers aged 21 and older.
''',
            ),

            _buildSection(
              context,
              title: '2. Eligibility',
              content: '''
To use Driftly, you must:

- Be at least 21 years of age
- Have a valid email address
- Have booked or plan to book a cruise
- Agree to these Terms of Service and our Privacy Policy

By using the App, you represent and warrant that you meet all eligibility requirements.
''',
            ),

            _buildSection(
              context,
              title: '3. Account Registration',
              content: '''
You must create an account to use Driftly. You agree to:

- Provide accurate, current, and complete information
- Maintain the security of your account credentials
- Notify us immediately of any unauthorized access
- Accept responsibility for all activities under your account

We reserve the right to suspend or terminate accounts that violate these terms.
''',
            ),

            _buildSection(
              context,
              title: '4. User Conduct',
              content: '''
You agree NOT to:

- Harass, bully, or intimidate other users
- Post content that is offensive, abusive, or inappropriate
- Impersonate another person or misrepresent your identity
- Use the App for illegal purposes
- Spam or send unsolicited messages
- Attempt to hack or disrupt the App's functionality
- Share explicit or adult content
- Discriminate against others based on race, gender, religion, or other protected characteristics
- Engage in any commercial activities without our permission

Violation of these rules may result in immediate account termination.
''',
            ),

            _buildSection(
              context,
              title: '5. Content',
              content: '''
User Content: You retain ownership of content you post (photos, messages, etc.), but grant Driftly a non-exclusive license to use, display, and distribute this content within the App.

Content Standards: All content must be appropriate for a general audience and comply with our community guidelines.

Content Removal: We reserve the right to remove any content that violates these terms or is otherwise objectionable.

Reporting: Users can report inappropriate content or behavior through the App's reporting feature.
''',
            ),

            _buildSection(
              context,
              title: '6. Tribe Matching',
              content: '''
Driftly uses algorithms to match users into "Tribes" based on various factors including interests, pod memberships, and sailing information.

- Matches are provided as suggestions only
- We do not guarantee compatibility or successful friendships
- Tribe assignments are final for each sailing
- Users must treat all tribe members with respect
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
- Report any concerning behavior to ship security and our support team

Driftly is not responsible for interactions that occur outside the App or for any harm resulting from in-person meetings.
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
- The accuracy of other users' information
- The behavior of other users

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

We may suspend or terminate your account at any time for violation of these Terms or for any other reason at our discretion.

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
If you have questions about these Terms, contact us at:

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
