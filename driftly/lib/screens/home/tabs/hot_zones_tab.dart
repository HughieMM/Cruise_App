import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/hot_zone_vote.dart';
import '../../../widgets/error_state.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/pill_button.dart';
import '../../hot_zones/vote_dialog.dart';

/// Hot Zones Tab
///
/// Users vote on vibe for different ship locations
///
/// Features:
/// - Fixed ship locations: Main Pool, Casino, Nightclub, Sports Deck,
///   Slides, Game Show, 18+ Pool
/// - Vote options: Active, Taking an L, Jammed, Chill
/// - One vote per location per hour per user
/// - Real-time vote aggregation from last 60 minutes
/// - Display dominant vibe and vote count per location
class HotZonesTab extends StatelessWidget {
  const HotZonesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hot Zones'),
      ),
      body: const HotZonesContent(),
    );
  }
}

/// Extracted Hot Zones content for reuse in HangoutsTab
class HotZonesContent extends StatefulWidget {
  const HotZonesContent({super.key});

  @override
  State<HotZonesContent> createState() => _HotZonesContentState();
}

class _HotZonesContentState extends State<HotZonesContent> {
  final _firestoreService = FirestoreService();

  Future<void> _refreshVotes() async {
    // StreamBuilder automatically refreshes, just show feedback
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Fixed locations as per requirements
  final List<Map<String, dynamic>> _locations = [
    {'name': 'Main Pool', 'icon': Icons.pool},
    {'name': 'Casino', 'icon': Icons.casino},
    {'name': 'Nightclub', 'icon': Icons.nightlife},
    {'name': 'Sports Deck', 'icon': Icons.sports_basketball},
    {'name': 'Slides', 'icon': Icons.waves},
    {'name': 'Game Show', 'icon': Icons.quiz},
    {'name': '18+ Pool', 'icon': Icons.local_bar},
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
        return '💥';
      case 'quiet':
        return '🎻';
      case 'overcrowded':
        return '🫠';
      case 'good_vibes':
        return '🧊';
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
        return 'Taking an L';
      case 'overcrowded':
        return 'Jammed';
      case 'good_vibes':
        return 'Chill';
      default:
        return 'Unknown';
    }
  }

  /// Get vibe color — a cold-to-warm gradient so the hottest spots pop:
  /// Taking an L (coldest) -> Chill (cold) -> Active (warmer) -> Jammed (warmest)
  Color _getVibeColor(String? vibe) {
    if (vibe == null) return Colors.grey;
    switch (vibe) {
      case 'quiet':
        return AppColors.vibeQuiet;
      case 'good_vibes':
        return AppColors.vibeChill;
      case 'active':
        return AppColors.vibeActive;
      case 'overcrowded':
        return AppColors.vibeJammed;
      default:
        return Colors.grey;
    }
  }

  /// Blend of the vibe colors weighted by vote share, cold-to-warm — same
  /// idea as the onboarding pod picker's color blend, but weighted by
  /// percentage of votes instead of an equal split per selection.
  List<Color> _buildVoteGradientColors(Map<String, int> vibes, int totalVotes) {
    if (totalVotes == 0) {
      return [AppColors.surfaceSolid, AppColors.surfaceSolid];
    }

    const order = ['quiet', 'good_vibes', 'active', 'overcrowded'];
    final colors = <Color>[];

    for (final vibe in order) {
      final count = vibes[vibe] ?? 0;
      if (count == 0) continue;
      final slices = ((count / totalVotes) * 10).round().clamp(1, 10);
      colors.addAll(List.filled(slices, _getVibeColor(vibe).withValues(alpha: 0.55)));
    }

    return colors.isEmpty ? [AppColors.surfaceSolid, AppColors.surfaceSolid] : colors;
  }

  void _showVoteDialog(String location) {
    showDialog(
      context: context,
      builder: (context) => VoteDialog(location: location),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
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
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: GlassCard(
                        borderColor: AppColors.amberBorder,
                        tintColor: AppColors.amberTint,
                        child: Row(
                          children: [
                            const Icon(Icons.whatshot, color: AppColors.amber),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'See what\'s happening around the ship in real-time! Tap a location to vote.',
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                            ),
                          ],
                        ),
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
                          vibes: summary['vibes'] as Map<String, int>,
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
    );
  }

  Widget _buildHotZoneCard(
    BuildContext context, {
    required String locationName,
    required IconData icon,
    required String? dominantVibe,
    required Map<String, int> vibes,
    required int totalVotes,
  }) {
    final vibeColor = _getVibeColor(dominantVibe);
    final hasVotes = totalVotes > 0;
    final gradientColors = _buildVoteGradientColors(vibes, totalVotes);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
            ),
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
                        IconBadge(
                          icon: icon,
                          backgroundColor: hasVotes ? vibeColor : AppColors.teal,
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
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasVotes
                                    ? '$totalVotes ${totalVotes == 1 ? "vote" : "votes"} in last 30 min'
                                    : 'No recent votes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Current Vibe: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
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
                    const SizedBox(height: 12),
                    PillButton(
                      label: 'Vote on Vibe',
                      icon: Icons.how_to_vote,
                      variant: PillVariant.outlined,
                      color: AppColors.teal,
                      onPressed: () => _showVoteDialog(locationName),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
