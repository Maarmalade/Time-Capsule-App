import 'package:cloud_firestore/cloud_firestore.dart';

class FolderModel {
  final String id;
  final String name;
  final String userId;
  final String? parentFolderId;
  final String? description;
  final String? coverImageUrl;
  final Timestamp createdAt;
  final bool isShared;
  final bool isPublic;
  final bool isLocked;
  final Timestamp? lockedAt;
  final List<String> contributorIds;

  FolderModel({
    required this.id,
    required this.name,
    required this.userId,
    this.parentFolderId,
    this.description,
    this.coverImageUrl,
    required this.createdAt,
    this.isShared = false,
    this.isPublic = false,
    this.isLocked = false,
    this.lockedAt,
    this.contributorIds = const [],
  });

  factory FolderModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FolderModel(
      id: doc.id,
      name: data['name'] ?? '',
      userId: data['userId'] ?? '',
      parentFolderId: data.containsKey('parentFolderId') ? data['parentFolderId'] : null,
      description: data['description'],
      coverImageUrl: data['coverImageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isShared: data['isShared'] ?? false,
      isPublic: data['isPublic'] ?? false,
      isLocked: data['isLocked'] ?? false,
      lockedAt: data['lockedAt'],
      contributorIds: List<String>.from(data['contributorIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'userId': userId,
    'parentFolderId': parentFolderId, // Always include, even if null
    'description': description,
    'coverImageUrl': coverImageUrl,
    'createdAt': createdAt,
    'isShared': isShared,
    'isPublic': isPublic,
    'isLocked': isLocked,
    'lockedAt': lockedAt,
    'contributorIds': contributorIds,
  };

  // Add copyWith method for immutable updates
  FolderModel copyWith({
    String? id,
    String? name,
    String? userId,
    String? parentFolderId,
    String? description,
    String? coverImageUrl,
    Timestamp? createdAt,
    bool? isShared,
    bool? isPublic,
    bool? isLocked,
    Timestamp? lockedAt,
    List<String>? contributorIds,
  }) {
    return FolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      parentFolderId: parentFolderId ?? this.parentFolderId,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      isShared: isShared ?? this.isShared,
      isPublic: isPublic ?? this.isPublic,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      contributorIds: contributorIds ?? this.contributorIds,
    );
  }
}