import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/tribe_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/pod.dart';
import '../../../models/sailing.dart';
import '../../../utils/constants.dart';
import '../../../widgets/app_background.dart';
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
        Card(
          color: Colors.amber[900]?.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Complete Your Profile',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                TextButton(
                  onPressed: () => context.go('/onboarding/photos'),
                  child: const Text('Add Photos'),
                ),
              ],
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // Tribe matching info (Day 25 or less, no tribe yet)
    if (_sailing!.shouldTriggerTribeMatching && !tribeProvider.hasTribe) {
      widgets.add(
        Card(
          color: Colors.purple[900]?.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.diversity_3, color: Colors.purple[300]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tribe Matching Active',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                Icon(Icons.hourglass_empty, color: Colors.purple[300]),
              ],
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    // Tribe assigned notification
    if (tribeProvider.hasTribe) {
      widgets.add(
        Card(
          color: Colors.green[900]?.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green[400]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You\'re in ${tribeProvider.currentTribe?.name ?? "a Tribe"}!',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${tribeProvider.memberCount} members ready to cruise together',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to tribe tab (index 2)
                  },
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        ),
      );
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  /// Get pod color from name
  Color _getPodColor(String podName) {
    final colorHex = AppConstants.podColors[podName];
    if (colorHex != null) {
      return _parseColor(colorHex);
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Driftly'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: AppBackground(
        overlayOpacity: 0.7,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Welcome Card with Countdown
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.appUser;
                final name = user?.name ?? 'Cruiser';

                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Welcome aboard, $name!',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            const Text('🚢', style: TextStyle(fontSize: 32)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_sailing != null && !_isLoadingSailing) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _sailing!.isInFinalCountdown
                                  ? Colors.orange.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _sailing!.isInFinalCountdown
                                      ? Icons.celebration
                                      : Icons.calendar_today,
                                  size: 16,
                                  color: _sailing!.isInFinalCountdown
                                      ? Colors.orange[800]
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _sailing!.countdownMessage,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _sailing!.isInFinalCountdown
                                        ? Colors.orange[800]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Ready to connect with your cruise crew',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Timeline Prompts
            ..._buildTimelinePrompts(),

            // Cruise Memories Card
            if (_sailing != null && _sailing!.hasDeparted)
              Card(
                color: Colors.indigo[900]?.withOpacity(0.3),
                child: InkWell(
                  onTap: () => context.push('/memories'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_camera, color: Colors.indigo),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cruise Memories',
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
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
                    label: 'Hangouts',
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pods joined yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join pods to connect with other cruisers',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._userPods.map((pod) {
                final podColor = _getPodColor(pod.name);
                final icon = _getIconData(pod.icon);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: podColor.withOpacity(0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: podColor.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: podColor.withOpacity(0.3),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent activity',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
            ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
