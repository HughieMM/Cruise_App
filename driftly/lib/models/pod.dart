import 'package:cloud_firestore/cloud_firestore.dart';

/// Pod Model
///
/// Represents a community pod within a sailing
///
/// Firestore path: /sailings/{sailingId}/pods/{podId}
class Pod {
  final String id;
  final String sailingId;
  final String name;
  final String description;
  final String icon; // Icon name for UI
  final String color; // Hex color code
  final int memberCount;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  Pod({
    required this.id,
    required this.sailingId,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    this.memberCount = 0,
    this.lastMessageAt,
    required this.createdAt,
  });

  /// Create Pod from Firestore document
  factory Pod.fromMap(Map<String, dynamic> map, String documentId) {
    return Pod(
      id: documentId,
      sailingId: map['sailingId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? 'groups',
      color: map['color'] as String? ?? '#2196F3',
      memberCount: map['memberCount'] as int? ?? 0,
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Pod to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sailingId': sailingId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'memberCount': memberCount,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Get formatted last message time
  String get lastMessageTimeAgo {
    if (lastMessageAt == null) return 'No messages yet';

    final now = DateTime.now();
    final difference = now.difference(lastMessageAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Create a copy with updated fields
  Pod copyWith({
    String? id,
    String? sailingId,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? memberCount,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) {
    return Pod(
      id: id ?? this.id,
      sailingId: sailingId ?? this.sailingId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      memberCount: memberCount ?? this.memberCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Pod(id: $id, name: $name, memberCount: $memberCount)';
  }
}
