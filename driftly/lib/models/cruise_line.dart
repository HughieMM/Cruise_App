import 'package:cloud_firestore/cloud_firestore.dart';

/// CruiseLine Model
///
/// Represents a cruise line company (e.g., Royal Caribbean, Carnival)
///
/// Firestore path: /cruiseLines/{cruiseLineId}
class CruiseLine {
  final String id;
  final String name;
  final String? logoUrl;
  final DateTime createdAt;

  CruiseLine({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.createdAt,
  });

  /// Create CruiseLine from Firestore document
  factory CruiseLine.fromMap(Map<String, dynamic> map, String documentId) {
    return CruiseLine(
      id: documentId,
      name: map['name'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert CruiseLine to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() => 'CruiseLine(id: $id, name: $name)';
}
