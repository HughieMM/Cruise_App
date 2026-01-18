import 'package:cloud_firestore/cloud_firestore.dart';

/// Message Model
///
/// Represents a chat message in a pod
///
/// Firestore path: /sailings/{sailingId}/pods/{podId}/messages/{messageId}
class Message {
  final String id;
  final String podId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String text;
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, List<String>>? reactions; // emoji -> list of userIds

  Message({
    required this.id,
    required this.podId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.text,
    required this.timestamp,
    this.imageUrl,
    this.reactions,
  });

  /// Create Message from Firestore document
  factory Message.fromMap(Map<String, dynamic> map, String documentId) {
    return Message(
      id: documentId,
      podId: map['podId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      text: map['text'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'] as String?,
      reactions: map['reactions'] != null
          ? Map<String, List<String>>.from(
              (map['reactions'] as Map<dynamic, dynamic>).map(
                (key, value) => MapEntry(
                  key.toString(),
                  List<String>.from(value as List),
                ),
              ),
            )
          : null,
    );
  }

  /// Convert Message to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'podId': podId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'imageUrl': imageUrl,
      'reactions': reactions,
    };
  }

  /// Get formatted timestamp
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  /// Check if message was sent by a specific user
  bool isSentBy(String currentUserId) {
    return userId == currentUserId;
  }

  /// Get total reaction count
  int get totalReactions {
    if (reactions == null) return 0;
    return reactions!.values.fold(0, (sum, userIds) => sum + userIds.length);
  }

  @override
  String toString() {
    return 'Message(id: $id, userName: $userName, text: $text, time: $formattedTime)';
  }
}
