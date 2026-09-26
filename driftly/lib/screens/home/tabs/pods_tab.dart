import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/pod.dart';
import '../../chat/pod_chat_screen.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/error_state.dart' as error_widget;
import '../../../widgets/empty_state.dart' as empty_widget;
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/icon_badge.dart';

/// Pods Tab
///
/// Features:
/// - List of user's joined pods with real Firestore data
/// - Pod chat preview
/// - Unread message badges
/// - Pod member count
/// - Tap to open full pod chat screen
class PodsTab extends StatefulWidget {
  const PodsTab({super.key});

  @override
  State<PodsTab> createState() => _PodsTabState();
}

class _PodsTabState extends State<PodsTab> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Pod>? _userPods;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserPods();
  }

  Future<void> _loadUserPods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;

      if (user == null || user.currentSailingId == null) {
        setState(() {
          _userPods = [];
          _isLoading = false;
        });
        return;
      }

      final pods = await _firestoreService.getUserPodsForSailing(
        sailingId: user.currentSailingId!,
        userId: user.uid,
      );

      setState(() {
        _userPods = pods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  IconData _getIconForPod(String podName) {
    final name = podName.toLowerCase();
    if (name.contains('nightlife') || name.contains('party')) {
      return Icons.nightlife;
    } else if (name.contains('gym') || name.contains('fitness')) {
      return Icons.fitness_center;
    } else if (name.contains('excursion') || name.contains('explore')) {
      return Icons.explore;
    } else if (name.contains('sport') || name.contains('game')) {
      return Icons.sports_basketball;
    } else if (name.contains('drink') || name.contains('chill')) {
      return Icons.local_bar;
    } else if (name.contains('food') || name.contains('dining')) {
      return Icons.restaurant;
    } else if (name.contains('music')) {
      return Icons.music_note;
    } else if (name.contains('photo')) {
      return Icons.camera_alt;
    } else if (name.contains('relax') || name.contains('spa')) {
      return Icons.spa;
    } else if (name.contains('casino') || name.contains('high roller')) {
      return Icons.casino;
    }
    return Icons.groups;
  }

  // Helper to parse color from hex string — matches the color used inside
  // pod_chat_screen.dart and choose_pods_screen.dart so pods look the same
  // color everywhere.
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return AppColors.teal;
    }
  }

  void _openPodChat(Pod pod) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser;

    if (user == null || user.currentSailingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sailing first')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PodChatScreen(
          sailingId: user.currentSailingId!,
          podId: pod.id,
          pod: pod,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Pods', style: AppTextStyles.displaySmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserPods,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        children: const [
          ShimmerListItem(),
          ShimmerListItem(),
          ShimmerListItem(),
        ],
      );
    }

    if (_error != null) {
      return error_widget.ErrorState(
        message: _error!,
        onRetry: _loadUserPods,
      );
    }

    if (_userPods == null || _userPods!.isEmpty) {
      return empty_widget.EmptyState(
        icon: Icons.groups_outlined,
        title: 'No pods yet',
        message: 'Join pods to connect with cruisers who share your interests',
      );
    }

    return ListView.builder(
      itemCount: _userPods!.length,
      itemBuilder: (context, index) {
        final pod = _userPods![index];
        return _buildPodCard(context, pod);
      },
    );
  }

  Widget _buildPodCard(BuildContext context, Pod pod) {
    final color = _parseColor(pod.color);
    final icon = _getIconForPod(pod.name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: GlassCard(
        padding: EdgeInsets.zero,
        borderColor: color.withValues(alpha: 0.4),
        tintColor: color.withValues(alpha: 0.12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: IconBadge(icon: icon, backgroundColor: color, size: 56, borderRadius: 16),
          title: Text(
            pod.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                pod.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[300]),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '${pod.memberCount} members',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
          onTap: () => _openPodChat(pod),
        ),
      ),
    );
  }
}
