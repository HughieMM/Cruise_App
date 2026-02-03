import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show Color;

/// HotZoneVote Model
///
/// Represents a user's vote on location vibe
/// Users can vote once per location per hour
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
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 1)),
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

  /// Get vibe emoji
  String get vibeEmoji {
    switch (vibe) {
      case 'active':
        return '⚡';
      case 'quiet':
        return '🤫';
      case 'overcrowded':
        return '😰';
      case 'good_vibes':
        return '✨';
      default:
        return '📍';
    }
  }

  /// Get vibe display name
  String get vibeDisplay {
    switch (vibe) {
      case 'active':
        return 'Active';
      case 'quiet':
        return 'Quiet';
      case 'overcrowded':
        return 'Overcrowded';
      case 'good_vibes':
        return 'Good Vibes';
      default:
        return 'Unknown';
    }
  }

  /// Get vibe color
  Color get vibeColor {
    switch (vibe) {
      case 'active':
        return const Color(0xFFFF9800); // Orange
      case 'quiet':
        return const Color(0xFF2196F3); // Blue
      case 'overcrowded':
        return const Color(0xFFF44336); // Red
      case 'good_vibes':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  @override
  String toString() {
    return 'HotZoneVote(location: $location, vibe: $vibe, time: $timeAgo)';
  }
}
