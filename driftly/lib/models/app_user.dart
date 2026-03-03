import 'package:cloud_firestore/cloud_firestore.dart';

/// AppUser Model
///
/// Represents a Driftly user with profile information
///
/// Firestore path: /users/{userId}
class AppUser {
  final String uid;
  final String email;
  final String name;
  final String ageBand; // "16-17", "18-20", "21-30", "31-40", "40+"
  final String gender; // "male", "female", "other"
  final List<String> interests;
  final bool selfieVerified;
  final String? selfieUrl;
  final String? facePhotoUrl;      // Required: Main profile photo (face)
  final String? funPhotoUrl;       // Required: Fun/personality photo
  final String? wildcardPhotoUrl;  // Required: Any photo they want
  final String? verificationPhotoUrl; // Liveness check selfie
  final String? currentSailingId;
  final String? currentTribeId;    // Tribe they're assigned to
  final String? siblingRequestId;  // If they requested to join with a sibling
  final bool profileComplete;      // True after Day 30 profile completion
  final bool allowAgeMixing;       // Opt-in to mix with other age groups (18-39 only)
  final Map<String, String> socialLinks; // Social media handles
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.ageBand,
    this.gender = 'other',
    required this.interests,
    this.selfieVerified = false,
    this.selfieUrl,
    this.facePhotoUrl,
    this.funPhotoUrl,
    this.wildcardPhotoUrl,
    this.verificationPhotoUrl,
    this.currentSailingId,
    this.currentTribeId,
    this.siblingRequestId,
    this.profileComplete = false,
    this.allowAgeMixing = false,
    this.socialLinks = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user is underage (16-17) for content restrictions
  bool get isUnderage => ageBand == '16-17';

  /// Check if user is in a protected age group that cannot mix (16-17 or 39+)
  bool get isProtectedAgeGroup => ageBand == '16-17' || ageBand == '39+';

  /// Check if user can mix with other age groups (18-39 and opted in)
  bool get canMixAgeGroups => !isProtectedAgeGroup && allowAgeMixing;

  /// Create AppUser from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      ageBand: map['ageBand'] as String? ?? '21-30',
      gender: map['gender'] as String? ?? 'other',
      interests: List<String>.from(map['interests'] as List? ?? []),
      selfieVerified: map['selfieVerified'] as bool? ?? false,
      selfieUrl: map['selfieUrl'] as String?,
      facePhotoUrl: map['facePhotoUrl'] as String?,
      funPhotoUrl: map['funPhotoUrl'] as String?,
      wildcardPhotoUrl: map['wildcardPhotoUrl'] as String?,
      verificationPhotoUrl: map['verificationPhotoUrl'] as String?,
      currentSailingId: map['currentSailingId'] as String?,
      currentTribeId: map['currentTribeId'] as String?,
      siblingRequestId: map['siblingRequestId'] as String?,
      profileComplete: map['profileComplete'] as bool? ?? false,
      allowAgeMixing: map['allowAgeMixing'] as bool? ?? false,
      socialLinks: Map<String, String>.from(map['socialLinks'] as Map? ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert AppUser to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'ageBand': ageBand,
      'gender': gender,
      'interests': interests,
      'selfieVerified': selfieVerified,
      'selfieUrl': selfieUrl,
      'facePhotoUrl': facePhotoUrl,
      'funPhotoUrl': funPhotoUrl,
      'wildcardPhotoUrl': wildcardPhotoUrl,
      'verificationPhotoUrl': verificationPhotoUrl,
      'currentSailingId': currentSailingId,
      'currentTribeId': currentTribeId,
      'siblingRequestId': siblingRequestId,
      'profileComplete': profileComplete,
      'allowAgeMixing': allowAgeMixing,
      'socialLinks': socialLinks,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? ageBand,
    String? gender,
    List<String>? interests,
    bool? selfieVerified,
    String? selfieUrl,
    String? facePhotoUrl,
    String? funPhotoUrl,
    String? wildcardPhotoUrl,
    String? verificationPhotoUrl,
    String? currentSailingId,
    String? currentTribeId,
    String? siblingRequestId,
    bool? profileComplete,
    bool? allowAgeMixing,
    Map<String, String>? socialLinks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      ageBand: ageBand ?? this.ageBand,
      gender: gender ?? this.gender,
      interests: interests ?? this.interests,
      selfieVerified: selfieVerified ?? this.selfieVerified,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      facePhotoUrl: facePhotoUrl ?? this.facePhotoUrl,
      funPhotoUrl: funPhotoUrl ?? this.funPhotoUrl,
      wildcardPhotoUrl: wildcardPhotoUrl ?? this.wildcardPhotoUrl,
      verificationPhotoUrl: verificationPhotoUrl ?? this.verificationPhotoUrl,
      currentSailingId: currentSailingId ?? this.currentSailingId,
      currentTribeId: currentTribeId ?? this.currentTribeId,
      siblingRequestId: siblingRequestId ?? this.siblingRequestId,
      profileComplete: profileComplete ?? this.profileComplete,
      allowAgeMixing: allowAgeMixing ?? this.allowAgeMixing,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is on a sailing
  bool get hasCurrentSailing => currentSailingId != null;

  /// Check if user is in a tribe
  bool get hasCurrentTribe => currentTribeId != null;

  /// Check if all required photos are uploaded
  bool get hasAllPhotos =>
      facePhotoUrl != null &&
      funPhotoUrl != null &&
      wildcardPhotoUrl != null;

  /// Check if face is verified
  bool get isFaceVerified => selfieVerified && verificationPhotoUrl != null;

  /// Check if profile is complete (for tribe matching)
  bool get isProfileComplete {
    return name.isNotEmpty &&
        ageBand.isNotEmpty &&
        gender != 'other' &&
        interests.isNotEmpty &&
        hasAllPhotos &&
        currentSailingId != null;
  }

  /// Check if user is ready for tribe matching
  bool get isReadyForTribeMatching =>
      isProfileComplete && !hasCurrentTribe;

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, email: $email, ageBand: $ageBand, gender: $gender)';
  }
}
