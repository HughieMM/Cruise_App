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
  final String ageBand; // "21-25" or "26-30"
  final List<String> interests;
  final bool selfieVerified;
  final String? selfieUrl;
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
      ageBand: map['ageBand'] as String? ?? '21-25',
      interests: List<String>.from(map['interests'] as List? ?? []),
      selfieVerified: map['selfieVerified'] as bool? ?? false,
      selfieUrl: map['selfieUrl'] as String?,
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
      currentSailingId: currentSailingId ?? this.currentSailingId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if user is on a sailing
  bool get hasCurrentSailing => currentSailingId != null;

  /// Check if profile is complete
  bool get isProfileComplete {
    return name.isNotEmpty &&
        ageBand.isNotEmpty &&
        interests.isNotEmpty &&
        currentSailingId != null;
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, name: $name, email: $email, ageBand: $ageBand)';
  }
}
