import 'package:cloud_firestore/cloud_firestore.dart';

/// AchievementBadge Model
///
/// Represents an achievement badge earned by the user
///
/// Firestore path: /users/{userId}/badges/{badgeId}
class AchievementBadge {
  final String id;
  final String userId;
  final String type; // Badge type identifier
  final String name;
  final String description;
  final String icon; // Icon name or emoji
  final DateTime earnedAt;
  final int progress; // Progress towards badge (for progressive badges)
  final int target; // Target to unlock badge

  AchievementBadge({
    required this.id,
    required this.userId,
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.progress = 0,
    this.target = 1,
  });

  /// Create AchievementBadge from Firestore document
  factory AchievementBadge.fromMap(Map<String, dynamic> map, String documentId) {
    return AchievementBadge(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '',
      earnedAt: (map['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: map['progress'] as int? ?? 0,
      target: map['target'] as int? ?? 1,
    );
  }

  /// Convert AchievementBadge to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'name': name,
      'description': description,
      'icon': icon,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'progress': progress,
      'target': target,
    };
  }

  /// Check if badge is fully unlocked
  bool get isUnlocked => progress >= target;

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercent => target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

  AchievementBadge copyWith({
    String? id,
    String? userId,
    String? type,
    String? name,
    String? description,
    String? icon,
    DateTime? earnedAt,
    int? progress,
    int? target,
  }) {
    return AchievementBadge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      earnedAt: earnedAt ?? this.earnedAt,
      progress: progress ?? this.progress,
      target: target ?? this.target,
    );
  }

  @override
  String toString() {
    return 'AchievementBadge(id: $id, name: $name, type: $type, progress: $progress/$target)';
  }
}

/// Badge definitions and requirements
class BadgeDefinitions {
  BadgeDefinitions._();

  /// All available badge types
  static const List<BadgeInfo> allBadges = [
    // Beta badge — awarded directly on account creation, not stat-based.
    BadgeInfo(
      type: 'beta_tester',
      name: 'Beta Crew',
      description: 'Joined Driftly during the beta',
      icon: '🚢',
      target: 1,
    ),

    // Memory badges
    BadgeInfo(
      type: 'first_memory',
      name: 'Memory Keeper',
      description: 'Save your first cruise memory',
      icon: '📸',
      target: 1,
    ),
    BadgeInfo(
      type: 'memories_5',
      name: 'Storyteller',
      description: 'Save 5 cruise memories',
      icon: '📖',
      target: 5,
    ),

    // Tribe chat badges
    BadgeInfo(
      type: 'first_tribe_message',
      name: 'Tribe Talker',
      description: 'Send your first tribe message',
      icon: '💌',
      target: 1,
    ),
    BadgeInfo(
      type: 'tribe_messages_25',
      name: 'Tribe MVP',
      description: 'Send 25 tribe messages',
      icon: '🌟',
      target: 25,
    ),

    // Pod badges
    BadgeInfo(
      type: 'first_pod',
      name: 'Pod Pioneer',
      description: 'Join your first pod',
      icon: '🚀',
      target: 1,
    ),
    BadgeInfo(
      type: 'pods_3',
      name: 'Community Builder',
      description: 'Join 3 different pods',
      icon: '🏘️',
      target: 3,
    ),
    BadgeInfo(
      type: 'messages_50',
      name: 'Chatterbox',
      description: 'Send 50 messages in pods',
      icon: '💬',
      target: 50,
    ),

    // Exploration badges
    BadgeInfo(
      type: 'hot_zones_voted_5',
      name: 'Vibe Reporter',
      description: 'Vote on 5 hot zones',
      icon: '📊',
      target: 5,
    ),
    BadgeInfo(
      type: 'daily_prompts_7',
      name: 'Prompt Master',
      description: 'Answer 7 daily prompts',
      icon: '✍️',
      target: 7,
    ),

    // Achievement badges
    BadgeInfo(
      type: 'first_day',
      name: 'Welcome Aboard',
      description: 'Complete your first day on the cruise',
      icon: '⚓',
      target: 1,
    ),
    BadgeInfo(
      type: 'hot_zones_voted_15',
      name: 'Ship Explorer',
      description: 'Vote on 15 hot zones',
      icon: '🗺️',
      target: 15,
    ),
    BadgeInfo(
      type: 'tribe_formed',
      name: 'Tribe Leader',
      description: 'Form a cruise tribe with 3+ members',
      icon: '👑',
      target: 1,
    ),
  ];

  /// Get badge info by type
  static BadgeInfo? getBadgeInfo(String type) {
    try {
      return allBadges.firstWhere((badge) => badge.type == type);
    } catch (_) {
      return null;
    }
  }
}

/// Badge information (static definition)
class BadgeInfo {
  final String type;
  final String name;
  final String description;
  final String icon;
  final int target;

  const BadgeInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.target,
  });
}
