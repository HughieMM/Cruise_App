import 'package:cloud_firestore/cloud_firestore.dart';

/// Sailing Model
///
/// Represents a specific cruise sailing instance
///
/// Firestore path: /sailings/{sailingId}
class Sailing {
  final String id;
  final String shipId;
  final String cruiseLineId;
  final DateTime departureDate;
  final DateTime? returnDate;
  final int memberCount;
  final bool active;
  final DateTime createdAt;

  Sailing({
    required this.id,
    required this.shipId,
    required this.cruiseLineId,
    required this.departureDate,
    this.returnDate,
    this.memberCount = 0,
    this.active = true,
    required this.createdAt,
  });

  /// Create Sailing from Firestore document
  factory Sailing.fromMap(Map<String, dynamic> map, String documentId) {
    return Sailing(
      id: documentId,
      shipId: map['shipId'] as String? ?? '',
      cruiseLineId: map['cruiseLineId'] as String? ?? '',
      departureDate: (map['departureDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      returnDate: (map['returnDate'] as Timestamp?)?.toDate(),
      memberCount: map['memberCount'] as int? ?? 0,
      active: map['active'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Sailing to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shipId': shipId,
      'cruiseLineId': cruiseLineId,
      'departureDate': Timestamp.fromDate(departureDate),
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'memberCount': memberCount,
      'active': active,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Check if sailing is within 30-day access window
  bool get isWithin30DayWindow {
    final now = DateTime.now();
    final daysDifference = departureDate.difference(now).inDays;
    return daysDifference <= 30 && daysDifference >= 0;
  }

  /// Get days until departure
  int get daysUntilDeparture {
    final now = DateTime.now();
    return departureDate.difference(now).inDays;
  }

  /// Check if sailing has departed
  bool get hasDeparted {
    return DateTime.now().isAfter(departureDate);
  }

  /// Check if sailing is complete (after return date)
  bool get isComplete {
    if (returnDate == null) return false;
    return DateTime.now().isAfter(returnDate!);
  }

  /// Get sailing status
  String get status {
    if (isComplete) return 'Completed';
    if (hasDeparted) return 'In Progress';
    if (isWithin30DayWindow) return 'Upcoming (Access Granted)';
    return 'Future (Access Locked)';
  }

  /// Check if it's time for profile completion prompt (Day 30 or less)
  bool get shouldPromptProfileCompletion => daysUntilDeparture <= 30;

  /// Check if tribe matching should happen (Day 25 or less)
  bool get shouldTriggerTribeMatching => daysUntilDeparture <= 25;

  /// Check if we're in the final countdown (Day 7 or less)
  bool get isInFinalCountdown => daysUntilDeparture <= 7;

  /// Get countdown message for UI
  String get countdownMessage {
    final days = daysUntilDeparture;
    if (days <= 0) return 'Departing today!';
    if (days == 1) return '1 day until departure!';
    if (days <= 7) return '$days days until departure!';
    if (days <= 25) return 'Tribes matching in ${days - 25} days';
    if (days <= 30) return '$days days to go - complete your profile!';
    return '$days days until departure';
  }

  /// Create a copy with updated fields
  Sailing copyWith({
    String? id,
    String? shipId,
    String? cruiseLineId,
    DateTime? departureDate,
    DateTime? returnDate,
    int? memberCount,
    bool? active,
    DateTime? createdAt,
  }) {
    return Sailing(
      id: id ?? this.id,
      shipId: shipId ?? this.shipId,
      cruiseLineId: cruiseLineId ?? this.cruiseLineId,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      memberCount: memberCount ?? this.memberCount,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Sailing(id: $id, shipId: $shipId, departureDate: $departureDate, status: $status)';
  }
}
