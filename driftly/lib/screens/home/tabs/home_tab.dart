import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tribe_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/badge_service.dart';
import '../../../services/connection_service.dart';
import '../../../models/pod.dart';
import '../../../models/sailing.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/icon_badge.dart';
import '../../../widgets/pill_button.dart';
import '../../../widgets/small_caps_label.dart';
import '../../settings/notification_preferences_screen.dart';
import 'first_mates_section.dart';

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
  final _badgeService = BadgeService();
  final _connectionService = ConnectionService();
  List<Pod> _userPods = [];
  Sailing? _sailing;
  int _hotZonesVoted = 0;
  int _connectionsCount = 0;
  bool _isLoadingPods = true;
  bool _isLoadingSailing = true;
  bool _isLoadingVibes = true;
  bool _isLoadingConnections = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserPods(),
      _loadSailing(),
      _loadVibesCount(),
      _loadConnectionsCount(),
    ]);
  }

  Future<void> _loadConnectionsCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (user == null || sailingId == null) {
        setState(() => _isLoadingConnections = false);
        return;
      }

      final connections = await _connectionService
          .streamAcceptedConnections(sailingId, user.uid)
          .first;
      setState(() {
        _connectionsCount = connections.length;
        _isLoadingConnections = false;
      });
    } catch (e) {
      setState(() => _isLoadingConnections = false);
    }
  }

  Future<void> _loadVibesCount() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      if (user == null) {
        setState(() => _isLoadingVibes = false);
        return;
      }

      final stats = await _badgeService.getBadgeProgress(user.uid);
      setState(() {
        _hotZonesVoted = stats['hot_zones_voted'] ?? 0;
        _isLoadingVibes = false;
      });
    } catch (e) {
      setState(() => _isLoadingVibes = false);
    }
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
          borderColor: AppColors.goldBorder,
          tintColor: AppColors.goldTint,
          padding: EdgeInsets.zero,
          child: InkWell(
            onTap: () => context.go('/home?tab=tribe'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const IconBadge(icon: Icons.diversity_3, backgroundColor: AppColors.gold),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tribe Matching Active',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
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
                ],
              ),
            ),
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
                onPressed: () => context.go('/home?tab=tribe'),
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
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationPreferencesScreen(),
                    ),
                  ),
                  child: Stack(
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
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => context.go('/home?tab=profile'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                    value: _isLoadingConnections ? '-' : '$_connectionsCount',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.location_on,
                    label: 'Vibes',
                    value: _isLoadingVibes ? '-' : '$_hotZonesVoted',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // First Mates — pod-only 1:1 connect requests + messaging
            const FirstMatesSection(),
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
