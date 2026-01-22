import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

/// Dialog for creating a new micro hangout
/// Allows users to select location and vibe
class CreateHangoutDialog extends StatefulWidget {
  const CreateHangoutDialog({super.key});

  @override
  State<CreateHangoutDialog> createState() => _CreateHangoutDialogState();
}

class _CreateHangoutDialogState extends State<CreateHangoutDialog> {
  final _firestoreService = FirestoreService();

  // Fixed locations as per requirements
  final List<Map<String, dynamic>> _locations = [
    {'name': 'Pool Deck', 'icon': Icons.pool},
    {'name': 'Sports Court', 'icon': Icons.sports_tennis},
    {'name': 'Nightclub', 'icon': Icons.nightlife},
    {'name': 'Atrium', 'icon': Icons.domain},
    {'name': 'Buffet', 'icon': Icons.restaurant},
    {'name': 'Coffee Bar', 'icon': Icons.local_cafe},
  ];

  final List<Map<String, dynamic>> _vibes = [
    {'name': 'Chill', 'value': 'chill', 'emoji': '😌', 'color': Colors.blue},
    {'name': 'Lively', 'value': 'lively', 'emoji': '🎉', 'color': Colors.orange},
    {'name': 'Party', 'value': 'party', 'emoji': '🔥', 'color': Colors.red},
  ];

  String? _selectedLocation;
  String _selectedVibe = 'chill';
  bool _isCreating = false;

  Future<void> _createHangout() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (user == null || sailingId == null) {
        throw Exception('User or sailing not found');
      }

      await _firestoreService.createMicroHangout(
        sailingId: sailingId,
        location: _selectedLocation!,
        createdBy: user.uid,
        createdByName: user.name,
        createdByAgeBand: user.ageBand,
        vibe: _selectedVibe,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true); // Return true to indicate success

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You\'re now at $_selectedLocation! Others can find you for the next 45 minutes.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isCreating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create hangout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I\'m Here!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Let others know where you are',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Location Selection
            Text(
              'Where are you?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _locations.map((location) {
                final isSelected = _selectedLocation == location['name'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        location['icon'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 6),
                      Text(location['name'] as String),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedLocation = selected ? location['name'] as String : null;
                    });
                  },
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Vibe Selection
            Text(
              'What\'s the vibe?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _vibes.map((vibe) {
                final isSelected = _selectedVibe == vibe['value'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            vibe['emoji'] as String,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vibe['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedVibe = vibe['value'] as String;
                        });
                      },
                      selectedColor: vibe['color'] as Color,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your hangout will be visible for 45 minutes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createHangout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create Hangout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
