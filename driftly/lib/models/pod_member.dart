import 'package:cloud_firestore/cloud_firestore.dart';

/// PodMember Model
///
/// Represents a user's membership in a pod
///
/// Firestore path: /sailings/{sailingId}/pods/{podId}/members/{userId}
class PodMember {
  final String userId;
  final String userName;
  final String podId;
  final DateTime joinedAt;
  final String role; // "member" or "admin"

  PodMember({
    required this.userId,
    required this.userName,
    required this.podId,
    required this.joinedAt,
    this.role = 'member',
  });

  /// Create PodMember from Firestore document
  factory PodMember.fromMap(Map<String, dynamic> map, String documentId) {
    return PodMember(
      userId: documentId,
      userName: map['userName'] as String? ?? '',
      podId: map['podId'] as String? ?? '',
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: map['role'] as String? ?? 'member',
    );
  }

  /// Convert PodMember to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'podId': podId,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'role': role,
    };
  }

  /// Check if user is pod admin
  bool get isAdmin => role == 'admin';

  @override
  String toString() {
    return 'PodMember(userId: $userId, userName: $userName, role: $role)';
  }
}
