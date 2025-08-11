import 'package:cloud_firestore/cloud_firestore.dart';

class FolderModel {
  final String id;
  final String name;
  final String userId;
  final String? parentFolderId;
  final String? description;
  final String? coverImageUrl;
  final Timestamp createdAt;

  FolderModel({
    required this.id,
    required this.name,
    required this.userId,
    this.parentFolderId,
    this.description,
    this.coverImageUrl,
    required this.createdAt,
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
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'userId': userId,
    'parentFolderId': parentFolderId, // Always include, even if null
    'description': description,
    'coverImageUrl': coverImageUrl,
    'createdAt': createdAt,
  };
}