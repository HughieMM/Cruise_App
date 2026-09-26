import 'package:cloud_firestore/cloud_firestore.dart';

/// ConnectionRequest Model
///
/// A Pod-only "First Mates" connect request between two users, mirroring
/// the shape of [SiblingRequest] (lib/models/tribe.dart) but simpler since
/// the target's UID is already known up front (the requester is connecting
/// to a specific person whose profile is already open, not looking someone
/// up by email).
///
/// Firestore path: /sailings/{sailingId}/connectionRequests/{requestId}
class ConnectionRequest {
  final String id;
  final String sailingId;
  final String requesterId;
  final String requesterName;
  final String targetId;
  final String targetName;
  final String status; // 'pending' | 'accepted' | 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;

  ConnectionRequest({
    required this.id,
    required this.sailingId,
    required this.requesterId,
    required this.requesterName,
    required this.targetId,
    required this.targetName,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory ConnectionRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return ConnectionRequest(
      id: documentId,
      sailingId: map['sailingId'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      requesterName: map['requesterName'] as String? ?? '',
      targetId: map['targetId'] as String? ?? '',
      targetName: map['targetName'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (map['respondedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sailingId': sailingId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'targetId': targetId,
      'targetName': targetName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  /// Given the current viewer's uid, the "other person" in this request.
  String otherUserId(String viewerUid) => requesterId == viewerUid ? targetId : requesterId;
  String otherUserName(String viewerUid) => requesterId == viewerUid ? targetName : requesterName;
}
