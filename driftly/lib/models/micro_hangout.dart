import 'package:cloud_firestore/cloud_firestore.dart';

/// MicroHangout Model
///
/// Represents a 45-minute temporary location check-in
///
/// Firestore path: /sailings/{sailingId}/hangouts/{hangoutId}
class MicroHangout {
  final String id;
  final String sailingId;
  final String location;
  final String? deck;
  final String createdBy;
  final String createdByName;
  final String createdByAgeBand; // Age band of creator for filtering
  final List<String> attendeeIds;
  final int attendeeCount;
  final String vibe; // "chill", "lively", "party"
  final DateTime startTime;
  final DateTime expiresAt;
  final bool active;

  MicroHangout({
    required this.id,
    required this.sailingId,
    required this.location,
    this.deck,
    required this.createdBy,
    required this.createdByName,
    required this.createdByAgeBand,
    required this.attendeeIds,
    required this.attendeeCount,
    required this.vibe,
    required this.startTime,
    required this.expiresAt,
    required this.active,
  });

  /// Create MicroHangout from Firestore document
  factory MicroHangout.fromMap(Map<String, dynamic> map, String documentId) {
    return MicroHangout(
      id: documentId,
      sailingId: map['sailingId'] as String? ?? '',
      location: map['location'] as String? ?? '',
      deck: map['deck'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      createdByAgeBand: map['createdByAgeBand'] as String? ?? '',
      attendeeIds: List<String>.from(map['attendeeIds'] as List? ?? []),
      attendeeCount: map['attendeeCount'] as int? ?? 0,
      vibe: map['vibe'] as String? ?? 'chill',
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(minutes: 45)),
      active: map['active'] as bool? ?? true,
    );
  }

  /// Convert MicroHangout to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sailingId': sailingId,
      'location': location,
      'deck': deck,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdByAgeBand': createdByAgeBand,
      'attendeeIds': attendeeIds,
      'attendeeCount': attendeeCount,
      'vibe': vibe,
      'startTime': Timestamp.fromDate(startTime),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'active': active,
    };
  }

  /// Check if hangout has expired
  bool get hasExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Get remaining time in minutes
  int get minutesRemaining {
    if (hasExpired) return 0;
    return expiresAt.difference(DateTime.now()).inMinutes;
  }

  /// Get formatted time remaining
  String get timeRemaining {
    final minutes = minutesRemaining;
    if (minutes <= 0) return 'Expired';
    return '$minutes min';
  }

  /// Check if user has joined
  bool hasUserJoined(String userId) {
    return attendeeIds.contains(userId);
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

  /// Create a copy with updated fields
  MicroHangout copyWith({
    String? id,
    String? sailingId,
    String? location,
    String? deck,
    String? createdBy,
    String? createdByName,
    String? createdByAgeBand,
    List<String>? attendeeIds,
    int? attendeeCount,
    String? vibe,
    DateTime? startTime,
    DateTime? expiresAt,
    bool? active,
  }) {
    return MicroHangout(
      id: id ?? this.id,
      sailingId: sailingId ?? this.sailingId,
      location: location ?? this.location,
      deck: deck ?? this.deck,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdByAgeBand: createdByAgeBand ?? this.createdByAgeBand,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      vibe: vibe ?? this.vibe,
      startTime: startTime ?? this.startTime,
      expiresAt: expiresAt ?? this.expiresAt,
      active: active ?? this.active,
    );
  }

  @override
  String toString() {
    return 'MicroHangout(id: $id, location: $location, attendees: $attendeeCount, time: $timeRemaining)';
  }
}
