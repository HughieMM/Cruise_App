import 'package:flutter/material.dart';

/// Hot Zones Tab
///
/// Users vote on crowd level and vibe for different ship locations
///
/// Features (to be implemented):
/// - List of ship locations/zones
/// - Current crowd level (Empty, Moderate, Packed)
/// - Current vibe (Chill, Lively, Party)
/// - Vote/update status
/// - Real-time updates from other users
///
/// TODO: Load locations from Firestore
/// TODO: Add real-time vote aggregation
/// TODO: Add location filtering (by deck, type, etc.)
class HotZonesTab extends StatelessWidget {
  const HotZonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock hot zones data - TODO: Replace with Firestore data
    final zones = [
      _HotZoneData(
        id: '1',
        name: 'Deck 12 Pool',
        deck: '12',
        crowdLevel: CrowdLevel.packed,
        vibe: Vibe.party,
        lastUpdated: '5 min ago',
        votes: 12,
      ),
      _HotZoneData(
        id: '2',
        name: 'Casino',
        deck: '5',
        crowdLevel: CrowdLevel.moderate,
        vibe: Vibe.lively,
        lastUpdated: '15 min ago',
        votes: 8,
      ),
      _HotZoneData(
        id: '3',
        name: 'Spa & Relaxation',
        deck: '14',
        crowdLevel: CrowdLevel.empty,
        vibe: Vibe.chill,
        lastUpdated: '30 min ago',
        votes: 4,
      ),
      _HotZoneData(
        id: '4',
        name: 'Sports Bar',
        deck: '6',
        crowdLevel: CrowdLevel.moderate,
        vibe: Vibe.lively,
        lastUpdated: '1 hour ago',
        votes: 6,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hot Zones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Add filter options
            },
          ),
        ],
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.whatshot, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'See what\'s happening around the ship in real-time!',
                      style: TextStyle(color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),

            // Hot Zones List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: zones.length,
              itemBuilder: (context, index) {
                return _buildHotZoneCard(context, zones[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotZoneCard(BuildContext context, _HotZoneData zone) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Deck ${zone.deck}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.whatshot,
                  color: _getHotZoneColor(zone.vibe),
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusChip(
                    context,
                    label: 'Crowd',
                    value: zone.crowdLevel.name.toUpperCase(),
                    color: _getCrowdColor(zone.crowdLevel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusChip(
                    context,
                    label: 'Vibe',
                    value: zone.vibe.name.toUpperCase(),
                    color: _getVibeColor(zone.vibe),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${zone.votes} votes',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  zone.lastUpdated,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // TODO: Open vote/update dialog
                _showVoteDialog(context, zone);
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 36),
              ),
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Color _getCrowdColor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.empty:
        return Colors.green;
      case CrowdLevel.moderate:
        return Colors.orange;
      case CrowdLevel.packed:
        return Colors.red;
    }
  }

  Color _getVibeColor(Vibe vibe) {
    switch (vibe) {
      case Vibe.chill:
        return Colors.blue;
      case Vibe.lively:
        return Colors.purple;
      case Vibe.party:
        return Colors.pink;
    }
  }

  Color _getHotZoneColor(Vibe vibe) {
    switch (vibe) {
      case Vibe.chill:
        return Colors.blue;
      case Vibe.lively:
        return Colors.orange;
      case Vibe.party:
        return Colors.red;
    }
  }

  void _showVoteDialog(BuildContext context, _HotZoneData zone) {
    // TODO: Implement full voting interface
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${zone.name}'),
        content: const Text('Vote on current crowd and vibe levels.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voting feature coming soon!')),
              );
            },
            child: const Text('Vote'),
          ),
        ],
      ),
    );
  }
}

enum CrowdLevel { empty, moderate, packed }

enum Vibe { chill, lively, party }

class _HotZoneData {
  final String id;
  final String name;
  final String deck;
  final CrowdLevel crowdLevel;
  final Vibe vibe;
  final String lastUpdated;
  final int votes;

  _HotZoneData({
    required this.id,
    required this.name,
    required this.deck,
    required this.crowdLevel,
    required this.vibe,
    required this.lastUpdated,
    required this.votes,
  });
}
