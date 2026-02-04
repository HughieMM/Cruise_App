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
  final String ageBand; // "14-17", "18-20", "21-30", "31-40", "40+"
  final List<String> interests;
  final bool selfieVerified;
  final String? selfieUrl;
  final String? facePhotoUrl;      // Required: Main profile photo (face)
  final String? funPhotoUrl;       // Required: Fun/personality photo
  final String? wildcardPhotoUrl;  // Required: Any photo they want
  final String? verificationPhotoUrl; // Liveness check selfie
  final String? currentSailingId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.ageBand,
    required this.interests,
    this.selfieVerified = false,
    this.selfieUrl,
    this.facePhotoUrl,
    this.funPhotoUrl,
    this.wildcardPhotoUrl,
    this.verificationPhotoUrl,
    this.currentSailingId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create AppUser from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      ageBand: map['ageBand'] as String? ?? '21-30',
      interests: List<String>.from(map['interests'] as List? ?? []),
      selfieVerified: map['selfieVerified'] as bool? ?? false,
      selfieUrl: map['selfieUrl'] as String?,
      facePhotoUrl: map['facePhotoUrl'] as String?,
      funPhotoUrl: map['funPhotoUrl'] as String?,
      wildcardPhotoUrl: map['wildcardPhotoUrl'] as String?,
      verificationPhotoUrl: map['verificationPhotoUrl'] as String?,
      currentSailingId: map['currentSailingId'] as String?,
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
      'interests': interests,
      'selfieVerified': selfieVerified,
      'selfieUrl': selfieUrl,
      'facePhotoUrl': facePhotoUrl,
      'funPhotoUrl': funPhotoUrl,
      'wildcardPhotoUrl': wildcardPhotoUrl,
      'verificationPhotoUrl': verificationPhotoUrl,
      'currentSailingId': currentSailingId,
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
    List<String>? interests,
    bool? selfieVerified,
    String? selfieUrl,
    String? facePhotoUrl,
    String? funPhotoUrl,
    String? wildcardPhotoUrl,
    String? verificationPhotoUrl,
    String? currentSailingId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      ageBand: ageBand ?? this.ageBand,
      interests: interests ?? this.interests,
      selfieVerified: selfieVerified ?? this.selfieVerified,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      facePhotoUrl: facePhotoUrl ?? this.facePhotoUrl,
      funPhotoUrl: funPhotoUrl ?? this.funPhotoUrl,
      wildcardPhotoUrl: wildcardPhotoUrl ?? this.wildcardPhotoUrl,
      verificationPhotoUrl: verificationPhotoUrl ?? this.verificationPhotoUrl,
      currentSailingId: currentSailingId ?? this.currentSailingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is on a sailing
  bool get hasCurrentSailing => currentSailingId != null;

  /// Check if all required photos are uploaded
  bool get hasAllPhotos =>
      facePhotoUrl != null &&
      funPhotoUrl != null &&
      wildcardPhotoUrl != null;

  /// Check if face is verified
  bool get isFaceVerified => selfieVerified && verificationPhotoUrl != null;

  /// Check if profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        ageBand.isNotEmpty &&
        interests.isNotEmpty &&
        hasAllPhotos &&
        currentSailingId != null;
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, email: $email, ageBand: $ageBand)';
  }
}
