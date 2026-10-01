import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../models/cruise_memory.dart';
import '../../models/sailing.dart';
import 'add_memory_dialog.dart';

/// Cruise Memories Screen
/// 
/// Displays a timeline of photos from the user's cruise experience
/// with milestone markers for boarding, daily highlights, and disembarking
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final _firestoreService = FirestoreService();
  List<CruiseMemory> _memories = [];
  Sailing? _sailing;
  bool _isLoading = true;
  int _cruiseDuration = 7;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser;
      final sailingId = user?.currentSailingId;

      if (user == null || sailingId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Load sailing info
      final sailing = await _firestoreService.getSailing(sailingId);
      
      // Calculate cruise duration
      int duration = 7;
      if (sailing != null && sailing.returnDate != null) {
        duration = sailing.returnDate!.difference(sailing.departureDate).inDays;
      }

      // Load memories
      final memories = await _firestoreService.getUserMemories(
        sailingId: sailingId,
        userId: user.uid,
      );

      setState(() {
        _sailing = sailing;
        _memories = memories;
        _cruiseDuration = duration;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  MemoryMilestone? _getCurrentMilestone() {
    if (_sailing == null) return null;

    final now = DateTime.now();
    final departure = _sailing!.departureDate;
    final returnDate = _sailing!.returnDate ?? departure.add(Duration(days: _cruiseDuration));

    // Before departure
    if (now.isBefore(departure)) {
      return null;
    }

    // Boarding day
    if (now.year == departure.year && 
        now.month == departure.month && 
        now.day == departure.day) {
      return MemoryMilestone.boarding;
    }

    // During cruise
    final daysSinceDeparture = now.difference(departure).inDays;
    if (daysSinceDeparture > 0 && daysSinceDeparture < _cruiseDuration) {
      // Return the appropriate day milestone
      switch (daysSinceDeparture) {
        case 1: return MemoryMilestone.day1;
        case 2: return MemoryMilestone.day2;
        case 3: return MemoryMilestone.day3;
        case 4: return MemoryMilestone.day4;
        case 5: return MemoryMilestone.day5;
        case 6: return MemoryMilestone.day6;
        default: return MemoryMilestone.day7;
      }
    }

    // Disembarking day
    if (now.year == returnDate.year && 
        now.month == returnDate.month && 
        now.day == returnDate.day) {
      return MemoryMilestone.disembarking;
    }

    // After return - back home
    if (now.isAfter(returnDate)) {
      return MemoryMilestone.backHome;
    }

    return null;
  }

  /// Each milestone's own real calendar date — boarding = departure day,
  /// dayN = departure + N, disembarking = return day, backHome = the day
  /// after. Used instead of `_getCurrentMilestone` for tap-gating, so a
  /// user can catch up on a day they missed instead of only ever being
  /// able to add a photo for the single milestone matching today exactly.
  DateTime? _dateForMilestone(MemoryMilestone milestone) {
    if (_sailing == null) return null;

    final departure = _sailing!.departureDate;
    final returnDate = _sailing!.returnDate ?? departure.add(Duration(days: _cruiseDuration));

    switch (milestone) {
      case MemoryMilestone.boarding:
        return departure;
      case MemoryMilestone.day1:
        return departure.add(const Duration(days: 1));
      case MemoryMilestone.day2:
        return departure.add(const Duration(days: 2));
      case MemoryMilestone.day3:
        return departure.add(const Duration(days: 3));
      case MemoryMilestone.day4:
        return departure.add(const Duration(days: 4));
      case MemoryMilestone.day5:
        return departure.add(const Duration(days: 5));
      case MemoryMilestone.day6:
        return departure.add(const Duration(days: 6));
      case MemoryMilestone.day7:
        return departure.add(const Duration(days: 7));
      case MemoryMilestone.disembarking:
        return returnDate;
      case MemoryMilestone.backHome:
        return returnDate.add(const Duration(days: 1));
    }
  }

  /// Whether [milestone]'s date has been reached (today or earlier) —
  /// i.e. it's addable, not locked as a future day.
  bool _isMilestoneUnlocked(MemoryMilestone milestone) {
    final date = _dateForMilestone(milestone);
    if (date == null) return false;
    final today = DateTime.now();
    final milestoneDay = DateTime(date.year, date.month, date.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return !todayDay.isBefore(milestoneDay);
  }

  CruiseMemory? _getMemoryForMilestone(MemoryMilestone milestone) {
    try {
      return _memories.firstWhere((m) => m.milestone == milestone);
    } catch (e) {
      return null;
    }
  }

  List<MemoryMilestone> _getMilestonesForCruise() {
    final milestones = <MemoryMilestone>[MemoryMilestone.boarding];
    
    for (int i = 1; i <= _cruiseDuration && i <= 7; i++) {
      switch (i) {
        case 1: milestones.add(MemoryMilestone.day1); break;
        case 2: milestones.add(MemoryMilestone.day2); break;
        case 3: milestones.add(MemoryMilestone.day3); break;
        case 4: milestones.add(MemoryMilestone.day4); break;
        case 5: milestones.add(MemoryMilestone.day5); break;
        case 6: milestones.add(MemoryMilestone.day6); break;
        case 7: milestones.add(MemoryMilestone.day7); break;
      }
    }
    
    milestones.add(MemoryMilestone.disembarking);
    milestones.add(MemoryMilestone.backHome);
    
    return milestones;
  }

  void _showCollageView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MemoriesCollageView(memories: _memories),
      ),
    );
  }

  void _showAddMemoryDialog(MemoryMilestone milestone) {
    showDialog(
      context: context,
      builder: (context) => AddMemoryDialog(
        milestone: milestone,
        sailing: _sailing!,
        onMemoryAdded: () {
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cruise Memories'),
        actions: [
          if (_memories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: _showCollageView,
              tooltip: 'View Collage',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sailing == null
              ? _buildNoSailingState()
              : _buildMemoriesTimeline(),
    );
  }

  Widget _buildNoSailingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sailing, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No Sailing Selected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a sailing to start capturing your cruise memories!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoriesTimeline() {
    final milestones = _getMilestonesForCruise();
    final currentMilestone = _getCurrentMilestone();
    final completedCount = _memories.length;
    final totalCount = milestones.length;

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Journey',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$completedCount / $totalCount',
                      style: TextStyle(
                        color: Colors.blue[300],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalCount > 0 ? completedCount / totalCount : 0,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
              ),
            ],
          ),
        ),

        // Timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              final memory = _getMemoryForMilestone(milestone);
              final isCurrent = milestone == currentMilestone;
              final isUnlocked = _isMilestoneUnlocked(milestone);
              final isCompleted = memory != null;
              final isLast = index == milestones.length - 1;

              return _buildTimelineItem(
                milestone: milestone,
                memory: memory,
                isCurrent: isCurrent,
                isUnlocked: isUnlocked,
                isCompleted: isCompleted,
                isLast: isLast,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required MemoryMilestone milestone,
    CruiseMemory? memory,
    required bool isCurrent,
    required bool isUnlocked,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? Colors.green
                        : isCurrent
                            ? Colors.blue
                            : Colors.grey[700],
                    border: isCurrent
                        ? Border.all(color: Colors.blue, width: 3)
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            milestone.emoji,
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted ? Colors.green : Colors.grey[700],
                    ),
                  ),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                color: isCurrent
                    ? Colors.blue.withValues(alpha: 0.1)
                    : null,
                child: InkWell(
                  onTap: isUnlocked && !isCompleted
                      ? () => _showAddMemoryDialog(milestone)
                      : isCompleted
                          ? () => _showMemoryDetail(memory!)
                          : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              milestone.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (milestone.isRequired) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Required',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[300],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (isCompleted && memory != null) ...[
                          // Show photo preview
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              memory.photoUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 150,
                                color: Colors.grey[800],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          if (memory.caption != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              memory.caption!,
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ] else if (isUnlocked) ...[
                          // Show prompt to add photo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.camera_alt, color: Colors.blue[300]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        milestone.promptMessage,
                                        style: TextStyle(color: Colors.blue[300]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap to add photo',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // Future milestone
                          Text(
                            milestone.promptMessage,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemoryDetail(CruiseMemory memory) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                memory.photoUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        memory.milestone.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        memory.milestone.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  if (memory.caption != null) ...[
                    const SizedBox(height: 8),
                    Text(memory.caption!),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collage View
///
/// Grid layout of all of the user's cruise memory photos, reusing the same
/// [CruiseMemory] list already loaded by [MemoriesScreen]. Tap a photo to
/// view it full-size with its caption.
class _MemoriesCollageView extends StatelessWidget {
  final List<CruiseMemory> memories;

  const _MemoriesCollageView({required this.memories});

  void _showFullPhoto(BuildContext context, CruiseMemory memory) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  memory.photoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: Colors.grey[900],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
            if (memory.caption != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  memory.caption!,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Collage')),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: memories.length,
        itemBuilder: (context, index) {
          final memory = memories[index];
          return GestureDetector(
            onTap: () => _showFullPhoto(context, memory),
            child: Image.network(
              memory.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[850],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
