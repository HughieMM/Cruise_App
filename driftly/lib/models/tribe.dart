import 'package:cloud_firestore/cloud_firestore.dart';

/// Tribe Model
///
/// Represents a randomly matched group of 4-6 cruisers
/// Similar to university dorm groups - not based on looks
///
/// Firestore path: /sailings/{sailingId}/tribes/{tribeId}
class Tribe {
  final String id;
  final String sailingId;
  final String name; // Auto-generated fun name like "The Wave Riders"
  final String ageBand; // All members must be same age band
  final List<String> memberIds; // User IDs
  final List<String> commonInterests; // Interests shared by all members
  final int maxMembers; // 4 or 6
  final bool isFull;
  final DateTime createdAt;
  final DateTime? lastActivityAt;

  Tribe({
    required this.id,
    required this.sailingId,
    required this.name,
    required this.ageBand,
    required this.memberIds,
    required this.commonInterests,
    this.maxMembers = 4,
    this.isFull = false,
    required this.createdAt,
    this.lastActivityAt,
  });

  factory Tribe.fromMap(Map<String, dynamic> map, String documentId) {
    return Tribe(
      id: documentId,
      sailingId: map['sailingId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Tribe',
      ageBand: map['ageBand'] as String? ?? '',
      memberIds: List<String>.from(map['memberIds'] as List? ?? []),
      commonInterests: List<String>.from(map['commonInterests'] as List? ?? []),
      maxMembers: map['maxMembers'] as int? ?? 4,
      isFull: map['isFull'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivityAt: (map['lastActivityAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sailingId': sailingId,
      'name': name,
      'ageBand': ageBand,
      'memberIds': memberIds,
      'commonInterests': commonInterests,
      'maxMembers': maxMembers,
      'isFull': isFull,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActivityAt': lastActivityAt != null
          ? Timestamp.fromDate(lastActivityAt!)
          : null,
    };
  }

  Tribe copyWith({
    String? id,
    String? sailingId,
    String? name,
    String? ageBand,
    List<String>? memberIds,
    List<String>? commonInterests,
    int? maxMembers,
    bool? isFull,
    DateTime? createdAt,
    DateTime? lastActivityAt,
  }) {
    return Tribe(
      id: id ?? this.id,
      sailingId: sailingId ?? this.sailingId,
      name: name ?? this.name,
      ageBand: ageBand ?? this.ageBand,
      memberIds: memberIds ?? this.memberIds,
      commonInterests: commonInterests ?? this.commonInterests,
      maxMembers: maxMembers ?? this.maxMembers,
      isFull: isFull ?? this.isFull,
      createdAt: createdAt ?? this.createdAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  int get memberCount => memberIds.length;
  int get spotsRemaining => maxMembers - memberCount;
  bool get hasSpace => memberCount < maxMembers;

  /// Check if a user is a member of this tribe
  bool hasMember(String userId) => memberIds.contains(userId);

  @override
  String toString() {
    return 'Tribe(id: $id, name: $name, members: $memberCount/$maxMembers)';
  }
}

/// TribeMember - detailed info about a tribe member
class TribeMember {
  final String userId;
  final String userName;
  final String ageBand;
  final String gender; // 'male', 'female', 'other'
  final List<String> interests;
  final String? photoUrl;
  final DateTime joinedAt;
  final bool isLeader; // First member or designated leader

  TribeMember({
    required this.userId,
    required this.userName,
    required this.ageBand,
    required this.gender,
    required this.interests,
    this.photoUrl,
    required this.joinedAt,
    this.isLeader = false,
  });

  factory TribeMember.fromMap(Map<String, dynamic> map) {
    return TribeMember(
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      ageBand: map['ageBand'] as String? ?? '',
      gender: map['gender'] as String? ?? 'other',
      interests: List<String>.from(map['interests'] as List? ?? []),
      photoUrl: map['photoUrl'] as String?,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isLeader: map['isLeader'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'ageBand': ageBand,
      'gender': gender,
      'interests': interests,
      'photoUrl': photoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isLeader': isLeader,
    };
  }
}

/// SiblingRequest - request to be matched with a friend/sibling
///
/// Firestore path: /sailings/{sailingId}/siblingRequests/{requestId}
class SiblingRequest {
  final String id;
  final String sailingId;
  final String requesterId; // User who sent the request
  final String requesterName;
  final String targetEmail; // Email of sibling/friend to match with
  final String? targetId; // Filled when target joins the sailing
  final String? targetName;
  final String status; // 'pending', 'accepted', 'declined', 'matched'
  final DateTime createdAt;
  final DateTime? respondedAt;

  SiblingRequest({
    required this.id,
    required this.sailingId,
    required this.requesterId,
    required this.requesterName,
    required this.targetEmail,
    this.targetId,
    this.targetName,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  factory SiblingRequest.fromMap(Map<String, dynamic> map, String documentId) {
    return SiblingRequest(
      id: documentId,
      sailingId: map['sailingId'] as String? ?? '',
      requesterId: map['requesterId'] as String? ?? '',
      requesterName: map['requesterName'] as String? ?? '',
      targetEmail: map['targetEmail'] as String? ?? '',
      targetId: map['targetId'] as String?,
      targetName: map['targetName'] as String?,
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
      'targetEmail': targetEmail,
      'targetId': targetId,
      'targetName': targetName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isMatched => status == 'matched';
}

/// BeReal-style daily photo
///
/// Firestore path: /sailings/{sailingId}/dailyPhotos/{photoId}
class DailyPhoto {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String sailingId;
  final String? tribeId;
  final String photoUrl;
  final String? caption;
  final DateTime promptedAt; // When the notification was sent
  final DateTime takenAt; // When they took the photo
  final int responseTimeSeconds; // How fast they responded
  final DateTime createdAt;

  DailyPhoto({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.sailingId,
    this.tribeId,
    required this.photoUrl,
    this.caption,
    required this.promptedAt,
    required this.takenAt,
    required this.responseTimeSeconds,
    required this.createdAt,
  });

  factory DailyPhoto.fromMap(Map<String, dynamic> map, String documentId) {
    return DailyPhoto(
      id: documentId,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      sailingId: map['sailingId'] as String? ?? '',
      tribeId: map['tribeId'] as String?,
      photoUrl: map['photoUrl'] as String? ?? '',
      caption: map['caption'] as String?,
      promptedAt: (map['promptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      takenAt: (map['takenAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responseTimeSeconds: map['responseTimeSeconds'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'sailingId': sailingId,
      'tribeId': tribeId,
      'photoUrl': photoUrl,
      'caption': caption,
      'promptedAt': Timestamp.fromDate(promptedAt),
      'takenAt': Timestamp.fromDate(takenAt),
      'responseTimeSeconds': responseTimeSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Format response time nicely
  String get responseTimeFormatted {
    if (responseTimeSeconds < 60) {
      return '${responseTimeSeconds}s';
    } else if (responseTimeSeconds < 3600) {
      return '${(responseTimeSeconds / 60).floor()}m';
    } else {
      return '${(responseTimeSeconds / 3600).floor()}h';
    }
  }
}
