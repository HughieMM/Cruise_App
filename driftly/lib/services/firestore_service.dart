import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/sailing.dart';
import '../models/pod.dart';
import '../models/pod_member.dart';

/// FirestoreService
///
/// Handles all Firestore database operations for users, sailings, and pods
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Users collection reference
  CollectionReference get usersCollection => _firestore.collection('users');

  /// Sailings collection reference
  CollectionReference get sailingsCollection => _firestore.collection('sailings');

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

  // ==================== Sailing Methods ====================

  /// Find or create a sailing
  /// Returns the sailing ID
  Future<String> findOrCreateSailing({
    required String cruiseLineId,
    required String shipId,
    required DateTime departureDate,
  }) async {
    try {
      // Search for existing sailing with same ship and departure date
      final querySnapshot = await sailingsCollection
          .where('shipId', isEqualTo: shipId)
          .where('departureDate',
              isEqualTo: Timestamp.fromDate(
                  DateTime(departureDate.year, departureDate.month, departureDate.day)))
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Sailing already exists
        return querySnapshot.docs.first.id;
      }

      // Create new sailing
      final sailing = Sailing(
        id: '', // Will be set by Firestore
        cruiseLineId: cruiseLineId,
        shipId: shipId,
        departureDate: DateTime(departureDate.year, departureDate.month, departureDate.day),
        returnDate: DateTime(departureDate.year, departureDate.month, departureDate.day)
            .add(const Duration(days: 7)), // Default 7-day cruise
        memberCount: 0,
        active: true,
        createdAt: DateTime.now(),
      );

      final docRef = await sailingsCollection.add(sailing.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to find or create sailing: $e');
    }
  }

  /// Get sailing by ID
  Future<Sailing?> getSailing(String sailingId) async {
    try {
      final doc = await sailingsCollection.doc(sailingId).get();
      if (!doc.exists) return null;
      return Sailing.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get sailing: $e');
    }
  }

  // ==================== Pod Methods ====================

  /// Get pods collection for a sailing
  CollectionReference podsCollection(String sailingId) {
    return sailingsCollection.doc(sailingId).collection('pods');
  }

  /// Get pod members collection
  CollectionReference podMembersCollection(String sailingId, String podId) {
    return podsCollection(sailingId).doc(podId).collection('members');
  }

  /// Create default pods for a sailing
  Future<void> createDefaultPodsForSailing(String sailingId) async {
    try {
      final defaultPods = [
        {
          'name': 'Gym Crew',
          'description': 'For fitness enthusiasts who want to stay active',
          'icon': 'fitness_center',
          'color': '#FF5722',
        },
        {
          'name': 'Nightlife Crew',
          'description': 'Dance the night away and party till dawn',
          'icon': 'nightlife',
          'color': '#9C27B0',
        },
        {
          'name': 'Chill Drinks',
          'description': 'Casual drinks and relaxed conversations',
          'icon': 'local_bar',
          'color': '#00BCD4',
        },
        {
          'name': 'Excursion Explorers',
          'description': 'Adventure seekers and shore excursion lovers',
          'icon': 'explore',
          'color': '#4CAF50',
        },
        {
          'name': 'Sports & Games',
          'description': 'Competitive fun with sports and activities',
          'icon': 'sports_basketball',
          'color': '#FF9800',
        },
      ];

      final batch = _firestore.batch();

      for (var podData in defaultPods) {
        final pod = Pod(
          id: '', // Will be set by Firestore
          sailingId: sailingId,
          name: podData['name'] as String,
          description: podData['description'] as String,
          icon: podData['icon'] as String,
          color: podData['color'] as String,
          memberCount: 0,
          createdAt: DateTime.now(),
        );

        final docRef = podsCollection(sailingId).doc();
        batch.set(docRef, pod.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create default pods: $e');
    }
  }

  /// Get all pods for a sailing
  Future<List<Pod>> getPodsForSailing(String sailingId) async {
    try {
      final querySnapshot = await podsCollection(sailingId).get();

      if (querySnapshot.docs.isEmpty) {
        // Create default pods if none exist
        await createDefaultPodsForSailing(sailingId);
        // Fetch again
        final newSnapshot = await podsCollection(sailingId).get();
        return newSnapshot.docs
            .map((doc) => Pod.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      }

      return querySnapshot.docs
          .map((doc) => Pod.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pods: $e');
    }
  }

  /// Join a pod
  Future<void> joinPod({
    required String sailingId,
    required String podId,
    required String userId,
    required String userName,
  }) async {
    try {
      final podMember = PodMember(
        userId: userId,
        userName: userName,
        podId: podId,
        joinedAt: DateTime.now(),
        role: 'member',
      );

      // Add member to pod
      await podMembersCollection(sailingId, podId)
          .doc(userId)
          .set(podMember.toMap());

      // Increment pod member count
      await podsCollection(sailingId).doc(podId).update({
        'memberCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to join pod: $e');
    }
  }

  /// Leave a pod
  Future<void> leavePod({
    required String sailingId,
    required String podId,
    required String userId,
  }) async {
    try {
      // Remove member from pod
      await podMembersCollection(sailingId, podId).doc(userId).delete();

      // Decrement pod member count
      await podsCollection(sailingId).doc(podId).update({
        'memberCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to leave pod: $e');
    }
  }

  /// Get user's pods for a sailing
  Future<List<Pod>> getUserPodsForSailing({
    required String sailingId,
    required String userId,
  }) async {
    try {
      // Get all pods for the sailing
      final allPods = await getPodsForSailing(sailingId);
      final userPods = <Pod>[];

      // Check membership for each pod
      for (var pod in allPods) {
        final memberDoc = await podMembersCollection(sailingId, pod.id)
            .doc(userId)
            .get();

        if (memberDoc.exists) {
          userPods.add(pod);
        }
      }

      return userPods;
    } catch (e) {
      throw Exception('Failed to get user pods: $e');
    }
  }

  /// Check if user is member of a pod
  Future<bool> isUserInPod({
    required String sailingId,
    required String podId,
    required String userId,
  }) async {
    try {
      final doc = await podMembersCollection(sailingId, podId).doc(userId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check pod membership: $e');
    }
  }
}
