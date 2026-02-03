import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/pod.dart';
import '../../chat/pod_chat_screen.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/error_state.dart';
import '../../../widgets/empty_state.dart';

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

  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
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
    } else if (name.contains('casino')) {
      return Icons.casino;
    }
    return Icons.groups;
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
      body: RefreshIndicator(
        onRefresh: _loadUserPods,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to browse/join pods screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Browse pods coming soon!')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Join Pod'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ShimmerLoading(itemCount: 3);
    }

    if (_error != null) {
      return ErrorStateWidget(
        message: _error!,
        onRetry: _loadUserPods,
      );
    }

    if (_userPods == null || _userPods!.isEmpty) {
      return const EmptyStateWidget(
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                pod.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Unread badge placeholder - TODO: implement with real unread count
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              pod.description,
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
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _openPodChat(pod),
      ),
    );
  }
}
