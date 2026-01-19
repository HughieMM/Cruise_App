import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/sailing.dart';
import '../models/pod.dart';
import '../models/pod_member.dart';
import '../models/message.dart';
import '../models/micro_hangout.dart';
import '../models/hot_zone_vote.dart';
import '../utils/input_validator.dart';
import '../utils/constants.dart';

/// FirestoreService
///
/// Handles all Firestore database operations for users, sailings, pods, messages, and hangouts
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

  // ==================== Message Methods ====================

  /// Get messages collection for a pod
  CollectionReference messagesCollection(String sailingId, String podId) {
    return podsCollection(sailingId).doc(podId).collection('messages');
  }

  /// Send a message to a pod
  Future<void> sendMessage({
    required String sailingId,
    required String podId,
    required String userId,
    required String userName,
    required String text,
    String? userPhotoUrl,
  }) async {
    try {
      // Validate and sanitize input
      final validationError = InputValidator.validateMessage(text);
      if (validationError != null) {
        throw Exception(validationError);
      }

      final sanitizedText = InputValidator.sanitizeAndTruncate(
        text,
        AppConstants.maxMessageLength,
      );

      final message = Message(
        id: '', // Will be set by Firestore
        podId: podId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        text: sanitizedText,
        timestamp: DateTime.now(),
      );

      // Add message to collection
      await messagesCollection(sailingId, podId).add(message.toMap());

      // Update pod's lastMessageAt timestamp
      await podsCollection(sailingId).doc(podId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Stream messages for a pod in real-time
  /// Returns messages ordered by timestamp (newest first for pagination, but display oldest first)
  Stream<List<Message>> streamMessages({
    required String sailingId,
    required String podId,
    int limit = 50,
  }) {
    return messagesCollection(sailingId, podId)
        .orderBy('timestamp', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Get messages for a pod (one-time fetch)
  Future<List<Message>> getMessages({
    required String sailingId,
    required String podId,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await messagesCollection(sailingId, podId)
          .orderBy('timestamp', descending: false)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage({
    required String sailingId,
    required String podId,
    required String messageId,
  }) async {
    try {
      await messagesCollection(sailingId, podId).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // ==================== Hangout Methods ====================

  /// Get hangouts collection for a sailing
  CollectionReference hangoutsCollection(String sailingId) {
    return sailingsCollection.doc(sailingId).collection('hangouts');
  }

  /// Create a new micro hangout
  Future<String> createMicroHangout({
    required String sailingId,
    required String location,
    String? deck,
    required String createdBy,
    required String createdByName,
    required String createdByAgeBand,
    required String vibe,
  }) async {
    try {
      // Validate inputs
      final locationError = InputValidator.validateLocation(location);
      if (locationError != null) {
        throw Exception(locationError);
      }

      if (!InputValidator.isValidHangoutVibe(vibe)) {
        throw Exception('Invalid vibe option');
      }

      if (!InputValidator.isValidAgeBand(createdByAgeBand)) {
        throw Exception('Invalid age band');
      }

      // Sanitize location
      final sanitizedLocation = InputValidator.sanitizeAndTruncate(
        location,
        AppConstants.maxLocationLength,
      );

      final now = DateTime.now();
      final expiresAt = now.add(AppConstants.hangoutDuration);

      final hangout = MicroHangout(
        id: '', // Will be set by Firestore
        sailingId: sailingId,
        location: sanitizedLocation,
        deck: deck,
        createdBy: createdBy,
        createdByName: createdByName,
        createdByAgeBand: createdByAgeBand,
        attendeeIds: [createdBy], // Creator automatically joins
        attendeeCount: 1,
        vibe: vibe,
        startTime: now,
        expiresAt: expiresAt,
        active: true,
      );

      final docRef = await hangoutsCollection(sailingId).add(hangout.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create hangout: $e');
    }
  }

  /// Get active hangouts for a sailing filtered by age band
  /// Returns only non-expired hangouts
  Future<List<MicroHangout>> getActiveHangouts({
    required String sailingId,
    String? ageBand,
  }) async {
    try {
      Query query = hangoutsCollection(sailingId)
          .where('active', isEqualTo: true)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt', descending: false);

      // Filter by age band if provided
      if (ageBand != null && ageBand.isNotEmpty) {
        query = query.where('createdByAgeBand', isEqualTo: ageBand);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
              MicroHangout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active hangouts: $e');
    }
  }

  /// Stream active hangouts for real-time updates
  Stream<List<MicroHangout>> streamActiveHangouts({
    required String sailingId,
    String? ageBand,
  }) {
    Query query = hangoutsCollection(sailingId)
        .where('active', isEqualTo: true)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt', descending: false);

    // Filter by age band if provided
    if (ageBand != null && ageBand.isNotEmpty) {
      query = query.where('createdByAgeBand', isEqualTo: ageBand);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              MicroHangout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((hangout) => !hangout.hasExpired) // Additional client-side filter
          .toList();
    });
  }

  /// Join a hangout
  Future<void> joinHangout({
    required String sailingId,
    required String hangoutId,
    required String userId,
  }) async {
    try {
      await hangoutsCollection(sailingId).doc(hangoutId).update({
        'attendeeIds': FieldValue.arrayUnion([userId]),
        'attendeeCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to join hangout: $e');
    }
  }

  /// Leave a hangout
  Future<void> leaveHangout({
    required String sailingId,
    required String hangoutId,
    required String userId,
  }) async {
    try {
      await hangoutsCollection(sailingId).doc(hangoutId).update({
        'attendeeIds': FieldValue.arrayRemove([userId]),
        'attendeeCount': FieldValue.increment(-1),
      });
    } catch (e) {
      throw Exception('Failed to leave hangout: $e');
    }
  }

  /// Get a specific hangout
  Future<MicroHangout?> getHangout({
    required String sailingId,
    required String hangoutId,
  }) async {
    try {
      final doc = await hangoutsCollection(sailingId).doc(hangoutId).get();
      if (!doc.exists) return null;
      return MicroHangout.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get hangout: $e');
    }
  }

  /// Deactivate an expired hangout
  Future<void> deactivateHangout({
    required String sailingId,
    required String hangoutId,
  }) async {
    try {
      await hangoutsCollection(sailingId).doc(hangoutId).update({
        'active': false,
      });
    } catch (e) {
      throw Exception('Failed to deactivate hangout: $e');
    }
  }

  // ==================== Hot Zones (Vibe Voting) Methods ====================

  /// Get hot zone votes collection for a sailing
  CollectionReference hotZoneVotesCollection(String sailingId) {
    return sailingsCollection.doc(sailingId).collection('hotZoneVotes');
  }

  /// Check if user has voted for a location in the last hour
  /// Returns the existing vote if found, null otherwise
  Future<HotZoneVote?> checkUserRecentVote({
    required String sailingId,
    required String userId,
    required String location,
  }) async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final querySnapshot = await hotZoneVotesCollection(sailingId)
          .where('userId', isEqualTo: userId)
          .where('location', isEqualTo: location)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return HotZoneVote.fromMap(
        querySnapshot.docs.first.data() as Map<String, dynamic>,
        querySnapshot.docs.first.id,
      );
    } catch (e) {
      throw Exception('Failed to check recent vote: $e');
    }
  }

  /// Submit a hot zone vibe vote
  /// Returns the vote ID on success
  /// Throws exception if user has already voted for this location in the last hour
  Future<String> submitHotZoneVote({
    required String sailingId,
    required String userId,
    required String location,
    required String vibe,
  }) async {
    try {
      // Validate inputs
      if (!InputValidator.isValidHotZoneLocation(location)) {
        throw Exception('Invalid location. Must be one of: ${AppConstants.hotZoneLocations.join(", ")}');
      }

      if (!InputValidator.isValidVibe(vibe)) {
        throw Exception('Invalid vibe option');
      }

      // Check for duplicate vote
      final existingVote = await checkUserRecentVote(
        sailingId: sailingId,
        userId: userId,
        location: location,
      );

      if (existingVote != null) {
        final minutesRemaining = existingVote.expiresAt.difference(DateTime.now()).inMinutes;
        throw Exception(
          'You already voted for this location. Try again in $minutesRemaining minutes.',
        );
      }

      // Create new vote
      final now = DateTime.now();
      final expiresAt = now.add(AppConstants.voteValidityDuration);

      final vote = HotZoneVote(
        id: '', // Will be set by Firestore
        sailingId: sailingId,
        location: location,
        userId: userId,
        vibe: vibe,
        timestamp: now,
        expiresAt: expiresAt,
      );

      final docRef = await hotZoneVotesCollection(sailingId).add(vote.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit vote: $e');
    }
  }

  /// Get recent votes for a specific location (last 60 minutes)
  Future<List<HotZoneVote>> getRecentVotesForLocation({
    required String sailingId,
    required String location,
  }) async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final querySnapshot = await hotZoneVotesCollection(sailingId)
          .where('location', isEqualTo: location)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              HotZoneVote.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((vote) => !vote.hasExpired) // Additional client-side filter
          .toList();
    } catch (e) {
      throw Exception('Failed to get recent votes: $e');
    }
  }

  /// Stream all recent votes for a sailing (last 60 minutes)
  /// Used to display real-time vibe updates across all locations
  Stream<List<HotZoneVote>> streamRecentVotesForSailing({
    required String sailingId,
  }) {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

    return hotZoneVotesCollection(sailingId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(oneHourAgo))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              HotZoneVote.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((vote) => !vote.hasExpired) // Additional client-side filter
          .toList();
    });
  }

  /// Get vote summary for all locations
  /// Returns a map of location -> {vibe, count}
  Future<Map<String, Map<String, dynamic>>> getVoteSummaryForSailing({
    required String sailingId,
  }) async {
    try {
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));

      final querySnapshot = await hotZoneVotesCollection(sailingId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneHourAgo))
          .get();

      final votes = querySnapshot.docs
          .map((doc) =>
              HotZoneVote.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((vote) => !vote.hasExpired)
          .toList();

      // Group votes by location
      final locationSummaries = <String, Map<String, dynamic>>{};

      for (var vote in votes) {
        if (!locationSummaries.containsKey(vote.location)) {
          locationSummaries[vote.location] = {
            'vibes': <String, int>{},
            'totalVotes': 0,
          };
        }

        final summary = locationSummaries[vote.location]!;
        summary['totalVotes'] = (summary['totalVotes'] as int) + 1;

        final vibes = summary['vibes'] as Map<String, int>;
        vibes[vote.vibe] = (vibes[vote.vibe] ?? 0) + 1;
      }

      // Determine most common vibe for each location
      for (var entry in locationSummaries.entries) {
        final vibes = entry.value['vibes'] as Map<String, int>;
        if (vibes.isNotEmpty) {
          final mostCommonVibe = vibes.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          entry.value['dominantVibe'] = mostCommonVibe;
        } else {
          entry.value['dominantVibe'] = null;
        }
      }

      return locationSummaries;
    } catch (e) {
      throw Exception('Failed to get vote summary: $e');
    }
  }
}
