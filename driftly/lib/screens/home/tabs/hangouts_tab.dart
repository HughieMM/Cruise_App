import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/badge_service.dart';
import '../../../models/micro_hangout.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/hangout_photos_grid.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/app_segmented_control.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/pill_button.dart';
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
        return AppColors.teal;
      case 'lively':
        return AppColors.amber;
      case 'party':
        return AppColors.coral;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Hangouts & Vibes', style: AppTextStyles.displaySmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AppSegmentedControl<int>(
              segments: const [
                SegmentItem(value: 0, label: 'Hangouts'),
                SegmentItem(value: 1, label: 'Hot Zones', emoji: '🔥'),
              ],
              selected: _selectedView,
              onChanged: (value) => setState(() => _selectedView = value),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _selectedView == 0 ? _buildHangoutsView() : const HotZonesContent(),
      ),
      floatingActionButton: _selectedView == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.black,
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: GlassCard(
                          borderColor: AppColors.tealBorder,
                          tintColor: AppColors.tealTint,
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.teal),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Hangouts last 45 minutes. Check in when you\'re at a location!',
                                  style: TextStyle(color: Colors.grey[300]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Active Hangouts Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Active in Your Age Group',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (hangouts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.tealTint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${hangouts.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.teal,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hangout.location,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.amberTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer, size: 16, color: AppColors.amber),
                    const SizedBox(width: 4),
                    Text(
                      hangout.timeRemaining,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.amber,
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
              IconBadge(
                emoji: hangout.createdByName.isNotEmpty
                    ? hangout.createdByName[0].toUpperCase()
                    : '?',
                backgroundColor: AppColors.teal,
                size: 32,
                borderRadius: 999,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hangout.createdByName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _formatCreatedTime(hangout.startTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, size: 20, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                '${hangout.attendeeCount} ${hangout.attendeeCount == 1 ? "person" : "people"} here',
                style: TextStyle(color: Colors.grey[300]),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: vibeColor.withValues(alpha: 0.2),
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
                        color: vibeColor,
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
                child: PillButton(
                  label: hasJoined ? 'You\'re Here!' : 'Join Hangout',
                  color: hasJoined ? Colors.grey : AppColors.teal,
                  onPressed: hasJoined ? null : () => _joinHangout(hangout.id),
                ),
              ),
              if (hasJoined) ...[
                const SizedBox(width: 8),
                PillButton(
                  label: 'Snap',
                  icon: Icons.camera_alt,
                  color: AppColors.coral,
                  onPressed: () => _openCamera(hangout),
                ),
              ],
            ],
          ),
        ],
        ),
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
