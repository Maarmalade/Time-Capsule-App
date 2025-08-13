import 'package:cloud_firestore/cloud_firestore.dart';

class Friendship {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.createdAt,
  });

  // Factory constructor to create Friendship from Firestore document
  factory Friendship.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Friendship(
      id: doc.id,
      userId1: data['userId1'] ?? '',
      userId2: data['userId2'] ?? '',
      createdAt: (data['createdAt'] is Timestamp && data['createdAt'] != null)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Convert Friendship to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a copy of Friendship with updated fields
  Friendship copyWith({
    String? id,
    String? userId1,
    String? userId2,
    DateTime? createdAt,
  }) {
    return Friendship(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods for bidirectional relationship handling
  bool involves(String userId) {
    return userId1 == userId || userId2 == userId;
  }

  String getOtherUserId(String currentUserId) {
    if (userId1 == currentUserId) {
      return userId2;
    } else if (userId2 == currentUserId) {
      return userId1;
    } else {
      throw ArgumentError('User $currentUserId is not part of this friendship');
    }
  }

  // Create a friendship with ordered user IDs (for consistent storage)
  static Friendship createOrdered({
    required String id,
    required String userIdA,
    required String userIdB,
    required DateTime createdAt,
  }) {
    // Order user IDs alphabetically for consistent storage
    final orderedIds = [userIdA, userIdB]..sort();
    return Friendship(
      id: id,
      userId1: orderedIds[0],
      userId2: orderedIds[1],
      createdAt: createdAt,
    );
  }

  // Validation methods
  bool isValid() {
    return userId1.isNotEmpty && 
           userId2.isNotEmpty && 
           userId1 != userId2;
  }

  @override
  String toString() {
    return 'Friendship(id: $id, userId1: $userId1, userId2: $userId2, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friendship &&
        other.id == id &&
        other.userId1 == userId1 &&
        other.userId2 == userId2 &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId1.hashCode ^
        userId2.hashCode ^
        createdAt.hashCode;
  }
}