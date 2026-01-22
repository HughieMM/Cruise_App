import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/hot_zone_vote.dart';
import '../../../widgets/error_state.dart';
import '../../hot_zones/vote_dialog.dart';

/// Hot Zones Tab
///
/// Users vote on vibe for different ship locations
///
/// Features:
/// - Fixed ship locations: Pool, Casino, Nightclub, Sports Deck, Buffet, Theatre
/// - Vote options: Active, Quiet, Overcrowded, Good Vibes
/// - One vote per location per hour per user
/// - Real-time vote aggregation from last 60 minutes
/// - Display dominant vibe and vote count per location
class HotZonesTab extends StatefulWidget {
  const HotZonesTab({super.key});

  @override
  State<HotZonesTab> createState() => _HotZonesTabState();
}

class _HotZonesTabState extends State<HotZonesTab> {
  final _firestoreService = FirestoreService();

  Future<void> _refreshVotes() async {
    // StreamBuilder automatically refreshes, just show feedback
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Fixed locations as per requirements
  final List<Map<String, dynamic>> _locations = [
    {'name': 'Pool', 'icon': Icons.pool},
    {'name': 'Casino', 'icon': Icons.casino},
    {'name': 'Nightclub', 'icon': Icons.nightlife},
    {'name': 'Sports Deck', 'icon': Icons.sports_basketball},
    {'name': 'Buffet', 'icon': Icons.restaurant},
    {'name': 'Theatre', 'icon': Icons.theater_comedy},
  ];

  /// Aggregate votes by location and calculate dominant vibe
  Map<String, Map<String, dynamic>> _aggregateVotes(List<HotZoneVote> votes) {
    final locationSummaries = <String, Map<String, dynamic>>{};

    // Initialize all locations
    for (var location in _locations) {
      locationSummaries[location['name'] as String] = {
        'vibes': <String, int>{},
        'totalVotes': 0,
        'dominantVibe': null,
        'icon': location['icon'],
      };
    }

    // Group votes by location
    for (var vote in votes) {
      if (!locationSummaries.containsKey(vote.location)) continue;

      final summary = locationSummaries[vote.location]!;
      summary['totalVotes'] = (summary['totalVotes'] as int) + 1;

      final vibes = summary['vibes'] as Map<String, int>;
      vibes[vote.vibe] = (vibes[vote.vibe] ?? 0) + 1;
    }

    // Determine most common vibe for each location
    for (var entry in locationSummaries.entries) {
      final vibes = entry.value['vibes'] as Map<String, int>;
      if (vibes.isNotEmpty) {
        final mostCommonVibe = vibes.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        entry.value['dominantVibe'] = mostCommonVibe;
      }
    }

    return locationSummaries;
  }

  /// Get vibe emoji
  String _getVibeEmoji(String? vibe) {
    if (vibe == null) return '📍';
    switch (vibe) {
      case 'active':
        return '⚡';
      case 'quiet':
        return '🤫';
      case 'overcrowded':
        return '😰';
      case 'good_vibes':
        return '✨';
      default:
        return '📍';
    }
  }

  /// Get vibe display name
  String _getVibeDisplay(String? vibe) {
    if (vibe == null) return 'No votes yet';
    switch (vibe) {
      case 'active':
        return 'Active';
      case 'quiet':
        return 'Quiet';
      case 'overcrowded':
        return 'Overcrowded';
      case 'good_vibes':
        return 'Good Vibes';
      default:
        return 'Unknown';
    }
  }

  /// Get vibe color
  Color _getVibeColor(String? vibe) {
    if (vibe == null) return Colors.grey;
    switch (vibe) {
      case 'active':
        return const Color(0xFFFF9800); // Orange
      case 'quiet':
        return const Color(0xFF2196F3); // Blue
      case 'overcrowded':
        return const Color(0xFFF44336); // Red
      case 'good_vibes':
        return const Color(0xFF4CAF50); // Green
      default:
        return Colors.grey;
    }
  }

  void _showVoteDialog(String location) {
    showDialog(
      context: context,
      builder: (context) => VoteDialog(location: location),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hot Zones'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.appUser;
          final sailingId = user?.currentSailingId;

          if (user == null || sailingId == null) {
            return const Center(
              child: Text('Please select a sailing first'),
            );
          }

          return StreamBuilder<List<HotZoneVote>>(
            stream: _firestoreService.streamRecentVotesForSailing(
              sailingId: sailingId,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(
                  message: 'Error loading hot zones: ${snapshot.error}',
                  onRetry: _refreshVotes,
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final votes = snapshot.data!;
              final locationSummaries = _aggregateVotes(votes);

              return RefreshIndicator(
                onRefresh: _refreshVotes,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                              'See what\'s happening around the ship in real-time! Tap a location to vote.',
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
                      itemCount: _locations.length,
                      itemBuilder: (context, index) {
                        final location = _locations[index];
                        final locationName = location['name'] as String;
                        final summary = locationSummaries[locationName]!;

                        return _buildHotZoneCard(
                          context,
                          locationName: locationName,
                          icon: location['icon'] as IconData,
                          dominantVibe: summary['dominantVibe'] as String?,
                          totalVotes: summary['totalVotes'] as int,
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHotZoneCard(
    BuildContext context, {
    required String locationName,
    required IconData icon,
    required String? dominantVibe,
    required int totalVotes,
  }) {
    final vibeColor = _getVibeColor(dominantVibe);
    final hasVotes = totalVotes > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showVoteDialog(locationName),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locationName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasVotes
                              ? '$totalVotes ${totalVotes == 1 ? "vote" : "votes"} in last hour'
                              : 'No recent votes',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasVotes)
                    Text(
                      _getVibeEmoji(dominantVibe),
                      style: const TextStyle(fontSize: 32),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: vibeColor.withOpacity(0.15),
                  border: Border.all(
                    color: vibeColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Current Vibe: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getVibeDisplay(dominantVibe),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: vibeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showVoteDialog(locationName),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
                icon: const Icon(Icons.how_to_vote, size: 18),
                label: const Text('Vote on Vibe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
