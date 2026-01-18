import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Choose Pods Screen
///
/// User selects 1-3 Pods to join:
/// - Gym Crew
/// - Nightlife Crew
/// - Chill
/// - Excursions
/// - Sports & Games
///
/// After selection → /home (complete onboarding)
///
/// TODO: Save pod selections to Firestore
/// TODO: Create pod memberships in Firestore
class ChoosePodsScreen extends StatefulWidget {
  const ChoosePodsScreen({super.key});

  @override
  State<ChoosePodsScreen> createState() => _ChoosePodsScreenState();
}

class _ChoosePodsScreenState extends State<ChoosePodsScreen> {
  final List<PodOption> _pods = [
    PodOption(
      id: 'gym_crew',
      name: 'Gym Crew',
      description: 'Early morning workouts and fitness challenges',
      icon: Icons.fitness_center,
      color: Colors.red,
    ),
    PodOption(
      id: 'nightlife_crew',
      name: 'Nightlife Crew',
      description: 'Late nights, dancing, and parties',
      icon: Icons.nightlife,
      color: Colors.purple,
    ),
    PodOption(
      id: 'chill',
      name: 'Chill',
      description: 'Relaxation, spa days, and quiet hangouts',
      icon: Icons.spa,
      color: Colors.blue,
    ),
    PodOption(
      id: 'excursions',
      name: 'Excursions',
      description: 'Shore excursions and adventure activities',
      icon: Icons.explore,
      color: Colors.green,
    ),
    PodOption(
      id: 'sports_games',
      name: 'Sports & Games',
      description: 'Competitive games and sports tournaments',
      icon: Icons.sports_basketball,
      color: Colors.orange,
    ),
  ];

  final Set<String> _selectedPodIds = {};

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

  void _handleContinue() {
    if (_selectedPodIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 pod')),
      );
      return;
    }

    // TODO: Save pod selections to Firestore
    // Complete onboarding → Navigate to home
    context.go('/home');
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
        child: Column(
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? pod.color
                            : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: pod.color.withOpacity(0.2),
                        child: Icon(pod.icon, color: pod.color),
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
                          ? Icon(Icons.check_circle, color: pod.color)
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
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text(
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

/// Pod Option Data Class
class PodOption {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  PodOption({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
