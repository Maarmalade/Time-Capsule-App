import 'package:cloud_firestore/cloud_firestore.dart';

class MediaFileModel {
  final String id;
  final String folderId;
  final String type; // image, video, text, audio
  final String url;
  final String? title;
  final String? description;
  final String? uploadedBy; // User ID of who uploaded this media
  final Timestamp createdAt;

  MediaFileModel({
    required this.id,
    required this.folderId,
    required this.type,
    required this.url,
    this.title,
    this.description,
    this.uploadedBy,
    required this.createdAt,
  });

  factory MediaFileModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MediaFileModel(
      id: doc.id,
      folderId: data['folderId'],
      type: data['type'],
      url: data['url'],
      title: data['title'],
      description: data['description'],
      uploadedBy: data['uploadedBy'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'folderId': folderId,
    'type': type,
    'url': url,
    'title': title,
    'description': description,
    'uploadedBy': uploadedBy,
    'createdAt': createdAt,
  };
}