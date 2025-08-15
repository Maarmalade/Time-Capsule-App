import 'package:cloud_firestore/cloud_firestore.dart';

class SharedFolderNotification {
  final String id;
  final String folderId;
  final String folderName;
  final String ownerId;
  final String ownerUsername;
  final String contributorId;
  final DateTime createdAt;
  final bool isRead;

  SharedFolderNotification({
    required this.id,
    required this.folderId,
    required this.folderName,
    required this.ownerId,
    required this.ownerUsername,
    required this.contributorId,
    required this.createdAt,
    this.isRead = false,
  });

  // Factory constructor to create SharedFolderNotification from Firestore document
  factory SharedFolderNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SharedFolderNotification(
      id: doc.id,
      folderId: data['folderId'] ?? '',
      folderName: data['folderName'] ?? '',
      ownerId: data['ownerId'] ?? '',
      ownerUsername: data['ownerUsername'] ?? '',
      contributorId: data['contributorId'] ?? '',
      createdAt: (data['createdAt'] is Timestamp && data['createdAt'] != null)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  // Convert SharedFolderNotification to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'folderId': folderId,
      'folderName': folderName,
      'ownerId': ownerId,
      'ownerUsername': ownerUsername,
      'contributorId': contributorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  // Create a copy of SharedFolderNotification with updated fields
  SharedFolderNotification copyWith({
    String? id,
    String? folderId,
    String? folderName,
    String? ownerId,
    String? ownerUsername,
    String? contributorId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return SharedFolderNotification(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      folderName: folderName ?? this.folderName,
      ownerId: ownerId ?? this.ownerId,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      contributorId: contributorId ?? this.contributorId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() {
    return 'SharedFolderNotification(id: $id, folderId: $folderId, folderName: $folderName, ownerId: $ownerId, ownerUsername: $ownerUsername, contributorId: $contributorId, createdAt: $createdAt, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedFolderNotification &&
        other.id == id &&
        other.folderId == folderId &&
        other.folderName == folderName &&
        other.ownerId == ownerId &&
        other.ownerUsername == ownerUsername &&
        other.contributorId == contributorId &&
        other.createdAt == createdAt &&
        other.isRead == isRead;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        folderId.hashCode ^
        folderName.hashCode ^
        ownerId.hashCode ^
        ownerUsername.hashCode ^
        contributorId.hashCode ^
        createdAt.hashCode ^
        isRead.hashCode;
  }
}