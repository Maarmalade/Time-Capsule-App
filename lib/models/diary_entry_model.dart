import 'package:cloud_firestore/cloud_firestore.dart';


class DiaryMedia {
  final String url;
  final String type; // "image" or "video"

  DiaryMedia({required this.url, required this.type});

  Map<String, dynamic> toMap() => {'url': url, 'type': type};

  factory DiaryMedia.fromMap(Map<String, dynamic> map) =>
      DiaryMedia(url: map['url'], type: map['type']);
}

class DiaryEntry {
  final String id;
  final String title; // <-- Add this line
  final DateTime date;
  final String text;
  final List<DiaryMedia> media;
  final bool isFavorite;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? imageUrl;

  DiaryEntry({
    required this.id,
    required this.title, // <-- Add this line
    required this.date,
    required this.text,
    required this.media,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'text': text,
        'media': media.map((m) => m.toMap()).toList(),
        'isFavorite': isFavorite,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'imageUrl': imageUrl,
      };

  factory DiaryEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      title: data['title'] ?? '', // <-- Add this line
      date: (data['date'] as Timestamp).toDate(),
      text: data['text'] ?? '',
      media: (data['media'] as List<dynamic>? ?? [])
          .map((m) => DiaryMedia.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      isFavorite: data['isFavorite'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'] as String?,
    );
  }
}