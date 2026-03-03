import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement_badge.dart';

/// BadgeService
///
/// Handles all badge-related operations including:
/// - Checking and awarding badges
/// - Tracking progress towards badges
/// - Retrieving user badges
class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get badges collection for a user
  CollectionReference badgesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('badges');
  }

  /// Get user stats collection for tracking badge progress
  DocumentReference userStatsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('stats').doc('badge_progress');
  }

  /// Get all badges for a user
  Future<List<AchievementBadge>> getUserBadges(String userId) async {
    try {
      final querySnapshot = await badgesCollection(userId)
          .orderBy('earnedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AchievementBadge.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user badges: $e');
    }
  }

  /// Stream user badges for real-time updates
  Stream<List<AchievementBadge>> streamUserBadges(String userId) {
    return badgesCollection(userId)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AchievementBadge.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    });
  }

  /// Get badge progress stats for a user
  Future<Map<String, int>> getBadgeProgress(String userId) async {
    try {
      final doc = await userStatsRef(userId).get();
      if (!doc.exists) {
        return _defaultStats;
      }
      final data = doc.data() as Map<String, dynamic>;
      return Map<String, int>.from(data.map((key, value) => MapEntry(key, value as int)));
    } catch (e) {
      return _defaultStats;
    }
  }

  /// Default stats for new users
  Map<String, int> get _defaultStats => {
        'hangouts_created': 0,
        'hangouts_joined': 0,
        'photos_shared': 0,
        'pods_joined': 0,
        'messages_sent': 0,
        'hot_zones_voted': 0,
        'daily_prompts_answered': 0,
        'unique_locations': 0,
      };

  /// Increment a stat and check for badge eligibility
  Future<AchievementBadge?> incrementStat({
    required String userId,
    required String statName,
    int amount = 1,
  }) async {
    try {
      // Update the stat
      await userStatsRef(userId).set(
        {statName: FieldValue.increment(amount)},
        SetOptions(merge: true),
      );

      // Get updated stats
      final stats = await getBadgeProgress(userId);

      // Check for new badges
      return await _checkAndAwardBadges(userId, stats);
    } catch (e) {
      throw Exception('Failed to increment stat: $e');
    }
  }

  /// Check for and award any earned badges
  Future<AchievementBadge?> _checkAndAwardBadges(
    String userId,
    Map<String, int> stats,
  ) async {
    // Get existing badge types
    final existingBadges = await getUserBadges(userId);
    final existingTypes = existingBadges.map((b) => b.type).toSet();

    // Check each badge definition
    for (final badgeInfo in BadgeDefinitions.allBadges) {
      // Skip if already earned
      if (existingTypes.contains(badgeInfo.type)) continue;

      // Check if badge should be awarded
      final shouldAward = _checkBadgeEligibility(badgeInfo.type, stats);

      if (shouldAward) {
        // Award the badge
        final badge = AchievementBadge(
          id: '',
          userId: userId,
          type: badgeInfo.type,
          name: badgeInfo.name,
          description: badgeInfo.description,
          icon: badgeInfo.icon,
          earnedAt: DateTime.now(),
          progress: badgeInfo.target,
          target: badgeInfo.target,
        );

        await badgesCollection(userId).add(badge.toMap());
        return badge; // Return newly earned badge for UI feedback
      }
    }

    return null;
  }

  /// Check if a specific badge should be awarded
  bool _checkBadgeEligibility(String badgeType, Map<String, int> stats) {
    switch (badgeType) {
      // Hangout badges
      case 'first_hangout':
        return (stats['hangouts_created'] ?? 0) >= 1;
      case 'hangouts_5':
        return (stats['hangouts_created'] ?? 0) >= 5;
      case 'hangouts_joined_10':
        return (stats['hangouts_joined'] ?? 0) >= 10;

      // Photo badges
      case 'first_photo':
        return (stats['photos_shared'] ?? 0) >= 1;
      case 'photos_10':
        return (stats['photos_shared'] ?? 0) >= 10;

      // Pod badges
      case 'first_pod':
        return (stats['pods_joined'] ?? 0) >= 1;
      case 'pods_3':
        return (stats['pods_joined'] ?? 0) >= 3;
      case 'messages_50':
        return (stats['messages_sent'] ?? 0) >= 50;

      // Exploration badges
      case 'hot_zones_voted_5':
        return (stats['hot_zones_voted'] ?? 0) >= 5;
      case 'daily_prompts_7':
        return (stats['daily_prompts_answered'] ?? 0) >= 7;

      // Achievement badges
      case 'all_locations':
        return (stats['unique_locations'] ?? 0) >= 5;

      default:
        return false;
    }
  }

  /// Award a specific badge directly (for special achievements)
  Future<AchievementBadge?> awardBadge({
    required String userId,
    required String badgeType,
  }) async {
    try {
      // Check if already earned
      final existingBadges = await getUserBadges(userId);
      if (existingBadges.any((b) => b.type == badgeType)) {
        return null; // Already has this badge
      }

      // Get badge info
      final badgeInfo = BadgeDefinitions.getBadgeInfo(badgeType);
      if (badgeInfo == null) return null;

      // Create and save badge
      final badge = AchievementBadge(
        id: '',
        userId: userId,
        type: badgeInfo.type,
        name: badgeInfo.name,
        description: badgeInfo.description,
        icon: badgeInfo.icon,
        earnedAt: DateTime.now(),
        progress: badgeInfo.target,
        target: badgeInfo.target,
      );

      await badgesCollection(userId).add(badge.toMap());
      return badge;
    } catch (e) {
      throw Exception('Failed to award badge: $e');
    }
  }

  /// Get badge count for a user
  Future<int> getBadgeCount(String userId) async {
    try {
      final snapshot = await badgesCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Get all available badges with user's progress
  Future<List<Map<String, dynamic>>> getAllBadgesWithProgress(String userId) async {
    final earnedBadges = await getUserBadges(userId);
    final stats = await getBadgeProgress(userId);
    final earnedTypes = earnedBadges.map((b) => b.type).toSet();

    return BadgeDefinitions.allBadges.map((badgeInfo) {
      final isEarned = earnedTypes.contains(badgeInfo.type);
      final progress = _getProgressForBadge(badgeInfo.type, stats);

      return {
        'info': badgeInfo,
        'isEarned': isEarned,
        'progress': progress,
        'earnedBadge': isEarned
            ? earnedBadges.firstWhere((b) => b.type == badgeInfo.type)
            : null,
      };
    }).toList();
  }

  /// Get current progress for a specific badge type
  int _getProgressForBadge(String badgeType, Map<String, int> stats) {
    switch (badgeType) {
      case 'first_hangout':
      case 'hangouts_5':
        return stats['hangouts_created'] ?? 0;
      case 'hangouts_joined_10':
        return stats['hangouts_joined'] ?? 0;
      case 'first_photo':
      case 'photos_10':
        return stats['photos_shared'] ?? 0;
      case 'first_pod':
      case 'pods_3':
        return stats['pods_joined'] ?? 0;
      case 'messages_50':
        return stats['messages_sent'] ?? 0;
      case 'hot_zones_voted_5':
        return stats['hot_zones_voted'] ?? 0;
      case 'daily_prompts_7':
        return stats['daily_prompts_answered'] ?? 0;
      case 'all_locations':
        return stats['unique_locations'] ?? 0;
      default:
        return 0;
    }
  }
}
