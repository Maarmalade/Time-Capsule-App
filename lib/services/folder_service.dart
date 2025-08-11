import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder_model.dart' as folder_model;

class FolderService {
  final _firestore = FirebaseFirestore.instance;

  // Create folder
  Future<String> createFolder(folder_model.FolderModel folder) async {
    final ref = _firestore.collection('folders').doc();
    final folderWithId = folder_model.FolderModel(
      id: ref.id,
      name: folder.name,
      userId: folder.userId,
      parentFolderId: folder.parentFolderId,
      description: folder.description,
      coverImageUrl: folder.coverImageUrl,
      createdAt: folder.createdAt,
    );
    await ref.set(folderWithId.toMap());
    return ref.id;
  }

  // Update folder
  Future<void> updateFolder(String folderId, Map<String, dynamic> data) async {
    await _firestore.collection('folders').doc(folderId).update(data);
  }

  // Delete folder and all nested folders/media
  Future<void> deleteFolder(String folderId) async {
    // Delete all subfolders recursively
    final subfolders = await _firestore
        .collection('folders')
        .where('parentFolderId', isEqualTo: folderId)
        .get();
    for (final doc in subfolders.docs) {
      await deleteFolder(doc.id);
    }
    // Delete all media in this folder
    final media = await _firestore
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .get();
    for (final doc in media.docs) {
      await doc.reference.delete();
    }
    // Delete the folder itself
    await _firestore.collection('folders').doc(folderId).delete();
  }

  // Stream folders (top-level or nested)
  Stream<List<folder_model.FolderModel>> streamFolders({required String userId, String? parentFolderId}) {
    Query query = _firestore.collection('folders').where('userId', isEqualTo: userId);
    if (parentFolderId == null) {
      query = query.where('parentFolderId', isNull: true);
    } else {
      query = query.where('parentFolderId', isEqualTo: parentFolderId);
    }
    return query
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snap) => snap.docs.map((d) => folder_model.FolderModel.fromDoc(d)).toList());
  }

  // Get a folder by ID
  Future<folder_model.FolderModel?> getFolder(String folderId) async {
    final doc = await _firestore.collection('folders').doc(folderId).get();
    if (!doc.exists) return null;
    return folder_model.FolderModel.fromDoc(doc);
  }
}