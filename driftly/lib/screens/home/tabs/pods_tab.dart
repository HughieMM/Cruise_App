import 'package:flutter/material.dart';

/// Pods Tab
///
/// Features (to be implemented):
/// - List of user's joined pods
/// - Pod chat preview
/// - Unread message badges
/// - Pod member count
/// - Tap to open full pod chat screen
///
/// TODO: Load user's pods from Firestore
/// TODO: Add real-time chat message listeners
/// TODO: Implement pod chat screen navigation
class PodsTab extends StatelessWidget {
  const PodsTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - TODO: Replace with Firestore data
    final pods = [
      _PodData(
        id: 'nightlife_crew',
        name: 'Nightlife Crew',
        icon: Icons.nightlife,
        color: Colors.purple,
        memberCount: 24,
        unreadCount: 3,
        lastMessage: 'Anyone up for the club tonight?',
        lastMessageTime: '2 min ago',
      ),
      _PodData(
        id: 'gym_crew',
        name: 'Gym Crew',
        icon: Icons.fitness_center,
        color: Colors.red,
        memberCount: 18,
        unreadCount: 0,
        lastMessage: '6 AM workout tomorrow?',
        lastMessageTime: '1 hour ago',
      ),
      _PodData(
        id: 'excursions',
        name: 'Excursions',
        icon: Icons.explore,
        color: Colors.green,
        memberCount: 31,
        unreadCount: 7,
        lastMessage: 'Just booked the snorkeling trip!',
        lastMessageTime: '3 hours ago',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Search pods
            },
          ),
        ],
      ),
      body: pods.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              itemCount: pods.length,
              itemBuilder: (context, index) {
                final pod = pods[index];
                return _buildPodCard(context, pod);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to browse/join pods screen
        },
        icon: const Icon(Icons.add),
        label: const Text('Join Pod'),
      ),
    );
  }

  Widget _buildPodCard(BuildContext context, _PodData pod) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: pod.color.withOpacity(0.2),
          child: Icon(pod.icon, color: pod.color),
        ),
        title: Row(
          children: [
            Text(
              pod.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            if (pod.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pod.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              pod.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${pod.memberCount} members',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Text(
                  pod.lastMessageTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to pod chat screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opening ${pod.name} chat...')),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No pods yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Join pods to connect with cruisers who share your interests',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodData {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final int memberCount;
  final int unreadCount;
  final String lastMessage;
  final String lastMessageTime;

  _PodData({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.memberCount,
    required this.unreadCount,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}
