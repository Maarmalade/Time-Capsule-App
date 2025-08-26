import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// Legacy DiaryEntry class for backward compatibility
class DiaryEntry {
  final String id;
  final String title;
  final String text;
  final DateTime date;
  final List<DiaryMedia> media;
  final bool isFavorite;
  final Timestamp createdAt;
  final String? imageUrl;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.text,
    required this.date,
    required this.media,
    required this.isFavorite,
    required this.createdAt,
    this.imageUrl,
  });

  factory DiaryEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      title: data['title'] ?? '',
      text: data['text'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      media: (data['media'] as List<dynamic>? ?? [])
          .map((m) => DiaryMedia.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      isFavorite: data['isFavorite'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'],
    );
  }
}

// Legacy DiaryMedia class for backward compatibility
class DiaryMedia {
  final String url;
  final String type;

  DiaryMedia({required this.url, required this.type});

  Map<String, dynamic> toMap() => {'url': url, 'type': type};

  factory DiaryMedia.fromMap(Map<String, dynamic> map) =>
      DiaryMedia(url: map['url'] ?? '', type: map['type'] ?? '');
}

class DiaryService {

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<List<DiaryEntry>> fetchDiaryEntriesForMonth(
      String userId, int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('diaryEntries')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return query.docs.map((doc) => DiaryEntry.fromDoc(doc)).toList();
  }

  Future<String> uploadMedia(
      String userId, String entryId, File file, String type) async {
    final filename = file.path.split('/').last;
    final ref = _storage
        .ref()
        .child('diaryMedia/$userId/$entryId/$filename');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> createDiaryEntry(String userId, Map<String, dynamic> entryData) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('diaryEntries')
        .doc();
    await ref.set(entryData);
    return ref.id;
  }

  Future<void> updateDiaryEntry(
      String userId, String entryId, Map<String, dynamic> updatedData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('diaryEntries')
        .doc(entryId)
        .update(updatedData);
  }

  Future<DiaryEntry?> getDiaryEntryByDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final query = await _firestore
        .collection('users')
        .doc(userId)
        .collection('diaryEntries')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return DiaryEntry.fromDoc(query.docs.first);
  }

  Stream<List<DiaryEntry>> getNostalgiaEntriesForToday(String userId) {
    final now = DateTime.now();
    final todayMonth = now.month;
    final todayDay = now.day;
    final thisYear = now.year;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('diaryEntries')
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromDoc(doc))
            .where((entry) {
              final created = entry.createdAt.toDate();
              return created.month == todayMonth &&
                  created.day == todayDay &&
                  created.year < thisYear;
            })
            .toList());
  }

  // Audio diary support methods
  Future<String> uploadAudioFile(String userId, String entryId, File audioFile) async {
    final filename = audioFile.path.split('/').last;
    final ref = _storage
        .ref()
        .child('diaryAudio/$userId/$entryId/$filename');
    final uploadTask = await ref.putFile(audioFile);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> createAudioDiaryEntry(String userId, Map<String, dynamic> entryData) async {
    final ref = _firestore
        .collection('users')
        .doc(userId)
        .collection('diaryEntries')
        .doc();
    
    // Add audio-specific fields
    entryData['type'] = 'audio';
    entryData['createdAt'] = Timestamp.now();
    entryData['updatedAt'] = Timestamp.now();
    
    await ref.set(entryData);
    return ref.id;
  }
}