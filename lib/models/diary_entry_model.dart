import 'package:cloud_firestore/cloud_firestore.dart';
import 'media_file_model.dart';

/// Model for media attachments within diary entries
class DiaryMediaAttachment {
  final String id;
  final String type; // 'image', 'video', 'audio'
  final String url;
  final String? caption;
  final int position; // Position within content

  DiaryMediaAttachment({
    required this.id,
    required this.type,
    required this.url,
    this.caption,
    required this.position,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'url': url,
        'caption': caption,
        'position': position,
      };

  factory DiaryMediaAttachment.fromMap(Map<String, dynamic> map) =>
      DiaryMediaAttachment(
        id: map['id'] ?? '',
        type: map['type'] ?? '',
        url: map['url'] ?? '',
        caption: map['caption'],
        position: map['position'] ?? 0,
      );
}

/// Diary entry model extending MediaFileModel with diary-specific fields
class DiaryEntryModel extends MediaFileModel {
  final String content; // Rich text content
  final List<DiaryMediaAttachment> attachments;
  final Timestamp? lastModified;
  @override
  final String? uploadedBy; // For shared folders
  final Timestamp diaryDate; // The date this diary entry is for (separate from createdAt)
  final bool isFavorite; // Whether this entry is marked as favorite for nostalgia reminders

  DiaryEntryModel({
    required super.id,
    required super.folderId,
    required super.title,
    required this.content,
    required this.attachments,
    required super.createdAt,
    required this.diaryDate,
    this.lastModified,
    this.uploadedBy,
    this.isFavorite = false,
    super.description,
  }) : super(
          type: 'diary',
          url: '',
        );

  @override
  Map<String, dynamic> toMap() {
    final baseMap = super.toMap();
    baseMap.addAll({
      'content': content,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'lastModified': lastModified,
      'uploadedBy': uploadedBy,
      'diaryDate': diaryDate,
      'isFavorite': isFavorite,
    });
    return baseMap;
  }

  factory DiaryEntryModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntryModel(
      id: doc.id,
      folderId: data['folderId'] ?? '',
      title: data['title'],
      content: data['content'] ?? '',
      attachments: (data['attachments'] as List<dynamic>? ?? [])
          .map((a) => DiaryMediaAttachment.fromMap(Map<String, dynamic>.from(a)))
          .toList(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      diaryDate: data['diaryDate'] ?? data['createdAt'] ?? Timestamp.now(), // Fallback for existing entries
      lastModified: data['lastModified'],
      uploadedBy: data['uploadedBy'],
      isFavorite: data['isFavorite'] ?? false,
      description: data['description'],
    );
  }

  /// Create a copy of this diary entry with updated fields
  DiaryEntryModel copyWith({
    String? id,
    String? folderId,
    String? title,
    String? content,
    List<DiaryMediaAttachment>? attachments,
    Timestamp? createdAt,
    Timestamp? diaryDate,
    Timestamp? lastModified,
    String? uploadedBy,
    bool? isFavorite,
    String? description,
  }) {
    return DiaryEntryModel(
      id: id ?? this.id,
      folderId: folderId ?? this.folderId,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      diaryDate: diaryDate ?? this.diaryDate,
      lastModified: lastModified ?? this.lastModified,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      isFavorite: isFavorite ?? this.isFavorite,
      description: description ?? this.description,
    );
  }
}