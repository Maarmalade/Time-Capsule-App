import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus { pending, accepted, declined }

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderUsername;
  final String? senderProfilePictureUrl;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderUsername,
    this.senderProfilePictureUrl,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  // Factory constructor to create FriendRequest from Firestore document
  factory FriendRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return FriendRequest(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      senderUsername: data['senderUsername'] ?? '',
      senderProfilePictureUrl: data['senderProfilePictureUrl'],
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] is Timestamp && data['createdAt'] != null)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      respondedAt: (data['respondedAt'] is Timestamp && data['respondedAt'] != null)
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // Convert FriendRequest to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'senderUsername': senderUsername,
      'senderProfilePictureUrl': senderProfilePictureUrl,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }

  // Create a copy of FriendRequest with updated fields
  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? senderUsername,
    String? senderProfilePictureUrl,
    FriendRequestStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderProfilePictureUrl: senderProfilePictureUrl ?? this.senderProfilePictureUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  // Helper method to parse status from string
  static FriendRequestStatus _parseStatus(dynamic statusValue) {
    if (statusValue is String) {
      switch (statusValue.toLowerCase()) {
        case 'pending':
          return FriendRequestStatus.pending;
        case 'accepted':
          return FriendRequestStatus.accepted;
        case 'declined':
          return FriendRequestStatus.declined;
        default:
          return FriendRequestStatus.pending;
      }
    }
    return FriendRequestStatus.pending;
  }

  // Validation methods
  bool isValid() {
    return senderId.isNotEmpty && 
           receiverId.isNotEmpty && 
           senderUsername.isNotEmpty &&
           senderId != receiverId;
  }

  bool isPending() => status == FriendRequestStatus.pending;
  bool isAccepted() => status == FriendRequestStatus.accepted;
  bool isDeclined() => status == FriendRequestStatus.declined;

  @override
  String toString() {
    return 'FriendRequest(id: $id, senderId: $senderId, receiverId: $receiverId, senderUsername: $senderUsername, status: $status, createdAt: $createdAt, respondedAt: $respondedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest &&
        other.id == id &&
        other.senderId == senderId &&
        other.receiverId == receiverId &&
        other.senderUsername == senderUsername &&
        other.senderProfilePictureUrl == senderProfilePictureUrl &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.respondedAt == respondedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        senderId.hashCode ^
        receiverId.hashCode ^
        senderUsername.hashCode ^
        senderProfilePictureUrl.hashCode ^
        status.hashCode ^
        createdAt.hashCode ^
        respondedAt.hashCode;
  }
}