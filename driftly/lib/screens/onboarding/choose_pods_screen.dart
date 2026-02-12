import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/pod.dart';

/// Choose Pods Screen
///
/// User selects 1-3 Pods to join
/// Loads pods from Firestore for the current sailing
/// Creates pod memberships when user confirms selection
///
/// After selection → /home (complete onboarding)
class ChoosePodsScreen extends StatefulWidget {
  const ChoosePodsScreen({super.key});

  @override
  State<ChoosePodsScreen> createState() => _ChoosePodsScreenState();
}

class _ChoosePodsScreenState extends State<ChoosePodsScreen> {
  final _firestoreService = FirestoreService();
  List<Pod> _pods = [];
  final Set<String> _selectedPodIds = {};
  bool _isLoading = false;
  bool _isLoadingPods = true;

  @override
  void initState() {
    super.initState();
    _loadPods();
  }

  Future<void> _loadPods() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final sailingId = authProvider.appUser?.currentSailingId;

      if (sailingId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No sailing selected. Please go back and select a sailing.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final pods = await _firestoreService.getPodsForSailing(sailingId);

      setState(() {
        _pods = pods;
        _isLoadingPods = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoadingPods = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load pods: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _togglePod(String podId) {
    setState(() {
      if (_selectedPodIds.contains(podId)) {
        _selectedPodIds.remove(podId);
      } else {
        if (_selectedPodIds.length < 3) {
          _selectedPodIds.add(podId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You can select up to 3 pods'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  Future<void> _handleContinue() async {
    if (_selectedPodIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 pod')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (user == null || sailingId == null) {
        throw Exception('User or sailing not found');
      }

      // Join each selected pod
      for (var podId in _selectedPodIds) {
        await _firestoreService.joinPod(
          sailingId: sailingId,
          podId: podId,
          userId: user.uid,
          userName: user.name,
        );
      }

      if (!mounted) return;

      // Navigate to notification permission screen
      context.go('/onboarding/notifications');
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join pods: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

  // Helper to parse color from hex string
  Color _parseColor(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Pods'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoadingPods
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Progress Indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: LinearProgressIndicator(
                      value: 3 / 3, // Step 3 of 3
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Join your tribes',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select 1-3 pods to join. You can change these later.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedPodIds.length}/3 selected',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pods List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _pods.length,
                      itemBuilder: (context, index) {
                        final pod = _pods[index];
                        final isSelected = _selectedPodIds.contains(pod.id);
                        final color = _parseColor(pod.color);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: isSelected ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? color
                                  : Colors.grey.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.2),
                              child: Icon(_getIconData(pod.icon), color: color),
                            ),
                            title: Text(
                              pod.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(pod.description),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: color)
                                : const Icon(Icons.circle_outlined),
                            onTap: () => _togglePod(pod.id),
                          ),
                        );
                      },
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Complete Setup',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
