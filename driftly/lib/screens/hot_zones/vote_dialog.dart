import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

/// Dialog for voting on location vibe
/// Allows users to vote once per location per hour
class VoteDialog extends StatefulWidget {
  final String location;

  const VoteDialog({
    super.key,
    required this.location,
  });

  @override
  State<VoteDialog> createState() => _VoteDialogState();
}

class _VoteDialogState extends State<VoteDialog> {
  final _firestoreService = FirestoreService();

  final List<Map<String, dynamic>> _vibes = [
    {
      'name': 'Active',
      'value': 'active',
      'emoji': '⚡',
      'color': const Color(0xFFFF9800)
    }, // Orange
    {
      'name': 'Quiet',
      'value': 'quiet',
      'emoji': '🤫',
      'color': const Color(0xFF2196F3)
    }, // Blue
    {
      'name': 'Overcrowded',
      'value': 'overcrowded',
      'emoji': '😰',
      'color': const Color(0xFFF44336)
    }, // Red
    {
      'name': 'Good Vibes',
      'value': 'good_vibes',
      'emoji': '✨',
      'color': const Color(0xFF4CAF50)
    }, // Green
  ];

  String? _selectedVibe;
  bool _isSubmitting = false;

  Future<void> _submitVote() async {
    if (_selectedVibe == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vibe')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (user == null || sailingId == null) {
        throw Exception('User or sailing not found');
      }

      await _firestoreService.submitHotZoneVote(
        sailingId: sailingId,
        userId: user.uid,
        location: widget.location,
        vibe: _selectedVibe!,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true); // Return true to indicate success

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thanks for voting! Your vote for ${widget.location} has been recorded.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isSubmitting = false);

      // Extract the error message
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: Failed to submit vote: Exception: ')) {
        errorMessage = errorMessage.substring('Exception: Failed to submit vote: Exception: '.length);
      } else if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.how_to_vote,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vote on Vibe',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        widget.location,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vibe Selection
            Text(
              'What\'s the current vibe?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Vibe Options Grid
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: _vibes.map((vibe) {
                final isSelected = _selectedVibe == vibe['value'];
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVibe = vibe['value'] as String;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (vibe['color'] as Color).withOpacity(0.15)
                          : Colors.grey[100],
                      border: Border.all(
                        color: isSelected
                            ? (vibe['color'] as Color)
                            : Colors.grey[300]!,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          vibe['emoji'] as String,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          vibe['name'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? (vibe['color'] as Color)
                                : Colors.grey[700],
                          ),
                        ),
                      ],
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
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can vote once per hour per location',
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
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitVote,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Vote'),
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
