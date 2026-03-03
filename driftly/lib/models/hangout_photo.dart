import 'package:cloud_firestore/cloud_firestore.dart';

/// HangoutPhoto Model
///
/// Represents a photo taken during a hangout
/// Only allows camera photos (no camera roll uploads) for authenticity
///
/// Firestore path: /sailings/{sailingId}/hangouts/{hangoutId}/photos/{photoId}
class HangoutPhoto {
  final String id;
  final String hangoutId;
  final String userId;
  final String userName;
  final String photoUrl;
  final DateTime takenAt;

  HangoutPhoto({
    required this.id,
    required this.hangoutId,
    required this.userId,
    required this.userName,
    required this.photoUrl,
    required this.takenAt,
  });

  /// Create HangoutPhoto from Firestore document
  factory HangoutPhoto.fromMap(Map<String, dynamic> map, String documentId) {
    return HangoutPhoto(
      id: documentId,
      hangoutId: map['hangoutId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      takenAt: (map['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert HangoutPhoto to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'hangoutId': hangoutId,
      'userId': userId,
      'userName': userName,
      'photoUrl': photoUrl,
      'takenAt': Timestamp.fromDate(takenAt),
    };
  }

  /// Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(takenAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  HangoutPhoto copyWith({
    String? id,
    String? hangoutId,
    String? userId,
    String? userName,
    String? photoUrl,
    DateTime? takenAt,
  }) {
    return HangoutPhoto(
      id: id ?? this.id,
      hangoutId: hangoutId ?? this.hangoutId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      photoUrl: photoUrl ?? this.photoUrl,
      takenAt: takenAt ?? this.takenAt,
    );
  }

  @override
  String toString() {
    return 'HangoutPhoto(id: $id, hangoutId: $hangoutId, userName: $userName)';
  }
}
