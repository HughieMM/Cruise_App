import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/connection_request.dart';
import '../models/message.dart';
import '../utils/input_validator.dart';
import '../utils/constants.dart';

/// ConnectionService
///
/// Handles "First Mates" — Pod-only 1:1 connect requests and, once
/// accepted, private direct messaging between the two people. Deliberately
/// not offered from Tribe chat (product decision: Tribe stays a closed
/// unit, no side-channel DMs forming from within it).
class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Connection requests are sailing-scoped, like pods/tribes/sibling
  /// requests — a connect request only makes sense between two people who
  /// are actually sailing together.
  CollectionReference connectionRequestsCollection(String sailingId) {
    return _firestore.collection('sailings').doc(sailingId).collection('connectionRequests');
  }

  /// Direct message threads are NOT sailing-scoped — a connection made on
  /// one cruise should keep working after it ends.
  CollectionReference get directMessagesCollection => _firestore.collection('directMessages');

  CollectionReference directMessagesFor(String threadId) {
    return directMessagesCollection.doc(threadId).collection('messages');
  }

  /// Deterministic sorted-pair thread ID — the first such convention in
  /// this codebase (everything else uses Firestore auto-IDs), needed here
  /// so both sides always resolve to the same thread and creation can be
  /// idempotent.
  String threadIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return sorted.join('_');
  }

  /// The existing pending/accepted/declined request between two users on a
  /// sailing, if any. Two simple single-field-pair queries combined
  /// client-side rather than a composite OR query, consistent with how the
  /// rest of this codebase avoids compound Firestore queries.
  Future<ConnectionRequest?> getConnectionBetween({
    required String sailingId,
    required String uidA,
    required String uidB,
  }) async {
    final asRequester = await connectionRequestsCollection(sailingId)
        .where('requesterId', isEqualTo: uidA)
        .where('targetId', isEqualTo: uidB)
        .limit(1)
        .get();
    if (asRequester.docs.isNotEmpty) {
      final doc = asRequester.docs.first;
      return ConnectionRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }

    final asTarget = await connectionRequestsCollection(sailingId)
        .where('requesterId', isEqualTo: uidB)
        .where('targetId', isEqualTo: uidA)
        .limit(1)
        .get();
    if (asTarget.docs.isNotEmpty) {
      final doc = asTarget.docs.first;
      return ConnectionRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }

    return null;
  }

  /// Send a connect request. Throws if one already exists between the pair
  /// (pending, accepted, or declined) — dedupe-checked client-side first,
  /// mirroring TribeService.createSiblingRequest's existing pattern.
  Future<void> sendConnectionRequest({
    required String sailingId,
    required String requesterId,
    required String requesterName,
    required String targetId,
    required String targetName,
  }) async {
    final existing = await getConnectionBetween(
      sailingId: sailingId,
      uidA: requesterId,
      uidB: targetId,
    );
    if (existing != null) {
      throw Exception('A connection request already exists with this person');
    }

    final request = ConnectionRequest(
      id: '',
      sailingId: sailingId,
      requesterId: requesterId,
      requesterName: requesterName,
      targetId: targetId,
      targetName: targetName,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await connectionRequestsCollection(sailingId).add(request.toMap());
  }

  Future<void> acceptConnectionRequest({
    required String sailingId,
    required String requestId,
  }) async {
    await connectionRequestsCollection(sailingId).doc(requestId).update({
      'status': 'accepted',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> declineConnectionRequest({
    required String sailingId,
    required String requestId,
  }) async {
    await connectionRequestsCollection(sailingId).doc(requestId).update({
      'status': 'declined',
      'respondedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Pending requests where the given user is the target — what they see
  /// as "incoming requests" in First Mates.
  Stream<List<ConnectionRequest>> streamIncomingRequests(String sailingId, String userId) {
    return connectionRequestsCollection(sailingId)
        .where('targetId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConnectionRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Accepted connections involving the given user, on either side.
  /// Manually merges two simple streams (no OR-query/composite-index risk,
  /// no extra dependency) rather than a single compound query.
  Stream<List<ConnectionRequest>> streamAcceptedConnections(String sailingId, String userId) {
    final controller = StreamController<List<ConnectionRequest>>.broadcast();
    var asRequesterList = <ConnectionRequest>[];
    var asTargetList = <ConnectionRequest>[];
    var haveRequester = false;
    var haveTarget = false;

    void emit() {
      if (!haveRequester || !haveTarget) return;
      final combined = [...asRequesterList, ...asTargetList];
      combined.sort((a, b) =>
          (b.respondedAt ?? b.createdAt).compareTo(a.respondedAt ?? a.createdAt));
      controller.add(combined);
    }

    final sub1 = connectionRequestsCollection(sailingId)
        .where('requesterId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      asRequesterList = snapshot.docs
          .map((doc) => ConnectionRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      haveRequester = true;
      emit();
    });

    final sub2 = connectionRequestsCollection(sailingId)
        .where('targetId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .listen((snapshot) {
      asTargetList = snapshot.docs
          .map((doc) => ConnectionRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      haveTarget = true;
      emit();
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
    };

    return controller.stream;
  }

  // ==================== Direct Messages ====================

  /// Ensures the thread doc exists (idempotent — safe to call every time a
  /// DM screen opens), then returns its ID. Only ever *creates* the doc if
  /// missing — never re-writes an existing thread, since the update rule
  /// only permits touching `lastMessageAt` and a resent `createdAt` via
  /// serverTimestamp() would resolve to a new value on every open, tripping
  /// that restriction.
  ///
  /// A thread that doesn't exist yet can't be read (the read rule checks
  /// `resource.data.participantIds`, which errors when `resource` is null),
  /// so a permission-denied on the initial get() is the "not created yet"
  /// signal here — safe to rely on since the caller is always one of the
  /// two intended participants. The create is also wrapped defensively in
  /// case both participants open the thread for the first time at once —
  /// if the other side's create already won, this one's is a harmless
  /// no-op update that we don't need to succeed.
  Future<String> getOrCreateThread(String uidA, String uidB) async {
    final threadId = threadIdFor(uidA, uidB);
    final docRef = directMessagesCollection.doc(threadId);

    var exists = false;
    try {
      exists = (await docRef.get()).exists;
    } catch (_) {
      exists = false;
    }

    if (!exists) {
      try {
        await docRef.set({
          'participantIds': [uidA, uidB]..sort(),
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Other participant's create already won the race — fine.
      }
    }

    return threadId;
  }

  /// Send a direct message. Reuses the Message model exactly like Tribe
  /// chat does, repurposing its `podId` field to hold the DM thread ID.
  Future<void> sendDirectMessage({
    required String threadId,
    required String userId,
    required String userName,
    required String text,
    String? userPhotoUrl,
  }) async {
    final validationError = InputValidator.validateMessage(text);
    if (validationError != null) {
      throw Exception(validationError);
    }

    final sanitizedText = InputValidator.sanitizeAndTruncate(
      text,
      AppConstants.maxMessageLength,
    );

    final message = Message(
      id: '',
      podId: threadId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      text: sanitizedText,
      timestamp: DateTime.now(),
    );

    await directMessagesFor(threadId).add(message.toMap());
    await directMessagesCollection.doc(threadId).update({
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Message>> streamDirectMessages(String threadId) {
    return directMessagesFor(threadId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
