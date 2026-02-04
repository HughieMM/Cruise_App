import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/tribe.dart';

/// TribeService
///
/// Handles tribe creation, matching algorithm, and sibling requests.
/// Tribes are randomly matched groups of 4-6 cruisers with:
/// - Same age band
/// - 1-2 shared interests
/// - Equal gender ratio (2 boys + 2 girls for 4-person tribe)
/// - Sibling/friend requests honored
class TribeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Tribes collection for a sailing
  CollectionReference tribesCollection(String sailingId) {
    return _firestore
        .collection('sailings')
        .doc(sailingId)
        .collection('tribes');
  }

  /// Sibling requests collection for a sailing
  CollectionReference siblingRequestsCollection(String sailingId) {
    return _firestore
        .collection('sailings')
        .doc(sailingId)
        .collection('siblingRequests');
  }

  /// Tribe members subcollection
  CollectionReference tribeMembersCollection(String sailingId, String tribeId) {
    return tribesCollection(sailingId).doc(tribeId).collection('members');
  }

  /// Daily photos collection for a sailing
  CollectionReference dailyPhotosCollection(String sailingId) {
    return _firestore
        .collection('sailings')
        .doc(sailingId)
        .collection('dailyPhotos');
  }

  /// Fun tribe names for random assignment
  static const List<String> _tribeNames = [
    'The Wave Riders',
    'Sunset Chasers',
    'Deck Explorers',
    'Ocean Nomads',
    'Sea Wanderers',
    'Tide Turners',
    'Horizon Hunters',
    'Coral Crew',
    'Starboard Squad',
    'Anchor Allies',
    'Nautical Nomads',
    'Voyage Vibes',
    'Salty Sailors',
    'Maritime Mates',
    'Current Cruisers',
    'Bay Breakers',
    'Lagoon Legends',
    'Reef Rangers',
    'Coastal Crew',
    'Portside Posse',
  ];

  /// Get a random tribe name
  String _getRandomTribeName() {
    final random = Random();
    return _tribeNames[random.nextInt(_tribeNames.length)];
  }

  // ==================== Tribe Methods ====================

  /// Create a new tribe
  Future<String> createTribe({
    required String sailingId,
    required String ageBand,
    required List<String> commonInterests,
    int maxMembers = 4,
  }) async {
    try {
      final tribe = Tribe(
        id: '',
        sailingId: sailingId,
        name: _getRandomTribeName(),
        ageBand: ageBand,
        memberIds: [],
        commonInterests: commonInterests,
        maxMembers: maxMembers,
        isFull: false,
        createdAt: DateTime.now(),
      );

      final docRef = await tribesCollection(sailingId).add(tribe.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create tribe: $e');
    }
  }

  /// Get tribe by ID
  Future<Tribe?> getTribe(String sailingId, String tribeId) async {
    try {
      final doc = await tribesCollection(sailingId).doc(tribeId).get();
      if (!doc.exists) return null;
      return Tribe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get tribe: $e');
    }
  }

  /// Stream user's tribe
  Stream<Tribe?> streamUserTribe(String sailingId, String tribeId) {
    return tribesCollection(sailingId).doc(tribeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Tribe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Get all tribes for a sailing
  Future<List<Tribe>> getTribesForSailing(String sailingId) async {
    try {
      final querySnapshot = await tribesCollection(sailingId).get();
      return querySnapshot.docs
          .map((doc) => Tribe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tribes: $e');
    }
  }

  /// Add member to tribe
  Future<void> addMemberToTribe({
    required String sailingId,
    required String tribeId,
    required AppUser user,
    bool isLeader = false,
  }) async {
    try {
      final tribeMember = TribeMember(
        userId: user.uid,
        userName: user.name,
        ageBand: user.ageBand,
        gender: user.gender,
        interests: user.interests,
        photoUrl: user.facePhotoUrl,
        joinedAt: DateTime.now(),
        isLeader: isLeader,
      );

      // Add to tribe members subcollection
      await tribeMembersCollection(sailingId, tribeId)
          .doc(user.uid)
          .set(tribeMember.toMap());

      // Update tribe document
      final tribe = await getTribe(sailingId, tribeId);
      if (tribe != null) {
        final newMemberIds = [...tribe.memberIds, user.uid];
        await tribesCollection(sailingId).doc(tribeId).update({
          'memberIds': newMemberIds,
          'isFull': newMemberIds.length >= tribe.maxMembers,
          'lastActivityAt': FieldValue.serverTimestamp(),
        });
      }

      // Update user's currentTribeId
      await _firestore.collection('users').doc(user.uid).update({
        'currentTribeId': tribeId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add member to tribe: $e');
    }
  }

  /// Get tribe members
  Future<List<TribeMember>> getTribeMembers(
    String sailingId,
    String tribeId,
  ) async {
    try {
      final querySnapshot =
          await tribeMembersCollection(sailingId, tribeId).get();
      return querySnapshot.docs
          .map((doc) => TribeMember.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tribe members: $e');
    }
  }

  /// Stream tribe members
  Stream<List<TribeMember>> streamTribeMembers(
    String sailingId,
    String tribeId,
  ) {
    return tribeMembersCollection(sailingId, tribeId)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TribeMember.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // ==================== Sibling Request Methods ====================

  /// Create a sibling/friend request
  Future<String> createSiblingRequest({
    required String sailingId,
    required String requesterId,
    required String requesterName,
    required String targetEmail,
  }) async {
    try {
      // Check if request already exists
      final existing = await siblingRequestsCollection(sailingId)
          .where('requesterId', isEqualTo: requesterId)
          .where('targetEmail', isEqualTo: targetEmail.toLowerCase())
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('You already have a pending request to this person');
      }

      final request = SiblingRequest(
        id: '',
        sailingId: sailingId,
        requesterId: requesterId,
        requesterName: requesterName,
        targetEmail: targetEmail.toLowerCase(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final docRef =
          await siblingRequestsCollection(sailingId).add(request.toMap());

      // Update requester's siblingRequestId
      await _firestore.collection('users').doc(requesterId).update({
        'siblingRequestId': docRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create sibling request: $e');
    }
  }

  /// Get pending sibling requests for a user (by email)
  Future<List<SiblingRequest>> getPendingRequestsForEmail(
    String sailingId,
    String email,
  ) async {
    try {
      final querySnapshot = await siblingRequestsCollection(sailingId)
          .where('targetEmail', isEqualTo: email.toLowerCase())
          .where('status', isEqualTo: 'pending')
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SiblingRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending requests: $e');
    }
  }

  /// Accept a sibling request
  Future<void> acceptSiblingRequest({
    required String sailingId,
    required String requestId,
    required String targetId,
    required String targetName,
  }) async {
    try {
      await siblingRequestsCollection(sailingId).doc(requestId).update({
        'targetId': targetId,
        'targetName': targetName,
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Update target's siblingRequestId
      await _firestore.collection('users').doc(targetId).update({
        'siblingRequestId': requestId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to accept sibling request: $e');
    }
  }

  /// Decline a sibling request
  Future<void> declineSiblingRequest(
    String sailingId,
    String requestId,
  ) async {
    try {
      await siblingRequestsCollection(sailingId).doc(requestId).update({
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to decline sibling request: $e');
    }
  }

  /// Get sibling request by ID
  Future<SiblingRequest?> getSiblingRequest(
    String sailingId,
    String requestId,
  ) async {
    try {
      final doc =
          await siblingRequestsCollection(sailingId).doc(requestId).get();
      if (!doc.exists) return null;
      return SiblingRequest.fromMap(
          doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get sibling request: $e');
    }
  }

  // ==================== Tribe Matching Algorithm ====================

  /// Match users into tribes for a sailing
  /// This is the main matching algorithm that runs on Day 25
  ///
  /// Algorithm:
  /// 1. Get all unmatched users for the sailing
  /// 2. Group by age band
  /// 3. Within each age band, find users with shared interests
  /// 4. Balance by gender (2 male + 2 female for 4-person tribes)
  /// 5. Honor sibling requests (place siblings in same tribe)
  /// 6. Create tribes and assign members
  Future<int> runTribeMatching(String sailingId) async {
    try {
      // Get all users on this sailing who don't have a tribe
      final usersSnapshot = await _firestore
          .collection('users')
          .where('currentSailingId', isEqualTo: sailingId)
          .where('currentTribeId', isNull: true)
          .get();

      final users = usersSnapshot.docs
          .map((doc) => AppUser.fromMap(doc.data(), doc.id))
          .where((u) => u.isProfileComplete)
          .toList();

      if (users.isEmpty) return 0;

      // Get accepted sibling requests
      final siblingSnapshot = await siblingRequestsCollection(sailingId)
          .where('status', isEqualTo: 'accepted')
          .get();

      final siblingPairs = <Set<String>>[];
      for (var doc in siblingSnapshot.docs) {
        final request =
            SiblingRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (request.targetId != null) {
          siblingPairs.add({request.requesterId, request.targetId!});
        }
      }

      // Group users by age band
      final usersByAgeBand = <String, List<AppUser>>{};
      for (var user in users) {
        usersByAgeBand.putIfAbsent(user.ageBand, () => []).add(user);
      }

      int tribesCreated = 0;

      // Process each age band
      for (var entry in usersByAgeBand.entries) {
        final ageBand = entry.key;
        final ageBandUsers = List<AppUser>.from(entry.value);

        // Shuffle for randomness
        ageBandUsers.shuffle();

        // Separate by gender
        final males =
            ageBandUsers.where((u) => u.gender == 'male').toList();
        final females =
            ageBandUsers.where((u) => u.gender == 'female').toList();
        final others =
            ageBandUsers.where((u) => u.gender == 'other').toList();

        // Process sibling pairs first
        final processedUserIds = <String>{};

        for (var pair in siblingPairs) {
          // Find the two users in this age band
          final user1 = ageBandUsers
              .where((u) => pair.contains(u.uid))
              .toList();

          if (user1.length == 2 &&
              !processedUserIds.contains(user1[0].uid) &&
              !processedUserIds.contains(user1[1].uid)) {
            // Both siblings are in this age band and unmatched
            // Find 2 more users to complete the tribe
            final commonInterests = _findCommonInterests(
              user1[0].interests,
              user1[1].interests,
            );

            // Find complementary users with shared interests
            final candidates = ageBandUsers
                .where((u) =>
                    !pair.contains(u.uid) &&
                    !processedUserIds.contains(u.uid) &&
                    _hasSharedInterest(u.interests, commonInterests))
                .toList();

            if (candidates.length >= 2) {
              // Try to balance genders
              final neededGenders = _getNeededGenders(user1);
              final selectedCandidates =
                  _selectByGender(candidates, neededGenders, 2);

              if (selectedCandidates.length >= 2) {
                // Create tribe with siblings + 2 others
                final tribeMembers = [...user1, ...selectedCandidates.take(2)];
                final allInterests =
                    tribeMembers.expand((u) => u.interests).toList();
                final sharedInterests = _findAllSharedInterests(allInterests);

                final tribeId = await createTribe(
                  sailingId: sailingId,
                  ageBand: ageBand,
                  commonInterests: sharedInterests.take(2).toList(),
                );

                // Add members
                bool isFirst = true;
                for (var member in tribeMembers) {
                  await addMemberToTribe(
                    sailingId: sailingId,
                    tribeId: tribeId,
                    user: member,
                    isLeader: isFirst,
                  );
                  processedUserIds.add(member.uid);
                  isFirst = false;
                }

                // Mark sibling request as matched
                final requestDoc = siblingSnapshot.docs.firstWhere(
                  (doc) {
                    final r = SiblingRequest.fromMap(
                        doc.data() as Map<String, dynamic>, doc.id);
                    return pair.contains(r.requesterId) &&
                        pair.contains(r.targetId);
                  },
                  orElse: () => throw Exception('Sibling request not found'),
                );
                await siblingRequestsCollection(sailingId)
                    .doc(requestDoc.id)
                    .update({'status': 'matched'});

                tribesCreated++;
              }
            }
          }
        }

        // Remove processed users from gender lists
        males.removeWhere((u) => processedUserIds.contains(u.uid));
        females.removeWhere((u) => processedUserIds.contains(u.uid));
        others.removeWhere((u) => processedUserIds.contains(u.uid));

        // Now match remaining users into tribes of 4
        // Try to make balanced tribes (2 male + 2 female)
        while (males.length >= 2 && females.length >= 2) {
          final selectedMales = males.take(2).toList();
          final selectedFemales = females.take(2).toList();

          final tribeMembers = [...selectedMales, ...selectedFemales];
          final allInterests =
              tribeMembers.expand((u) => u.interests).toList();
          final sharedInterests = _findAllSharedInterests(allInterests);

          final tribeId = await createTribe(
            sailingId: sailingId,
            ageBand: ageBand,
            commonInterests: sharedInterests.take(2).toList(),
          );

          bool isFirst = true;
          for (var member in tribeMembers) {
            await addMemberToTribe(
              sailingId: sailingId,
              tribeId: tribeId,
              user: member,
              isLeader: isFirst,
            );
            isFirst = false;
          }

          males.removeRange(0, 2);
          females.removeRange(0, 2);
          tribesCreated++;
        }

        // Handle remaining users (less balanced tribes)
        final remaining = [...males, ...females, ...others];
        while (remaining.length >= 4) {
          final tribeMembers = remaining.take(4).toList();
          final allInterests =
              tribeMembers.expand((u) => u.interests).toList();
          final sharedInterests = _findAllSharedInterests(allInterests);

          final tribeId = await createTribe(
            sailingId: sailingId,
            ageBand: ageBand,
            commonInterests: sharedInterests.take(2).toList(),
          );

          bool isFirst = true;
          for (var member in tribeMembers) {
            await addMemberToTribe(
              sailingId: sailingId,
              tribeId: tribeId,
              user: member,
              isLeader: isFirst,
            );
            isFirst = false;
          }

          remaining.removeRange(0, 4);
          tribesCreated++;
        }

        // If 2-3 users remain, add them to an existing non-full tribe
        // or create a smaller tribe
        if (remaining.isNotEmpty) {
          // Find non-full tribe with same age band
          final existingTribes = await tribesCollection(sailingId)
              .where('ageBand', isEqualTo: ageBand)
              .where('isFull', isEqualTo: false)
              .limit(1)
              .get();

          if (existingTribes.docs.isNotEmpty) {
            final tribe = Tribe.fromMap(
              existingTribes.docs.first.data() as Map<String, dynamic>,
              existingTribes.docs.first.id,
            );

            // Add remaining users to this tribe (up to max)
            for (var user in remaining) {
              if (tribe.memberIds.length < tribe.maxMembers) {
                await addMemberToTribe(
                  sailingId: sailingId,
                  tribeId: tribe.id,
                  user: user,
                );
              }
            }
          } else if (remaining.length >= 2) {
            // Create a smaller tribe if at least 2 users
            final tribeMembers = remaining;
            final allInterests =
                tribeMembers.expand((u) => u.interests).toList();
            final sharedInterests = _findAllSharedInterests(allInterests);

            final tribeId = await createTribe(
              sailingId: sailingId,
              ageBand: ageBand,
              commonInterests: sharedInterests.take(2).toList(),
              maxMembers: 6, // Allow more to join later
            );

            bool isFirst = true;
            for (var member in tribeMembers) {
              await addMemberToTribe(
                sailingId: sailingId,
                tribeId: tribeId,
                user: member,
                isLeader: isFirst,
              );
              isFirst = false;
            }
            tribesCreated++;
          }
        }
      }

      return tribesCreated;
    } catch (e) {
      throw Exception('Failed to run tribe matching: $e');
    }
  }

  /// Find common interests between two lists
  List<String> _findCommonInterests(
    List<String> interests1,
    List<String> interests2,
  ) {
    return interests1.where((i) => interests2.contains(i)).toList();
  }

  /// Check if user has at least one shared interest
  bool _hasSharedInterest(
    List<String> userInterests,
    List<String> targetInterests,
  ) {
    return userInterests.any((i) => targetInterests.contains(i));
  }

  /// Find interests that appear more than once in the combined list
  List<String> _findAllSharedInterests(List<String> allInterests) {
    final counts = <String, int>{};
    for (var interest in allInterests) {
      counts[interest] = (counts[interest] ?? 0) + 1;
    }
    // Return interests shared by at least 2 members
    return counts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList()
      ..sort((a, b) =>
          (counts[b] ?? 0).compareTo(counts[a] ?? 0)); // Most common first
  }

  /// Get needed genders to balance a tribe
  Map<String, int> _getNeededGenders(List<AppUser> currentMembers) {
    final maleCount =
        currentMembers.where((u) => u.gender == 'male').length;
    final femaleCount =
        currentMembers.where((u) => u.gender == 'female').length;

    // For a balanced tribe of 4: 2 male + 2 female
    return {
      'male': (2 - maleCount).clamp(0, 2),
      'female': (2 - femaleCount).clamp(0, 2),
    };
  }

  /// Select users by gender preference
  List<AppUser> _selectByGender(
    List<AppUser> candidates,
    Map<String, int> neededGenders,
    int total,
  ) {
    final selected = <AppUser>[];

    // First, try to fulfill gender needs
    for (var gender in neededGenders.keys) {
      final needed = neededGenders[gender] ?? 0;
      final available =
          candidates.where((u) => u.gender == gender).take(needed).toList();
      selected.addAll(available);
    }

    // If we still need more, add any remaining
    if (selected.length < total) {
      final remaining = candidates
          .where((u) => !selected.contains(u))
          .take(total - selected.length);
      selected.addAll(remaining);
    }

    return selected;
  }

  // ==================== Daily Photo Methods ====================

  /// Submit a daily photo
  Future<String> submitDailyPhoto({
    required String sailingId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    String? tribeId,
    required String photoUrl,
    String? caption,
    required DateTime promptedAt,
  }) async {
    try {
      final now = DateTime.now();
      final responseTime = now.difference(promptedAt).inSeconds;

      final photo = DailyPhoto(
        id: '',
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        sailingId: sailingId,
        tribeId: tribeId,
        photoUrl: photoUrl,
        caption: caption,
        promptedAt: promptedAt,
        takenAt: now,
        responseTimeSeconds: responseTime,
        createdAt: now,
      );

      final docRef = await dailyPhotosCollection(sailingId).add(photo.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit daily photo: $e');
    }
  }

  /// Get today's daily photos for a tribe
  Future<List<DailyPhoto>> getTribeDailyPhotos({
    required String sailingId,
    required String tribeId,
  }) async {
    try {
      final todayStart = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );

      final querySnapshot = await dailyPhotosCollection(sailingId)
          .where('tribeId', isEqualTo: tribeId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              DailyPhoto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tribe daily photos: $e');
    }
  }

  /// Stream daily photos for a tribe
  Stream<List<DailyPhoto>> streamTribeDailyPhotos({
    required String sailingId,
    required String tribeId,
  }) {
    final todayStart = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );

    return dailyPhotosCollection(sailingId)
        .where('tribeId', isEqualTo: tribeId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                DailyPhoto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Check if user has submitted daily photo today
  Future<bool> hasSubmittedDailyPhoto({
    required String sailingId,
    required String userId,
  }) async {
    try {
      final todayStart = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
      );

      final querySnapshot = await dailyPhotosCollection(sailingId)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check daily photo: $e');
    }
  }
}
