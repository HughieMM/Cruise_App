import 'package:cloud_firestore/cloud_firestore.dart';

/// HotZoneVote Model
///
/// Represents a user's vote on location vibe
/// Users can vote once per location every 30 minutes
///
/// Firestore path: /sailings/{sailingId}/hotZoneVotes/{voteId}
class HotZoneVote {
  final String id;
  final String sailingId;
  final String location;
  final String userId;
  final String vibe; // "active", "quiet", "overcrowded", "good_vibes"
  final DateTime timestamp;
  final DateTime expiresAt;

  HotZoneVote({
    required this.id,
    required this.sailingId,
    required this.location,
    required this.userId,
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
      userId: map['userId'] as String? ?? '',
      vibe: map['vibe'] as String? ?? 'active',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  /// Convert HotZoneVote to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sailingId': sailingId,
      'location': location,
      'userId': userId,
      'vibe': vibe,
      'timestamp': Timestamp.fromDate(timestamp),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  /// Check if vote has expired (30 minutes old)
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

  @override
  String toString() {
    return 'HotZoneVote(location: $location, vibe: $vibe, time: $timeAgo)';
  }
}
