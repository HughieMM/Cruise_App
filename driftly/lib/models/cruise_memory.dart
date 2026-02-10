import 'package:cloud_firestore/cloud_firestore.dart';

/// Milestone types for cruise memories
enum MemoryMilestone {
  boarding,      // Day 1 - Boarding the ship
  day1,          // Day 1 on cruise
  day2,          // Day 2 on cruise
  day3,          // Day 3 on cruise
  day4,          // Day 4 on cruise
  day5,          // Day 5 on cruise
  day6,          // Day 6 on cruise
  day7,          // Day 7 on cruise
  disembarking,  // Last day - Leaving the ship
  backHome,      // 24 hours after - Back to normal life
}

extension MemoryMilestoneExtension on MemoryMilestone {
  String get displayName {
    switch (this) {
      case MemoryMilestone.boarding:
        return 'Boarding Day';
      case MemoryMilestone.day1:
        return 'Day 1';
      case MemoryMilestone.day2:
        return 'Day 2';
      case MemoryMilestone.day3:
        return 'Day 3';
      case MemoryMilestone.day4:
        return 'Day 4';
      case MemoryMilestone.day5:
        return 'Day 5';
      case MemoryMilestone.day6:
        return 'Day 6';
      case MemoryMilestone.day7:
        return 'Day 7';
      case MemoryMilestone.disembarking:
        return 'Disembarking';
      case MemoryMilestone.backHome:
        return 'Back Home';
    }
  }

  String get emoji {
    switch (this) {
      case MemoryMilestone.boarding:
        return '🚢';
      case MemoryMilestone.day1:
      case MemoryMilestone.day2:
      case MemoryMilestone.day3:
      case MemoryMilestone.day4:
      case MemoryMilestone.day5:
      case MemoryMilestone.day6:
      case MemoryMilestone.day7:
        return '🌊';
      case MemoryMilestone.disembarking:
        return '👋';
      case MemoryMilestone.backHome:
        return '🏠';
    }
  }

  String get promptMessage {
    switch (this) {
      case MemoryMilestone.boarding:
        return 'Capture your excitement as you board!';
      case MemoryMilestone.day1:
      case MemoryMilestone.day2:
      case MemoryMilestone.day3:
      case MemoryMilestone.day4:
      case MemoryMilestone.day5:
      case MemoryMilestone.day6:
      case MemoryMilestone.day7:
        return 'What\'s the highlight of your day?';
      case MemoryMilestone.disembarking:
        return 'Last moments on the ship - capture the memories!';
      case MemoryMilestone.backHome:
        return 'Back to reality - how does it feel?';
    }
  }

  bool get isRequired {
    return this == MemoryMilestone.boarding ||
           this == MemoryMilestone.disembarking ||
           this == MemoryMilestone.backHome;
  }
}

/// CruiseMemory Model
/// 
/// Represents a single photo memory from a cruise
/// 
/// Firestore path: /sailings/{sailingId}/memories/{memoryId}
class CruiseMemory {
  final String id;
  final String userId;
  final String sailingId;
  final MemoryMilestone milestone;
  final String photoUrl;
  final String? caption;
  final DateTime createdAt;
  final int dayNumber; // Which day of the cruise (1-7+)

  CruiseMemory({
    required this.id,
    required this.userId,
    required this.sailingId,
    required this.milestone,
    required this.photoUrl,
    this.caption,
    required this.createdAt,
    required this.dayNumber,
  });

  factory CruiseMemory.fromMap(Map<String, dynamic> map, String documentId) {
    return CruiseMemory(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      sailingId: map['sailingId'] as String? ?? '',
      milestone: MemoryMilestone.values.firstWhere(
        (e) => e.name == map['milestone'],
        orElse: () => MemoryMilestone.day1,
      ),
      photoUrl: map['photoUrl'] as String? ?? '',
      caption: map['caption'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dayNumber: map['dayNumber'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sailingId': sailingId,
      'milestone': milestone.name,
      'photoUrl': photoUrl,
      'caption': caption,
      'createdAt': Timestamp.fromDate(createdAt),
      'dayNumber': dayNumber,
    };
  }

  CruiseMemory copyWith({
    String? id,
    String? userId,
    String? sailingId,
    MemoryMilestone? milestone,
    String? photoUrl,
    String? caption,
    DateTime? createdAt,
    int? dayNumber,
  }) {
    return CruiseMemory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sailingId: sailingId ?? this.sailingId,
      milestone: milestone ?? this.milestone,
      photoUrl: photoUrl ?? this.photoUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      dayNumber: dayNumber ?? this.dayNumber,
    );
  }
}

/// Collection of memories for a user's sailing
class UserSailingMemories {
  final String userId;
  final String sailingId;
  final List<CruiseMemory> memories;
  final int cruiseDuration; // Number of days

  UserSailingMemories({
    required this.userId,
    required this.sailingId,
    required this.memories,
    required this.cruiseDuration,
  });

  /// Get memory for a specific milestone
  CruiseMemory? getMemoryForMilestone(MemoryMilestone milestone) {
    try {
      return memories.firstWhere((m) => m.milestone == milestone);
    } catch (e) {
      return null;
    }
  }

  /// Check if all required milestones are completed
  bool get hasAllRequiredMemories {
    return memories.any((m) => m.milestone == MemoryMilestone.boarding) &&
           memories.any((m) => m.milestone == MemoryMilestone.disembarking) &&
           memories.any((m) => m.milestone == MemoryMilestone.backHome);
  }

  /// Get completion percentage
  double get completionPercentage {
    // Required: boarding, disembarking, backHome = 3
    // Optional: days during cruise
    final totalSlots = 3 + cruiseDuration;
    return memories.length / totalSlots;
  }

  /// Get list of milestones that are still pending
  List<MemoryMilestone> get pendingMilestones {
    final completed = memories.map((m) => m.milestone).toSet();
    return MemoryMilestone.values.where((m) => !completed.contains(m)).toList();
  }
}
