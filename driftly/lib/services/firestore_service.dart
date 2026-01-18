import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// FirestoreService
///
/// Handles all Firestore database operations for users
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Users collection reference
  CollectionReference get usersCollection => _firestore.collection('users');

  /// Create a new user document
  Future<void> createUser(AppUser user) async {
    try {
      await usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get user by ID
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Update user document
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Check if user document exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user existence: $e');
    }
  }

  /// Delete user document
  Future<void> deleteUser(String uid) async {
    try {
      await usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Stream user document
  Stream<AppUser?> streamUser(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Update user's current sailing
  Future<void> updateCurrentSailing(String uid, String sailingId) async {
    try {
      await updateUser(uid, {'currentSailingId': sailingId});
    } catch (e) {
      throw Exception('Failed to update current sailing: $e');
    }
  }

  /// Update selfie verification status
  Future<void> updateSelfieVerification(
    String uid, {
    required bool verified,
    String? photoUrl,
  }) async {
    try {
      await updateUser(uid, {
        'selfieVerified': verified,
        if (photoUrl != null) 'selfieUrl': photoUrl,
      });
    } catch (e) {
      throw Exception('Failed to update selfie verification: $e');
    }
  }
}
