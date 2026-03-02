import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/constants.dart';

/// Dialog for creating a new micro hangout
/// Allows users to select location and vibe
class CreateHangoutDialog extends StatefulWidget {
  const CreateHangoutDialog({super.key});

  @override
  State<CreateHangoutDialog> createState() => _CreateHangoutDialogState();
}

class _CreateHangoutDialogState extends State<CreateHangoutDialog> {
  final _firestoreService = FirestoreService();

  // Fixed locations with their category colors
  final List<Map<String, dynamic>> _locations = [
    {'name': 'Pool', 'icon': Icons.pool, 'category': 'Pool'},
    {'name': 'Sports Court', 'icon': Icons.sports_tennis, 'category': 'Gym'},
    {'name': 'Nightclub', 'icon': Icons.nightlife, 'category': 'Bar'},
    {'name': 'Atrium', 'icon': Icons.domain, 'category': 'Other'},
    {'name': 'Buffet', 'icon': Icons.restaurant, 'category': 'Restaurant'},
    {'name': 'Coffee Bar', 'icon': Icons.local_cafe, 'category': 'Restaurant'},
    {'name': 'Casino', 'icon': Icons.casino, 'category': 'Casino'},
    {'name': 'Spa', 'icon': Icons.spa, 'category': 'Spa'},
    {'name': 'Theatre', 'icon': Icons.theater_comedy, 'category': 'Theatre'},
    {'name': 'Shore Excursion', 'icon': Icons.beach_access, 'category': 'Shore Excursion'},
  ];

  // Get vibe color from constants
  Color _getVibeColor(String vibe) {
    final hexColor = AppConstants.hangoutMoodColors[vibe];
    if (hexColor != null) {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.blue;
  }

  // Get location color from constants
  Color _getLocationColor(String category) {
    final hexColor = AppConstants.hangoutCategoryColors[category];
    if (hexColor != null) {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.grey;
  }

  final List<Map<String, dynamic>> _vibes = [
    {'name': 'Chill', 'value': 'chill', 'emoji': '😌'},
    {'name': 'Lively', 'value': 'lively', 'emoji': '🎉'},
    {'name': 'Party', 'value': 'party', 'emoji': '🔥'},
    {'name': 'Adventure', 'value': 'adventurous', 'emoji': '🌊'},
    {'name': 'Social', 'value': 'social', 'emoji': '💬'},
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

            // Scrollable content section
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        final locationColor = _getLocationColor(location['category'] as String);
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                location['icon'] as IconData,
                                size: 18,
                                color: isSelected ? Colors.white : locationColor,
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
                          selectedColor: locationColor,
                          backgroundColor: locationColor.withOpacity(0.1),
                          side: BorderSide(color: locationColor.withOpacity(0.3)),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _vibes.map((vibe) {
                        final isSelected = _selectedVibe == vibe['value'];
                        final vibeColor = _getVibeColor(vibe['value'] as String);
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                vibe['emoji'] as String,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                vibe['name'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.grey[300],
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
                          selectedColor: vibeColor,
                          backgroundColor: vibeColor.withOpacity(0.1),
                          side: BorderSide(color: vibeColor.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Info Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.timer, color: Colors.blue[300], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your hangout will be visible for 45 minutes',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[200],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
