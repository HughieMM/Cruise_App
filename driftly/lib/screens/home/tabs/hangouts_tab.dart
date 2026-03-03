import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/badge_service.dart';
import '../../../models/micro_hangout.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/app_background.dart';
import '../../../widgets/hangout_photos_grid.dart';
import '../../hangouts/create_hangout_dialog.dart';
import '../../hangouts/hangout_camera_screen.dart';
import 'hot_zones_tab.dart';

/// Hangouts Tab
///
/// Micro Hangouts Feature (45-minute "I'm here" check-ins)
///
/// Features:
/// - View active hangouts filtered by sailing and age band
/// - Create new hangout with location and vibe selection
/// - Join existing hangouts
/// - Real-time updates with StreamBuilder
/// - Automatic expiration filtering (45 minutes)
/// - See who created each hangout and attendee count
class HangoutsTab extends StatefulWidget {
  const HangoutsTab({super.key});

  @override
  State<HangoutsTab> createState() => _HangoutsTabState();
}

class _HangoutsTabState extends State<HangoutsTab> {
  final _firestoreService = FirestoreService();
  final _badgeService = BadgeService();
  String? _errorMessage;
  int _selectedView = 0; // 0 = Hangouts, 1 = Hot Zones

  Future<void> _refreshHangouts() async {
    // StreamBuilder automatically refreshes, just show feedback
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  Future<void> _joinHangout(String hangoutId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (user == null || sailingId == null) {
        throw Exception('User or sailing not found');
      }

      await _firestoreService.joinHangout(
        sailingId: sailingId,
        hangoutId: hangoutId,
        userId: user.uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You joined the hangout!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatCreatedTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return DateFormat('h:mm a').format(timestamp);
    }
  }

  Color _getVibeColor(String vibe) {
    switch (vibe) {
      case 'chill':
        return Colors.blue;
      case 'lively':
        return Colors.orange;
      case 'party':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      extendBodyBehindAppBar: true,
      overlayOpacity: 0.5,
      appBar: AppBar(
        title: const Text('Hangouts & Vibes'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.location_on, size: 18),
                  label: Text('Hangouts'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.whatshot, size: 18),
                  label: Text('Hot Zones'),
                ),
              ],
              selected: {_selectedView},
              onSelectionChanged: (Set<int> selection) {
                setState(() {
                  _selectedView = selection.first;
                });
              },
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _selectedView == 0 ? _buildHangoutsView() : const HotZonesContent(),
      ),
      floatingActionButton: _selectedView == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateHangoutDialog(context),
              icon: const Icon(Icons.add_location),
              label: const Text('I\'m Here'),
            )
          : null,
    );
  }

  Widget _buildHangoutsView() {
    return Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.appUser;
          final sailingId = user?.currentSailingId;
          final ageBand = user?.ageBand;

          if (user == null || sailingId == null) {
            return const Center(
              child: Text('Please select a sailing first'),
            );
          }

          return StreamBuilder<List<MicroHangout>>(
            stream: _firestoreService.streamActiveHangouts(
              sailingId: sailingId,
              ageBand: ageBand,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ErrorState(
                  message: 'Error loading hangouts: ${snapshot.error}',
                  onRetry: _refreshHangouts,
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final hangouts = snapshot.data!;

              return RefreshIndicator(
                onRefresh: _refreshHangouts,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Active in Your Age Group',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (hangouts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${hangouts.length}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (hangouts.isEmpty)
                        EmptyState(
                          icon: Icons.location_off,
                          title: 'No Active Hangouts',
                          message: 'No one is hanging out in your age group right now.\nBe the first to create one!',
                          actionLabel: 'Create Hangout',
                          onAction: () => _showCreateHangoutDialog(context),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: hangouts.length,
                          itemBuilder: (context, index) {
                            return _buildHangoutCard(
                              context,
                              hangouts[index],
                              user.uid,
                            );
                          },
                        ),

                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              );
          },
        );
      },
    );
  }

  Widget _buildHangoutCard(
    BuildContext context,
    MicroHangout hangout,
    String currentUserId,
  ) {
    final vibeColor = _getVibeColor(hangout.vibe);
    final hasJoined = hangout.hasUserJoined(currentUserId);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final sailingId = authProvider.appUser?.currentSailingId ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hangout.location,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                backgroundColor: Colors.blue[100],
                child: Text(
                  hangout.createdByName.isNotEmpty
                      ? hangout.createdByName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hangout.createdByName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                  Text(
                    _formatCreatedTime(hangout.startTime),
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, size: 20, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                '${hangout.attendeeCount} ${hangout.attendeeCount == 1 ? "person" : "people"} here',
                style: TextStyle(color: Colors.blue[800]),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vibeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hangout.vibeEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hangout.vibe.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: vibeColor.withOpacity(0.9),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Hangout Photos Section
          if (hasJoined) ...[
            const SizedBox(height: 16),
            HangoutPhotosGrid(
              sailingId: sailingId,
              hangoutId: hangout.id,
              onAddPhoto: () => _openCamera(hangout),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: hasJoined ? null : () => _joinHangout(hangout.id),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    backgroundColor: hasJoined ? Colors.grey : Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text(hasJoined ? 'You\'re Here!' : 'Join Hangout'),
                ),
              ),
              if (hasJoined) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _openCamera(hangout),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Snap'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openCamera(MicroHangout hangout) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;
    final sailingId = user?.currentSailingId;

    if (user == null || sailingId == null) return;

    final photoUrl = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => HangoutCameraScreen(
          hangoutId: hangout.id,
          sailingId: sailingId,
          location: hangout.location,
        ),
      ),
    );

    if (photoUrl != null && mounted) {
      // Save photo to Firestore
      await _firestoreService.addHangoutPhoto(
        sailingId: sailingId,
        hangoutId: hangout.id,
        userId: user.uid,
        userName: user.name,
        photoUrl: photoUrl,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo shared!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showCreateHangoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateHangoutDialog(),
    );
  }
}
