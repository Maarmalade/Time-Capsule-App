import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/media_file_model.dart';

class MediaService {
  final _firestore = FirebaseFirestore.instance;

  // Create media file
  Future<String> createMedia(String folderId, MediaFileModel media) async {
    final ref = _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .doc();
    await ref.set(media.toMap());
    return ref.id;
  }

  // Update media file
  Future<void> updateMedia(String folderId, String mediaId, Map<String, dynamic> data) async {
    await _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .doc(mediaId)
        .update(data);
  }

  // Delete media file
  Future<void> deleteMedia(String folderId, String mediaId) async {
    await _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .doc(mediaId)
        .delete();
  }

  // Stream media files in a folder
  Stream<List<MediaFileModel>> streamMedia(String folderId) {
    return _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MediaFileModel.fromDoc(d)).toList());
  }
}