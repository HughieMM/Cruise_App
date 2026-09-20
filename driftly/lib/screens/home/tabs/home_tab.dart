import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tribe_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/pod.dart';
import '../../../models/sailing.dart';
import '../../../utils/constants.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/small_caps_label.dart';
import '../../chat/pod_chat_screen.dart';

/// Home Tab
///
/// Features:
/// - Welcome message with user's name
/// - My Pods list showing user's joined pods
/// - Quick stats (pods count, connections, hangouts)
/// - Navigate to pod chat on tap
///
/// TODO: Add real-time activity feed
/// TODO: Add countdown timer to sailing date
/// TODO: Add sailing information display
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _firestoreService = FirestoreService();
  List<Pod> _userPods = [];
  Sailing? _sailing;
  bool _isLoadingPods = true;
  bool _isLoadingSailing = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserPods(),
      _loadSailing(),
    ]);
  }

  Future<void> _loadUserPods() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (user == null || sailingId == null) {
        setState(() => _isLoadingPods = false);
        return;
      }

      final pods = await _firestoreService.getUserPodsForSailing(
        sailingId: sailingId,
        userId: user.uid,
      );

      setState(() {
        _userPods = pods;
        _isLoadingPods = false;
      });
    } catch (e) {
      setState(() => _isLoadingPods = false);
    }
  }

  Future<void> _loadSailing() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (sailingId == null) {
        setState(() => _isLoadingSailing = false);
        return;
      }

      final sailing = await _firestoreService.getSailing(sailingId);
      setState(() {
        _sailing = sailing;
        _isLoadingSailing = false;
      });
    } catch (e) {
      setState(() => _isLoadingSailing = false);
    }
  }

  // Helper to parse color from hex string
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  /// "Day X · Cruise Line" label shown top-left, matching the sailing's
  /// actual elapsed time and cruise line rather than fabricated data.
  String _dayAndLineLabel() {
    if (_sailing == null) return 'Driftly';
    final dayNumber = _sailing!.hasDeparted
        ? DateTime.now().difference(_sailing!.departureDate).inDays + 1
        : 1;
    final lineName = _sailing!.cruiseLineId
        .split('_')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
    return 'Day $dayNumber · $lineName';
  }

  // Helper to get icon from string
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center;
      case 'nightlife':
        return Icons.nightlife;
      case 'local_bar':
        return Icons.local_bar;
      case 'explore':
        return Icons.explore;
      case 'sports_basketball':
        return Icons.sports_basketball;
      case 'casino':
        return Icons.casino;
      default:
        return Icons.groups;
    }
  }

  List<Widget> _buildTimelinePrompts() {
    final widgets = <Widget>[];
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final tribeProvider = Provider.of<TribeProvider>(context, listen: false);
    final user = authProvider.appUser;

    if (_sailing == null || user == null) return widgets;

    // Profile completion prompt (Day 30 or less, profile incomplete)
    if (_sailing!.shouldPromptProfileCompletion && !user.hasAllPhotos) {
      widgets.add(
        GlassCard(
          borderColor: AppColors.amberBorder,
          tintColor: AppColors.amberTint,
          child: Row(
            children: [
              const IconBadge(icon: Icons.person_add, backgroundColor: AppColors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Add your photos to be matched with a tribe!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              PillButton(
                label: 'Add Photos',
                color: AppColors.amber,
                onPressed: () => context.go('/onboarding/photos'),
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // Tribe matching info (Day 25 or less, no tribe yet)
    if (_sailing!.shouldTriggerTribeMatching && !tribeProvider.hasTribe) {
      widgets.add(
        GlassCard(
          child: Row(
            children: [
              const IconBadge(icon: Icons.diversity_3, backgroundColor: AppColors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tribe Matching Active',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'You\'ll be matched with your tribe soon!',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.hourglass_empty, color: AppColors.amber),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // Tribe assigned notification
    if (tribeProvider.hasTribe) {
      widgets.add(
        GlassCard(
          borderColor: AppColors.tealBorder,
          tintColor: AppColors.tealTint,
          child: Row(
            children: [
              const IconBadge(icon: Icons.check_circle, backgroundColor: AppColors.teal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'re in ${tribeProvider.currentTribe?.name ?? "a Tribe"}!',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${tribeProvider.memberCount} members ready to cruise together',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to tribe tab (index 2)
                },
                child: const Text('View', style: TextStyle(color: AppColors.teal)),
              ),
            ],
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Top bar: "DAY X · LOCATION" + notification bell
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SmallCapsLabel(_dayAndLineLabel(), color: AppColors.teal),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.grey),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Welcome Card with Countdown
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.appUser;
                final name = user?.name ?? 'Cruiser';

                return Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Welcome aboard, '),
                      TextSpan(text: name, style: AppTextStyles.displayItalicSpan),
                    ],
                  ),
                  style: AppTextStyles.displayMedium,
                );
              },
            ),
            const SizedBox(height: 16),

            // Days countdown (separate card)
            if (_sailing != null && !_isLoadingSailing)
              GlassCard(
                borderColor: AppColors.tealBorder,
                tintColor: AppColors.tealTint,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _sailing!.isInFinalCountdown
                          ? Icons.celebration
                          : Icons.calendar_today,
                      size: 20,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _sailing!.countdownMessage,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.teal),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Timeline Prompts
            ..._buildTimelinePrompts(),

            // Cruise Memories Card
            if (_sailing != null && _sailing!.hasDeparted)
              GlassCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => context.push('/memories'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.tealTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.photo_camera, color: AppColors.teal),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cruise Memories',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Capture your journey moments!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.teal),
                      ],
                    ),
                  ),
                ),
              ),
            if (_sailing != null && _sailing!.hasDeparted)
              const SizedBox(height: 12),

            const SizedBox(height: 8),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.groups,
                    label: 'Pods',
                    value: _isLoadingPods ? '-' : '${_userPods.length}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.people,
                    label: 'Connections',
                    value: '-',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.location_on,
                    label: 'Vibes',
                    value: '-',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // My Pods Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Pods',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (!_isLoadingPods && _userPods.isEmpty)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to pod discovery
                    },
                    child: const Text('Browse Pods'),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Pods List
            if (_isLoadingPods)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_userPods.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color: AppColors.teal,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pods joined yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join pods to connect with other cruisers',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[400],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._userPods.map((pod) {
                final podColor = AppConstants.podAccentColor(pod.name);
                final icon = _getIconData(pod.icon);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: podColor.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: podColor.withValues(alpha: 0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: podColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: podColor),
                    ),
                    title: Text(
                      pod.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${pod.memberCount} members',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: Icon(Icons.chevron_right, color: podColor),
                    onTap: () {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final sailingId = authProvider.appUser?.currentSailingId;

                      if (sailingId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Sailing information not found'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Navigate to pod chat
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PodChatScreen(
                            sailingId: sailingId,
                            podId: pod.id,
                            pod: pod,
                          ),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),

            const SizedBox(height: 24),

            // Activity Feed Header
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),

            // Placeholder for future activity feed
            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: AppColors.teal,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recent activity',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[400],
                        ),
                  ),
                ],
              ),
            ),
          ],
            ),
          ),
        ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppColors.teal),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
