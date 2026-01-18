import 'package:flutter/material.dart';

/// Hangouts Tab
///
/// Micro Hangouts Feature (45-minute "I'm here" check-ins)
///
/// Features (to be implemented):
/// - Active hangouts nearby (based on location/deck)
/// - Create new hangout
/// - Join existing hangout
/// - Hangout expiration timer (45 minutes)
/// - See who's checked in
///
/// TODO: Implement location-based hangout discovery
/// TODO: Add real-time hangout updates
/// TODO: Add countdown timer for active hangouts
class HangoutsTab extends StatelessWidget {
  const HangoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock active hangouts - TODO: Replace with Firestore data
    final activeHangouts = [
      _HangoutData(
        id: '1',
        location: 'Deck 12 Pool',
        createdBy: 'Sarah M.',
        attendeeCount: 5,
        timeRemaining: '32 min',
        vibe: 'Chill',
      ),
      _HangoutData(
        id: '2',
        location: 'Sports Bar',
        createdBy: 'Mike R.',
        attendeeCount: 3,
        timeRemaining: '18 min',
        vibe: 'Lively',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hangouts'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hangouts last 45 minutes. Check in when you\'re at a location!',
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),

            // Active Hangouts Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Active Nearby',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),

            if (activeHangouts.isEmpty)
              _buildEmptyState(context)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeHangouts.length,
                itemBuilder: (context, index) {
                  return _buildHangoutCard(context, activeHangouts[index]);
                },
              ),

            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Show create hangout dialog
          _showCreateHangoutDialog(context);
        },
        icon: const Icon(Icons.add_location),
        label: const Text('Start Hangout'),
      ),
    );
  }

  Widget _buildHangoutCard(BuildContext context, _HangoutData hangout) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hangout.location,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, size: 16, color: Colors.orange[800]),
                      const SizedBox(width: 4),
                      Text(
                        hangout.timeRemaining,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(hangout.createdBy[0]),
                ),
                const SizedBox(width: 8),
                Text(
                  'Started by ${hangout.createdBy}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${hangout.attendeeCount} checked in',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hangout.vibe,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: Join hangout
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joining ${hangout.location}...')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              child: const Text('Join Hangout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No active hangouts nearby',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Start one to let others know where you are!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showCreateHangoutDialog(BuildContext context) {
    // TODO: Implement full create hangout screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a Hangout'),
        content: const Text('Select your current location to start a 45-minute hangout.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hangout feature coming soon!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _HangoutData {
  final String id;
  final String location;
  final String createdBy;
  final int attendeeCount;
  final String timeRemaining;
  final String vibe;

  _HangoutData({
    required this.id,
    required this.location,
    required this.createdBy,
    required this.attendeeCount,
    required this.timeRemaining,
    required this.vibe,
  });
}
