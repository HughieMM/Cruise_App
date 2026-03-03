import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/content_report.dart';
import 'storage_service.dart';

/// ModerationService
///
/// Handles content moderation including:
/// - Reporting users and content
/// - Blocking users
/// - Auto-deleting photos with 2+ reports
class ModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  /// Reports collection
  CollectionReference get reportsCollection => _firestore.collection('reports');

  /// Get blocked users collection for a user
  CollectionReference blockedUsersCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('blockedUsers');
  }

  // ==================== Reporting ====================

  /// Submit a content report
  /// Auto-deletes photos if they receive 2+ reports
  Future<String> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String contentType,
    required String reason,
    String? contentId,
    String? details,
    String? sailingId,
    String? photoUrl,
  }) async {
    try {
      final report = ContentReport(
        id: '',
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        contentId: contentId,
        contentType: contentType,
        reason: reason,
        details: details,
        createdAt: DateTime.now(),
        sailingId: sailingId,
        photoUrl: photoUrl,
      );

      final docRef = await reportsCollection.add(report.toMap());

      // Check if photo needs auto-deletion (2+ reports)
      if (contentType == 'photo' && photoUrl != null) {
        await _checkAndDeletePhoto(photoUrl);
      }

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Check if a photo has 2+ reports and delete it
  Future<void> _checkAndDeletePhoto(String photoUrl) async {
    try {
      // Count reports for this photo URL
      final querySnapshot = await reportsCollection
          .where('photoUrl', isEqualTo: photoUrl)
          .where('contentType', isEqualTo: 'photo')
          .get();

      // If 2+ reports, delete the photo
      if (querySnapshot.docs.length >= 2) {
        await _storageService.deletePhoto(photoUrl);

        // Update all reports for this photo as actioned
        for (final doc in querySnapshot.docs) {
          await doc.reference.update({'status': 'actioned'});
        }

        // Also delete the photo document from Firestore if it exists
        // This handles hangout photos and other photo records
        await _deletePhotoFromFirestore(photoUrl);
      }
    } catch (_) {
      // Silently handle moderation errors - photo may already be deleted
    }
  }

  /// Delete photo references from Firestore
  Future<void> _deletePhotoFromFirestore(String photoUrl) async {
    try {
      // Search for hangout photos with this URL
      final hangoutPhotos = await _firestore
          .collectionGroup('photos')
          .where('photoUrl', isEqualTo: photoUrl)
          .get();

      for (final doc in hangoutPhotos.docs) {
        await doc.reference.delete();
      }

      // Search for messages with this photo URL
      final messages = await _firestore
          .collectionGroup('messages')
          .where('photoUrl', isEqualTo: photoUrl)
          .get();

      for (final doc in messages.docs) {
        await doc.reference.delete();
      }
    } catch (_) {
      // Silently handle cleanup errors - documents may already be deleted
    }
  }

  /// Check if user has already reported this content
  Future<bool> hasUserReported({
    required String reporterId,
    required String contentId,
    required String contentType,
  }) async {
    try {
      final querySnapshot = await reportsCollection
          .where('reporterId', isEqualTo: reporterId)
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get report count for a piece of content
  Future<int> getReportCount(String contentId, String contentType) async {
    try {
      final snapshot = await reportsCollection
          .where('contentId', isEqualTo: contentId)
          .where('contentType', isEqualTo: contentType)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // ==================== Blocking ====================

  /// Block a user
  Future<void> blockUser({
    required String userId,
    required String blockedUserId,
    String? reason,
  }) async {
    try {
      final block = UserBlock(
        blockedUserId: blockedUserId,
        blockedAt: DateTime.now(),
        reason: reason,
      );

      await blockedUsersCollection(userId).doc(blockedUserId).set(block.toMap());
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// Unblock a user
  Future<void> unblockUser({
    required String userId,
    required String blockedUserId,
  }) async {
    try {
      await blockedUsersCollection(userId).doc(blockedUserId).delete();
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// Check if a user is blocked
  Future<bool> isUserBlocked({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final doc = await blockedUsersCollection(userId).doc(otherUserId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get list of blocked user IDs
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final querySnapshot = await blockedUsersCollection(userId).get();
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream blocked users for real-time updates
  Stream<List<UserBlock>> streamBlockedUsers(String userId) {
    return blockedUsersCollection(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserBlock.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }
}
