import 'package:flutter/material.dart';

/// Profile Tab
///
/// Features (to be implemented):
/// - User profile info (name, age band, interests)
/// - Selfie/profile photo
/// - Sailing details (cruise line, ship, date)
/// - Joined pods
/// - Settings
/// - Sign out
///
/// TODO: Load user data from Firestore
/// TODO: Add edit profile functionality
/// TODO: Add settings screen
/// TODO: Implement sign out
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock user data - TODO: Replace with Firestore data
    final userName = 'Alex Johnson';
    final ageBand = '21-25';
    final interests = ['Nightlife', 'Fitness', 'Excursions'];
    final cruiseLine = 'Royal Caribbean';
    final ship = 'Harmony of the Seas';
    final sailingDate = '15 Feb 2026';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        userName[0],
                        style: TextStyle(
                          fontSize: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Age: $ageBand',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to edit profile
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interests
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests
                          .map((interest) => Chip(
                                label: Text(interest),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sailing Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Sailing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.directions_boat,
                      'Cruise Line',
                      cruiseLine,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.sailing, 'Ship', ship),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.calendar_today, 'Sailing Date', sailingDate),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // My Pods
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Pods',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPodBadge('Nightlife Crew', Colors.purple),
                    const SizedBox(height: 8),
                    _buildPodBadge('Gym Crew', Colors.red),
                    const SizedBox(height: 8),
                    _buildPodBadge('Excursions', Colors.green),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sign Out Button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement sign out
                _showSignOutDialog(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // App Version
            Center(
              child: Text(
                'Driftly v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPodBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.groups, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement Firebase sign out
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sign out feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
