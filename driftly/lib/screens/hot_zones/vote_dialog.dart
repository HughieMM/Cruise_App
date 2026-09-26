import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/badge_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/icon_badge.dart';

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
  final _badgeService = BadgeService();

  // Cold-to-warm: Taking an L (coldest) -> Chill (cold) -> Active (warmer)
  // -> Jammed (warmest)
  final List<Map<String, dynamic>> _vibes = [
    {
      'name': 'Taking an L',
      'value': 'quiet',
      'emoji': '🎻',
      'color': AppColors.vibeQuiet
    },
    {
      'name': 'Chill',
      'value': 'good_vibes',
      'emoji': '🧊',
      'color': AppColors.vibeChill
    },
    {
      'name': 'Active',
      'value': 'active',
      'emoji': '💥',
      'color': AppColors.vibeActive
    },
    {
      'name': 'Jammed',
      'value': 'overcrowded',
      'emoji': '🫠',
      'color': AppColors.vibeJammed
    },
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

      // Track badge progress for hot zone votes
      final newBadge = await _badgeService.incrementStat(
        userId: user.uid,
        statName: 'hot_zones_voted',
      );

      if (!mounted) return;

      Navigator.of(context).pop(true); // Return true to indicate success

      if (newBadge != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(newBadge.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Badge Earned!', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(newBadge.name),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanks for voting! Your vote for ${widget.location} has been recorded.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.tealTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.tealBorder, width: 1),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const IconBadge(icon: Icons.how_to_vote, backgroundColor: AppColors.teal),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vote on Vibe',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.location,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
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
                const Text(
                  'What\'s the current vibe?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                              ? (vibe['color'] as Color).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: isSelected
                                ? (vibe['color'] as Color)
                                : Colors.white.withValues(alpha: 0.3),
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
                                    : Colors.white,
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
                    color: AppColors.tealTint,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.tealBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.teal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can vote once every 30 minutes per location',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
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
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
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
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.black,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Text('Submit Vote'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
