import 'package:cloud_firestore/cloud_firestore.dart';

/// HotZoneVote Model
///
/// Represents a user's vote on location crowd level and vibe
///
/// Firestore path: /sailings/{sailingId}/hotZoneVotes/{voteId}
class HotZoneVote {
  final String id;
  final String sailingId;
  final String location;
  final String? deck;
  final String userId;
  final String crowdLevel; // "empty", "moderate", "packed"
  final String vibe; // "chill", "lively", "party"
  final DateTime timestamp;
  final DateTime expiresAt;

  HotZoneVote({
    required this.id,
    required this.sailingId,
    required this.location,
    this.deck,
    required this.userId,
    required this.crowdLevel,
    required this.vibe,
    required this.timestamp,
    required this.expiresAt,
  });

  /// Create HotZoneVote from Firestore document
  factory HotZoneVote.fromMap(Map<String, dynamic> map, String documentId) {
    return HotZoneVote(
      id: documentId,
      sailingId: map['sailingId'] as String? ?? '',
      location: map['location'] as String? ?? '',
      deck: map['deck'] as String?,
      userId: map['userId'] as String? ?? '',
      crowdLevel: map['crowdLevel'] as String? ?? 'moderate',
      vibe: map['vibe'] as String? ?? 'chill',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 1)),
    );
  }

  /// Convert HotZoneVote to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sailingId': sailingId,
      'location': location,
      'deck': deck,
      'userId': userId,
      'crowdLevel': crowdLevel,
      'vibe': vibe,
      'timestamp': Timestamp.fromDate(timestamp),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  /// Check if vote has expired (1 hour old)
  bool get hasExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get crowd level emoji
  String get crowdEmoji {
    switch (crowdLevel) {
      case 'empty':
        return '🟢';
      case 'moderate':
        return '🟡';
      case 'packed':
        return '🔴';
      default:
        return '⚪';
    }
  }

  /// Get vibe emoji
  String get vibeEmoji {
    switch (vibe) {
      case 'chill':
        return '😌';
      case 'lively':
        return '🎉';
      case 'party':
        return '🔥';
      default:
        return '📍';
    }
  }

  /// Get crowd level display name
  String get crowdLevelDisplay {
    switch (crowdLevel) {
      case 'empty':
        return 'Empty';
      case 'moderate':
        return 'Moderate';
      case 'packed':
        return 'Packed';
      default:
        return 'Unknown';
    }
  }

  /// Get vibe display name
  String get vibeDisplay {
    switch (vibe) {
      case 'chill':
        return 'Chill';
      case 'lively':
        return 'Lively';
      case 'party':
        return 'Party';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'HotZoneVote(location: $location, crowd: $crowdLevel, vibe: $vibe, time: $timeAgo)';
  }
}
