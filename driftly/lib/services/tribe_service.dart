import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/tribe.dart';
import '../models/message.dart';
import '../utils/constants.dart';
import '../utils/input_validator.dart';
import 'content_moderation_service.dart';

/// TribeService
///
/// Handles tribe creation, matching algorithm, and sibling requests.
/// Tribes are randomly matched groups of 3-5 cruisers with:
/// - Same age band (or mixed 18-39 if opted in and numbers are low)
/// - 1-2 shared interests
/// - Gender balance attempted where possible
/// - Sibling/friend requests honored
///
/// Safety Rules:
/// - 16-17: ONLY with other 16-17, NEVER with other ages (minor protection)
/// - 39+: ONLY with other 39+, NEVER with other ages (community preference)
/// - 18-39: CAN mix across these brackets if user opts in and numbers are low
class TribeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContentModerationService _moderationService = ContentModerationService();

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

  /// Messages collection for a tribe
  CollectionReference tribeMessagesCollection(String sailingId, String tribeId) {
    return tribesCollection(sailingId).doc(tribeId).collection('messages');
  }

  /// Send a message in a tribe chat. Reuses the same Message model as Pod
  /// chat — its `podId` field holds the tribeId here.
  Future<void> sendTribeMessage({
    required String sailingId,
    required String tribeId,
    required String userId,
    required String userName,
    required String text,
    String? userPhotoUrl,
  }) async {
    try {
      final validationError = InputValidator.validateMessage(text);
      if (validationError != null) {
        throw Exception(validationError);
      }

      final moderationResult = await _moderationService.checkAndRecordViolation(
        userId: userId,
        text: text,
      );
      if (moderationResult.blocked) {
        throw ContentModerationException(moderationResult);
      }

      final sanitizedText = InputValidator.sanitizeAndTruncate(
        text,
        AppConstants.maxMessageLength,
      );

      final message = Message(
        id: '',
        podId: tribeId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
        text: sanitizedText,
        timestamp: DateTime.now(),
      );

      await tribeMessagesCollection(sailingId, tribeId).add(message.toMap());
    } on ContentModerationException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Stream tribe chat messages, most recent first
  Stream<List<Message>> streamTribeMessages({
    required String sailingId,
    required String tribeId,
    int limit = 100,
  }) {
    return tribeMessagesCollection(sailingId, tribeId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Sea Ya photos collection for a sailing
  CollectionReference seaYaPhotosCollection(String sailingId) {
    return _firestore
        .collection('sailings')
        .doc(sailingId)
        .collection('seaYaPhotos');
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
    int maxMembers = 5,
    bool isMixedAgeGroup = false,
    List<String> ageBands = const [],
    bool isLateJoinerTribe = false,
  }) async {
    try {
      final tribe = Tribe(
        id: '',
        sailingId: sailingId,
        name: _getRandomTribeName(),
        ageBand: isMixedAgeGroup ? 'mixed' : ageBand,
        ageBands: ageBands.isNotEmpty ? ageBands : [ageBand],
        memberIds: [],
        commonInterests: commonInterests,
        maxMembers: maxMembers.clamp(
          AppConstants.minTribeSize,
          AppConstants.maxTribeSize,
        ),
        isFull: false,
        isMixedAgeGroup: isMixedAgeGroup,
        isLateJoinerTribe: isLateJoinerTribe,
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

  /// Whether two age bands are allowed to be matched into the same tribe
  /// via a sibling/friend request. Mirrors the age-mixing rule used
  /// everywhere else in the app: 16-17 and 39+ are "protected" bands that
  /// never mix with a different band, but adult bands in between (18-20,
  /// 21-30, 31-39) can freely request each other — that's the point of
  /// this feature, letting known siblings/friends across those adult
  /// bands stay together despite normally landing in different buckets.
  bool _ageBandsCompatibleForSibling(String bandA, String bandB) {
    if (bandA == bandB) return true;
    return !AppConstants.isProtectedAgeBand(bandA) &&
        !AppConstants.isProtectedAgeBand(bandB);
  }

  /// Create a sibling/friend request
  Future<String> createSiblingRequest({
    required String sailingId,
    required String requesterId,
    required String requesterName,
    required String requesterAgeBand,
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

      // If the target already has an account on this sailing, check age
      // compatibility right away instead of waiting until they try to
      // accept — much clearer feedback for the sender.
      final targetUserQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: targetEmail.toLowerCase())
          .limit(1)
          .get();
      if (targetUserQuery.docs.isNotEmpty) {
        final targetAgeBand = targetUserQuery.docs.first.data()['ageBand'] as String?;
        if (targetAgeBand != null &&
            !_ageBandsCompatibleForSibling(requesterAgeBand, targetAgeBand)) {
          throw Exception(
              'Sibling requests aren\'t allowed across this age gap for safety reasons');
        }
      }

      final request = SiblingRequest(
        id: '',
        sailingId: sailingId,
        requesterId: requesterId,
        requesterName: requesterName,
        requesterAgeBand: requesterAgeBand,
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
    required String targetAgeBand,
  }) async {
    try {
      // Backstop age check — the create-time check only catches this if
      // the target already had an account with that email at request
      // time; re-checking here covers a target who signed up afterward.
      final requestDoc =
          await siblingRequestsCollection(sailingId).doc(requestId).get();
      final requesterAgeBand =
          (requestDoc.data() as Map<String, dynamic>?)?['requesterAgeBand'] as String?;
      if (requesterAgeBand != null &&
          !_ageBandsCompatibleForSibling(requesterAgeBand, targetAgeBand)) {
        throw Exception(
            'Sibling requests aren\'t allowed across this age gap for safety reasons');
      }

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

  // ==================== Tribe Size Calculation ====================

  /// Calculate optimal tribe sizes for a given number of users
  /// Example: 22 users → [4, 4, 4, 4, 3, 3] (4 tribes of 4, 2 tribes of 3)
  ///
  /// Rules:
  /// - Minimum tribe size: 3
  /// - Maximum tribe size: 5
  /// - Prefer sizes of 4-5 over 3
  List<int> calculateOptimalTribeSizes(int userCount) {
    if (userCount < AppConstants.minTribeSize) {
      return []; // Not enough users for a tribe
    }

    final sizes = <int>[];
    int remaining = userCount;

    // First, try to make tribes of 5
    while (remaining >= 5 && remaining != 6 && remaining != 7) {
      sizes.add(5);
      remaining -= 5;
    }

    // Then, make tribes of 4
    while (remaining >= 4 && remaining != 6) {
      sizes.add(4);
      remaining -= 4;
    }

    // Handle edge cases
    if (remaining == 6) {
      // 6 = 3 + 3 is better than leaving 2 out
      sizes.add(3);
      sizes.add(3);
      remaining = 0;
    } else if (remaining == 7) {
      // 7 = 4 + 3
      sizes.add(4);
      sizes.add(3);
      remaining = 0;
    } else if (remaining >= 3) {
      sizes.add(remaining);
      remaining = 0;
    }
    // If 1-2 remaining, they'll be added to existing tribes later

    return sizes;
  }

  /// Check if age mixing is needed for a sailing
  /// Returns true if any mixable age band has fewer than minTribeSize users
  bool needsAgeMixing(Map<String, List<AppUser>> usersByAgeBand) {
    for (var ageBand in AppConstants.mixableAgeBands) {
      final users = usersByAgeBand[ageBand] ?? [];
      if (users.isNotEmpty && users.length < AppConstants.minTribeSize) {
        return true;
      }
    }
    return false;
  }

  // ==================== Tribe Matching Algorithm ====================

  /// Match users into tribes for a sailing
  /// This is the main matching algorithm that runs on Day 25
  ///
  /// Algorithm:
  /// 1. Get all unmatched users for the sailing
  /// 2. Group by age band
  /// 3. Check if age mixing is needed (small numbers)
  /// 4. Within each age band (or mixed pool), find users with shared interests
  /// 5. Attempt gender balance where possible
  /// 6. Honor sibling requests (place siblings in same tribe)
  /// Attempts to trigger tribe matching for a sailing. Nothing in the app
  /// runs [runTribeMatching] automatically, so this is called from the
  /// client the first time a user without a tribe opens the Tribe tab
  /// past the matching day. Uses a Firestore transaction as a lock (via
  /// the sailing doc's `tribeMatchingStatus` field) so only one caller's
  /// attempt actually runs the algorithm, even if several users' clients
  /// try around the same time. Returns true if THIS call ran matching.
  Future<bool> tryTriggerTribeMatching(String sailingId) async {
    final sailingRef = _firestore.collection('sailings').doc(sailingId);

    final wonLock = await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(sailingRef);
      final data = snapshot.data() as Map<String, dynamic>?;
      final status = data?['tribeMatchingStatus'] as String?;

      if (status == 'in_progress' || status == 'completed') {
        return false;
      }

      transaction.update(sailingRef, {'tribeMatchingStatus': 'in_progress'});
      return true;
    });

    if (!wonLock) return false;

    try {
      await runTribeMatching(sailingId);
      await sailingRef.update({'tribeMatchingStatus': 'completed'});
      return true;
    } catch (e) {
      // Allow a retry later if something went wrong mid-run.
      await sailingRef.update({'tribeMatchingStatus': 'not_started'});
      rethrow;
    }
  }

  /// 7. Create tribes with optimal sizes (3-5 members)
  ///
  /// Safety Rules:
  /// - 16-17 and 39+ NEVER mix with other age groups
  /// - 18-39 can mix only if opted in
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
      final processedUserIds = <String>{};

      // ========== PHASE 1: Process protected age bands (16-17 and 39+) ==========
      // These NEVER mix with other age groups
      for (var protectedBand in AppConstants.noMixingAgeBands) {
        final bandUsers = usersByAgeBand[protectedBand] ?? [];
        if (bandUsers.isEmpty) continue;

        tribesCreated += await _processAgeBandUsers(
          sailingId: sailingId,
          ageBand: protectedBand,
          users: List.from(bandUsers),
          siblingPairs: siblingPairs,
          siblingSnapshot: siblingSnapshot,
          processedUserIds: processedUserIds,
          isMixedAgeGroup: false,
        );
      }

      // ========== PHASE 2: Check if mixable bands need mixing (18-39) ==========
      final mixableUsers = <AppUser>[];
      final mixableBandCounts = <String, int>{};

      for (var band in AppConstants.mixableAgeBands) {
        final bandUsers = (usersByAgeBand[band] ?? [])
            .where((u) => !processedUserIds.contains(u.uid))
            .toList();
        mixableBandCounts[band] = bandUsers.length;
      }

      // Check if any mixable band has insufficient users
      final needsMixing = mixableBandCounts.values
          .any((count) => count > 0 && count < AppConstants.minTribeSize);

      if (needsMixing) {
        // Collect users who opted in to age mixing
        for (var band in AppConstants.mixableAgeBands) {
          final bandUsers = (usersByAgeBand[band] ?? [])
              .where((u) => !processedUserIds.contains(u.uid) && u.canMixAgeGroups)
              .toList();
          mixableUsers.addAll(bandUsers);
        }

        // Process mixed group if we have enough opt-in users
        if (mixableUsers.length >= AppConstants.minTribeSize) {
          tribesCreated += await _processMixedAgeUsers(
            sailingId: sailingId,
            users: mixableUsers,
            siblingPairs: siblingPairs,
            siblingSnapshot: siblingSnapshot,
            processedUserIds: processedUserIds,
          );
        }
      }

      // ========== PHASE 3: Process remaining mixable bands normally ==========
      for (var band in AppConstants.mixableAgeBands) {
        final bandUsers = (usersByAgeBand[band] ?? [])
            .where((u) => !processedUserIds.contains(u.uid))
            .toList();
        if (bandUsers.isEmpty) continue;

        tribesCreated += await _processAgeBandUsers(
          sailingId: sailingId,
          ageBand: band,
          users: bandUsers,
          siblingPairs: siblingPairs,
          siblingSnapshot: siblingSnapshot,
          processedUserIds: processedUserIds,
          isMixedAgeGroup: false,
        );
      }

      return tribesCreated;
    } catch (e) {
      throw Exception('Failed to run tribe matching: $e');
    }
  }

  // ==================== Late Joiner Matching ====================
  //
  // For someone who joins after their sailing's main matching pass has
  // already completed (e.g. they create their account partway through a
  // cruise that already departed) — runTribeMatching above is a one-shot
  // lock and will never fire again for that sailing, so without this,
  // such a user would never get a tribe at all. Deliberately simpler than
  // the main algorithm: pools are expected to be tiny (people trickling
  // in one at a time), so there's no gender-balancing or sibling-pair
  // special-casing here, and the minimum group size is 2 (vs. the normal
  // 3) so nobody waits the rest of a short cruise for a 3rd match that
  // may never come. Never inserts a late joiner into an existing on-time
  // tribe — only into another late-joiner tribe (isLateJoinerTribe: true),
  // which it will keep growing (up to the normal 5-member cap) as more
  // late joiners show up, rather than fragmenting into many separate
  // 2-person tribes.

  /// Attempt a late-joiner matching pass, guarded by a resettable lock
  /// (unlike tribeMatchingStatus, this can run again every time a new
  /// late joiner appears — it's not one-shot).
  Future<bool> tryTriggerLateJoinerMatching(String sailingId) async {
    final sailingRef = _firestore.collection('sailings').doc(sailingId);

    final wonLock = await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(sailingRef);
      final data = snapshot.data() as Map<String, dynamic>?;
      final status = data?['tribeMatchingStatus'] as String?;
      final lateLock = data?['lateJoinerMatchingLock'] as bool? ?? false;

      // Only meaningful once the main pass has already run — before
      // that, an unmatched user is just waiting their normal turn.
      if (status != 'completed' || lateLock) return false;

      transaction.update(sailingRef, {'lateJoinerMatchingLock': true});
      return true;
    });

    if (!wonLock) return false;

    try {
      await _runLateJoinerMatching(sailingId);
      return true;
    } finally {
      await sailingRef.update({'lateJoinerMatchingLock': false});
    }
  }

  Future<void> _runLateJoinerMatching(String sailingId) async {
    final usersSnapshot = await _firestore
        .collection('users')
        .where('currentSailingId', isEqualTo: sailingId)
        .where('currentTribeId', isNull: true)
        .get();

    final users = usersSnapshot.docs
        .map((doc) => AppUser.fromMap(doc.data(), doc.id))
        .where((u) => u.isProfileComplete)
        .toList();

    if (users.isEmpty) return;

    final existingTribes = await getTribesForSailing(sailingId);

    final usersByAgeBand = <String, List<AppUser>>{};
    for (var user in users) {
      usersByAgeBand.putIfAbsent(user.ageBand, () => []).add(user);
    }

    // Pass 1: exact-band groups. Protected bands (16-17, 39+) only ever
    // match this way — same safety rule as the main algorithm. Runs even
    // for a single leftover user, since _groupLateJoiners still checks
    // for room in an already-open late-joiner tribe before deciding
    // whether to wait.
    final groupedUserIds = <String>{};
    for (var band in [...AppConstants.noMixingAgeBands, ...AppConstants.mixableAgeBands]) {
      final bandUsers = usersByAgeBand[band] ?? [];
      if (bandUsers.isEmpty) continue;
      final matched = await _groupLateJoiners(
        sailingId: sailingId,
        tribeAgeBandLabel: band,
        poolUsers: bandUsers,
        existingTribes: existingTribes,
        isMixedAgeGroup: false,
        ageBands: [band],
      );
      groupedUserIds.addAll(matched);
    }

    // Pass 2: leftover mixable-band users who've opted in to age mixing
    // (canMixAgeGroups) get pooled together, same opt-in gate the main
    // algorithm respects — a late joiner who never opted in shouldn't be
    // auto-mixed just because they're impatient to be matched.
    final mixedLeftovers = <AppUser>[];
    for (var band in AppConstants.mixableAgeBands) {
      final leftovers = (usersByAgeBand[band] ?? [])
          .where((u) => !groupedUserIds.contains(u.uid) && u.canMixAgeGroups)
          .toList();
      mixedLeftovers.addAll(leftovers);
    }
    if (mixedLeftovers.length >= 2) {
      await _groupLateJoiners(
        sailingId: sailingId,
        tribeAgeBandLabel: 'mixed',
        poolUsers: mixedLeftovers,
        existingTribes: existingTribes,
        isMixedAgeGroup: true,
        ageBands: AppConstants.mixableAgeBands,
      );
    }
  }

  /// Slots a pool of late joiners into an existing open late-joiner tribe
  /// for this exact band/label if one exists (so late arrivals accumulate
  /// into one shared group over time), otherwise creates a brand new one
  /// — but only if at least 2 people remain to form it. A lone leftover
  /// (0 or 1 person) is left unmatched and retried on the next trigger.
  /// Returns the uids that were actually placed into a tribe, so callers
  /// know which users are still free to be considered elsewhere (e.g. in
  /// the mixed-age pass) rather than assuming the whole pool was handled.
  Future<List<String>> _groupLateJoiners({
    required String sailingId,
    required String tribeAgeBandLabel,
    required List<AppUser> poolUsers,
    required List<Tribe> existingTribes,
    required bool isMixedAgeGroup,
    required List<String> ageBands,
  }) async {
    final remaining = List<AppUser>.from(poolUsers);
    if (remaining.isEmpty) return [];

    final matchedUserIds = <String>[];

    Tribe? openTribe;
    for (final t in existingTribes) {
      if (t.isLateJoinerTribe && !t.isFull && t.ageBand == tribeAgeBandLabel) {
        openTribe = t;
        break;
      }
    }

    if (openTribe != null) {
      final toAdd = remaining.take(openTribe.spotsRemaining).toList();
      for (final user in toAdd) {
        await addMemberToTribe(
          sailingId: sailingId,
          tribeId: openTribe.id,
          user: user,
        );
        matchedUserIds.add(user.uid);
      }
      remaining.removeRange(0, toAdd.length);
    }

    if (remaining.length >= 2) {
      final sharedInterests = _findAllSharedInterests(
        remaining.expand((u) => u.interests).toList(),
      );

      final tribeId = await createTribe(
        sailingId: sailingId,
        ageBand: tribeAgeBandLabel,
        commonInterests: sharedInterests.take(2).toList(),
        maxMembers: AppConstants.maxTribeSize,
        isMixedAgeGroup: isMixedAgeGroup,
        ageBands: ageBands,
        isLateJoinerTribe: true,
      );

      for (var i = 0; i < remaining.length; i++) {
        await addMemberToTribe(
          sailingId: sailingId,
          tribeId: tribeId,
          user: remaining[i],
          isLeader: i == 0,
        );
        matchedUserIds.add(remaining[i].uid);
      }
    }

    return matchedUserIds;
  }

  /// Process users from a single age band into tribes
  Future<int> _processAgeBandUsers({
    required String sailingId,
    required String ageBand,
    required List<AppUser> users,
    required List<Set<String>> siblingPairs,
    required QuerySnapshot siblingSnapshot,
    required Set<String> processedUserIds,
    required bool isMixedAgeGroup,
    List<String> ageBands = const [],
  }) async {
    if (users.isEmpty) return 0;

    int tribesCreated = 0;
    final ageBandUsers = List<AppUser>.from(users);
    ageBandUsers.shuffle();

    // Separate by gender
    final males = ageBandUsers.where((u) => u.gender == 'male').toList();
    final females = ageBandUsers.where((u) => u.gender == 'female').toList();
    final others = ageBandUsers.where((u) => u.gender == 'other').toList();

    // Process sibling pairs first
    for (var pair in siblingPairs) {
      final pairUsers = ageBandUsers
          .where((u) => pair.contains(u.uid) && !processedUserIds.contains(u.uid))
          .toList();

      if (pairUsers.length == 2) {
        final commonInterests = _findCommonInterests(
          pairUsers[0].interests,
          pairUsers[1].interests,
        );

        final candidates = ageBandUsers
            .where((u) =>
                !pair.contains(u.uid) &&
                !processedUserIds.contains(u.uid) &&
                _hasSharedInterest(u.interests, commonInterests))
            .toList();

        // Need at least 1 more for minimum tribe size of 3
        if (candidates.isNotEmpty) {
          final neededCount = AppConstants.minTribeSize - 2; // Already have 2 siblings
          final selectedCandidates = _selectByGenderBalanced(
            candidates,
            pairUsers,
            neededCount.clamp(1, 3),
          );

          final tribeMembers = [...pairUsers, ...selectedCandidates];
          if (tribeMembers.length >= AppConstants.minTribeSize) {
            final allInterests = tribeMembers.expand((u) => u.interests).toList();
            final sharedInterests = _findAllSharedInterests(allInterests);

            final tribeId = await createTribe(
              sailingId: sailingId,
              ageBand: ageBand,
              commonInterests: sharedInterests.take(2).toList(),
              maxMembers: AppConstants.maxTribeSize,
              isMixedAgeGroup: isMixedAgeGroup,
              ageBands: ageBands,
            );

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
            try {
              final requestDoc = siblingSnapshot.docs.firstWhere((doc) {
                final r = SiblingRequest.fromMap(
                    doc.data() as Map<String, dynamic>, doc.id);
                return pair.contains(r.requesterId) && pair.contains(r.targetId);
              });
              await siblingRequestsCollection(sailingId)
                  .doc(requestDoc.id)
                  .update({'status': 'matched'});
            } catch (_) {
              // Sibling request not found, continue
            }

            tribesCreated++;
          }
        }
      }
    }

    // Remove processed users
    males.removeWhere((u) => processedUserIds.contains(u.uid));
    females.removeWhere((u) => processedUserIds.contains(u.uid));
    others.removeWhere((u) => processedUserIds.contains(u.uid));

    // Calculate optimal tribe sizes for remaining users
    final remainingUsers = [...males, ...females, ...others];
    final tribeSizes = calculateOptimalTribeSizes(remainingUsers.length);

    // Create tribes based on optimal sizes
    for (var size in tribeSizes) {
      if (remainingUsers.length < size) break;

      // Try to balance genders
      final tribeMembers = <AppUser>[];

      // Add balanced genders first
      final malesNeeded = (size / 2).floor();
      final femalesNeeded = size - malesNeeded;

      final availableMales = remainingUsers.where((u) => u.gender == 'male').toList();
      final availableFemales = remainingUsers.where((u) => u.gender == 'female').toList();
      final availableOthers = remainingUsers.where((u) => u.gender == 'other').toList();

      tribeMembers.addAll(availableMales.take(malesNeeded));
      tribeMembers.addAll(availableFemales.take(femalesNeeded));

      // Fill remaining spots
      while (tribeMembers.length < size && remainingUsers.isNotEmpty) {
        final nextUser = remainingUsers.firstWhere(
          (u) => !tribeMembers.contains(u),
          orElse: () => remainingUsers.first,
        );
        if (!tribeMembers.contains(nextUser)) {
          tribeMembers.add(nextUser);
        } else {
          break;
        }
      }

      if (tribeMembers.length >= AppConstants.minTribeSize) {
        final allInterests = tribeMembers.expand((u) => u.interests).toList();
        final sharedInterests = _findAllSharedInterests(allInterests);

        final tribeId = await createTribe(
          sailingId: sailingId,
          ageBand: ageBand,
          commonInterests: sharedInterests.take(2).toList(),
          maxMembers: AppConstants.maxTribeSize,
          isMixedAgeGroup: isMixedAgeGroup,
          ageBands: ageBands,
        );

        bool isFirst = true;
        for (var member in tribeMembers) {
          await addMemberToTribe(
            sailingId: sailingId,
            tribeId: tribeId,
            user: member,
            isLeader: isFirst,
          );
          processedUserIds.add(member.uid);
          remainingUsers.remove(member);
          isFirst = false;
        }

        tribesCreated++;
      }
    }

    // Handle leftover users (1-2 remaining) - add to existing tribes
    if (remainingUsers.isNotEmpty && remainingUsers.length < AppConstants.minTribeSize) {
      final existingTribes = await tribesCollection(sailingId)
          .where('ageBand', isEqualTo: ageBand)
          .where('isFull', isEqualTo: false)
          .limit(remainingUsers.length)
          .get();

      for (var doc in existingTribes.docs) {
        if (remainingUsers.isEmpty) break;
        final tribe = Tribe.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        if (tribe.memberCount < tribe.maxMembers) {
          final user = remainingUsers.removeAt(0);
          await addMemberToTribe(
            sailingId: sailingId,
            tribeId: tribe.id,
            user: user,
          );
          processedUserIds.add(user.uid);
        }
      }
    }

    return tribesCreated;
  }

  /// Process users from multiple age bands (18-39) who opted into mixing
  Future<int> _processMixedAgeUsers({
    required String sailingId,
    required List<AppUser> users,
    required List<Set<String>> siblingPairs,
    required QuerySnapshot siblingSnapshot,
    required Set<String> processedUserIds,
  }) async {
    // Collect unique age bands
    final uniqueAgeBands = users.map((u) => u.ageBand).toSet().toList();

    return _processAgeBandUsers(
      sailingId: sailingId,
      ageBand: 'mixed',
      users: users,
      siblingPairs: siblingPairs,
      siblingSnapshot: siblingSnapshot,
      processedUserIds: processedUserIds,
      isMixedAgeGroup: true,
      ageBands: uniqueAgeBands,
    );
  }

  /// Select users for gender balance in a tribe
  List<AppUser> _selectByGenderBalanced(
    List<AppUser> candidates,
    List<AppUser> existingMembers,
    int needed,
  ) {
    final maleCount = existingMembers.where((u) => u.gender == 'male').length;
    final femaleCount = existingMembers.where((u) => u.gender == 'female').length;

    final selected = <AppUser>[];
    final maleCandidates = candidates.where((u) => u.gender == 'male').toList();
    final femaleCandidates = candidates.where((u) => u.gender == 'female').toList();
    final otherCandidates = candidates.where((u) => u.gender == 'other').toList();

    // Try to balance
    if (maleCount < femaleCount && maleCandidates.isNotEmpty) {
      selected.add(maleCandidates.removeAt(0));
    } else if (femaleCount < maleCount && femaleCandidates.isNotEmpty) {
      selected.add(femaleCandidates.removeAt(0));
    }

    // Fill remaining with any available
    final remaining = [...maleCandidates, ...femaleCandidates, ...otherCandidates];
    while (selected.length < needed && remaining.isNotEmpty) {
      selected.add(remaining.removeAt(0));
    }

    return selected;
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

  // ==================== Sea Ya Photo Methods ====================

  /// Submit a Sea Ya photo
  Future<String> submitSeaYaPhoto({
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

      final photo = SeaYaPhoto(
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

      final docRef = await seaYaPhotosCollection(sailingId).add(photo.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit Sea Ya photo: $e');
    }
  }

  /// Get today's Sea Ya photos for a tribe
  Future<List<SeaYaPhoto>> getTribeSeaYaPhotos({
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

      final querySnapshot = await seaYaPhotosCollection(sailingId)
          .where('tribeId', isEqualTo: tribeId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              SeaYaPhoto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get tribe Sea Ya photos: $e');
    }
  }

  /// Stream Sea Ya photos for a tribe
  Stream<List<SeaYaPhoto>> streamTribeSeaYaPhotos({
    required String sailingId,
    required String tribeId,
  }) {
    final todayStart = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );

    return seaYaPhotosCollection(sailingId)
        .where('tribeId', isEqualTo: tribeId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SeaYaPhoto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Check if user has submitted Sea Ya photo today
  Future<bool> hasSubmittedSeaYaPhoto({
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

      final querySnapshot = await seaYaPhotosCollection(sailingId)
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check Sea Ya photo: $e');
    }
  }
}
