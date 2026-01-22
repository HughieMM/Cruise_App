import 'package:cloud_firestore/cloud_firestore.dart';

/// Ship Model
///
/// Represents a cruise ship
///
/// Firestore path: /ships/{shipId}
class Ship {
  final String id;
  final String name;
  final String cruiseLineId;
  final int? capacity;
  final String? imageUrl;
  final DateTime createdAt;

  Ship({
    required this.id,
    required this.name,
    required this.cruiseLineId,
    this.capacity,
    this.imageUrl,
    required this.createdAt,
  });

  /// Create Ship from Firestore document
  factory Ship.fromMap(Map<String, dynamic> map, String documentId) {
    return Ship(
      id: documentId,
      name: map['name'] as String? ?? '',
      cruiseLineId: map['cruiseLineId'] as String? ?? '',
      capacity: map['capacity'] as int?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Ship to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cruiseLineId': cruiseLineId,
      'capacity': capacity,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() => 'Ship(id: $id, name: $name, cruiseLine: $cruiseLineId)';
}
