import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/diary_entry_model.dart';

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
}