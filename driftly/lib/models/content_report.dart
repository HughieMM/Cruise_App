import 'package:cloud_firestore/cloud_firestore.dart';

/// ContentReport Model
///
/// Represents a report against a user or content
/// If a photo receives 2+ reports across ANY chat, it gets permanently deleted
///
/// Firestore path: /reports/{reportId}
class ContentReport {
  final String id;
  final String reporterId; // User who reported
  final String reportedUserId; // User being reported
  final String? contentId; // ID of reported content (message, photo, etc.)
  final String contentType; // 'message', 'photo', 'profile', 'user'
  final String reason; // 'inappropriate_photo', 'harassment', 'spam', 'other'
  final String? details; // Additional details from reporter
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'actioned', 'dismissed'
  final String? sailingId;
  final String? photoUrl; // URL of reported photo for auto-deletion

  ContentReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.contentId,
    required this.contentType,
    required this.reason,
    this.details,
    required this.createdAt,
    this.status = 'pending',
    this.sailingId,
    this.photoUrl,
  });

  factory ContentReport.fromMap(Map<String, dynamic> map, String documentId) {
    return ContentReport(
      id: documentId,
      reporterId: map['reporterId'] as String? ?? '',
      reportedUserId: map['reportedUserId'] as String? ?? '',
      contentId: map['contentId'] as String?,
      contentType: map['contentType'] as String? ?? 'user',
      reason: map['reason'] as String? ?? 'other',
      details: map['details'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      sailingId: map['sailingId'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'contentId': contentId,
      'contentType': contentType,
      'reason': reason,
      'details': details,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'sailingId': sailingId,
      'photoUrl': photoUrl,
    };
  }

  @override
  String toString() {
    return 'ContentReport(id: $id, reason: $reason, contentType: $contentType)';
  }
}

/// UserBlock Model
///
/// Represents a blocked user relationship
///
/// Firestore path: /users/{userId}/blockedUsers/{blockedUserId}
class UserBlock {
  final String blockedUserId;
  final DateTime blockedAt;
  final String? reason;

  UserBlock({
    required this.blockedUserId,
    required this.blockedAt,
    this.reason,
  });

  factory UserBlock.fromMap(Map<String, dynamic> map, String documentId) {
    return UserBlock(
      blockedUserId: documentId,
      blockedAt: (map['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: map['reason'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'blockedAt': Timestamp.fromDate(blockedAt),
      'reason': reason,
    };
  }
}

/// Report reason options
class ReportReasons {
  ReportReasons._();

  static const List<ReportOption> photoReasons = [
    ReportOption(
      value: 'inappropriate_photo',
      label: 'Inappropriate/Explicit Content',
      description: 'Contains nudity or sexually explicit content',
    ),
    ReportOption(
      value: 'offensive_content',
      label: 'Offensive Content',
      description: 'Contains hate speech or offensive imagery',
    ),
    ReportOption(
      value: 'violence',
      label: 'Violence or Gore',
      description: 'Contains violent or disturbing content',
    ),
    ReportOption(
      value: 'other',
      label: 'Other',
      description: 'Other violation not listed above',
    ),
  ];

  static const List<ReportOption> userReasons = [
    ReportOption(
      value: 'harassment',
      label: 'Harassment',
      description: 'Bullying, threatening, or harassing behavior',
    ),
    ReportOption(
      value: 'inappropriate_messages',
      label: 'Inappropriate Messages',
      description: 'Sending unwanted explicit or offensive messages',
    ),
    ReportOption(
      value: 'fake_profile',
      label: 'Fake Profile',
      description: 'Using fake photos or impersonating someone',
    ),
    ReportOption(
      value: 'spam',
      label: 'Spam',
      description: 'Sending spam or promotional content',
    ),
    ReportOption(
      value: 'other',
      label: 'Other',
      description: 'Other violation not listed above',
    ),
  ];
}

class ReportOption {
  final String value;
  final String label;
  final String description;

  const ReportOption({
    required this.value,
    required this.label,
    required this.description,
  });
}
