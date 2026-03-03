import 'package:cloud_firestore/cloud_firestore.dart';

/// Tribe Model
///
/// Represents a randomly matched group of 3-5 cruisers
/// Similar to university dorm groups - not based on looks
///
/// Tribe sizes: Minimum 3, Maximum 5, Ideal 4-5
/// Example: 22 people in age bracket = 4 tribes of 4, 2 tribes of 3
///
/// Firestore path: /sailings/{sailingId}/tribes/{tribeId}
class Tribe {
  final String id;
  final String sailingId;
  final String name; // Auto-generated fun name like "The Wave Riders"
  final String ageBand; // Primary age band (or 'mixed' for mixed-age tribes)
  final List<String> ageBands; // All age bands represented (for mixed tribes)
  final List<String> memberIds; // User IDs
  final List<String> commonInterests; // Interests shared by all members
  final int maxMembers; // 3-5 members
  final bool isFull;
  final bool isMixedAgeGroup; // True if tribe has multiple age groups (18-39 only)
  final DateTime createdAt;
  final DateTime? lastActivityAt;

  Tribe({
    required this.id,
    required this.sailingId,
    required this.name,
    required this.ageBand,
    this.ageBands = const [],
    required this.memberIds,
    required this.commonInterests,
    this.maxMembers = 5,
    this.isFull = false,
    this.isMixedAgeGroup = false,
    required this.createdAt,
    this.lastActivityAt,
  });

  factory Tribe.fromMap(Map<String, dynamic> map, String documentId) {
    return Tribe(
      id: documentId,
      sailingId: map['sailingId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Tribe',
      ageBand: map['ageBand'] as String? ?? '',
      ageBands: List<String>.from(map['ageBands'] as List? ?? []),
      memberIds: List<String>.from(map['memberIds'] as List? ?? []),
      commonInterests: List<String>.from(map['commonInterests'] as List? ?? []),
      maxMembers: map['maxMembers'] as int? ?? 5,
      isFull: map['isFull'] as bool? ?? false,
      isMixedAgeGroup: map['isMixedAgeGroup'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivityAt: (map['lastActivityAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sailingId': sailingId,
      'name': name,
      'ageBand': ageBand,
      'ageBands': ageBands,
      'memberIds': memberIds,
      'commonInterests': commonInterests,
      'maxMembers': maxMembers,
      'isFull': isFull,
      'isMixedAgeGroup': isMixedAgeGroup,
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
    List<String>? ageBands,
    List<String>? memberIds,
    List<String>? commonInterests,
    int? maxMembers,
    bool? isFull,
    bool? isMixedAgeGroup,
    DateTime? createdAt,
    DateTime? lastActivityAt,
  }) {
    return Tribe(
      id: id ?? this.id,
      sailingId: sailingId ?? this.sailingId,
      name: name ?? this.name,
      ageBand: ageBand ?? this.ageBand,
      ageBands: ageBands ?? this.ageBands,
      memberIds: memberIds ?? this.memberIds,
      commonInterests: commonInterests ?? this.commonInterests,
      maxMembers: maxMembers ?? this.maxMembers,
      isFull: isFull ?? this.isFull,
      isMixedAgeGroup: isMixedAgeGroup ?? this.isMixedAgeGroup,
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

/// Sea Ya - Daily photo feature (like BeReal but cruise-themed)
/// One prompt per day, tribe-only
///
/// Firestore path: /sailings/{sailingId}/seaYaPhotos/{photoId}
class SeaYaPhoto {
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

  SeaYaPhoto({
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

  factory SeaYaPhoto.fromMap(Map<String, dynamic> map, String documentId) {
    return SeaYaPhoto(
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
