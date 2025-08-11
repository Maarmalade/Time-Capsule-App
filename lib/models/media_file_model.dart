import 'package:cloud_firestore/cloud_firestore.dart';

class MediaFileModel {
  final String id;
  final String folderId;
  final String type; // image, video, text, audio
  final String url;
  final String? title;
  final String? description;
  final Timestamp createdAt;

  MediaFileModel({
    required this.id,
    required this.folderId,
    required this.type,
    required this.url,
    this.title,
    this.description,
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
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'folderId': folderId,
    'type': type,
    'url': url,
    'title': title,
    'description': description,
    'createdAt': createdAt,
  };
}