import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/folder_model.dart';
import '../services/folder_service.dart';

/// Utility to fix folder access issues and invalid condition errors
class FolderAccessFix {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FolderService _folderService = FolderService();

  /// Fix the "Operations failed due to invalid condition" error
  /// by using a simpler query approach
  static Stream<List<FolderModel>> getAccessibleFoldersStream(
    String userId, {
    String? parentFolderId,
  }) {
    try {
      if (userId.isEmpty) {
        return Stream.value([]);
      }

      // Use a simple query that gets all folders and filters client-side
      Query query = _firestore.collection('folders');

      // Add parent folder filter
      if (parentFolderId == null) {
        query = query.where('parentFolderId', isNull: true);
      } else {
        query = query.where('parentFolderId', isEqualTo: parentFolderId);
      }

      return query.snapshots().map((snapshot) {
        final folders = <FolderModel>[];
        
        for (final doc in snapshot.docs) {
          try {
            final folder = FolderModel.fromDoc(doc);
            
            // Check if user can access this folder
            if (_canUserAccessFolder(folder, userId)) {
              folders.add(folder);
            }
          } catch (e) {
            // Skip folders that can't be parsed
            continue;
          }
        }

        // Sort by creation date
        folders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return folders;
      });
    } catch (e) {
      // Return empty stream on any error
      return Stream.value([]);
    }
  }

  /// Check if user can access a folder (owner, contributor, or public)
  static bool _canUserAccessFolder(FolderModel folder, String userId) {
    try {
      // User is the owner
      if (folder.userId == userId) {
        return true;
      }

      // User is a contributor to a shared folder
      if (folder.isShared && folder.contributorIds.contains(userId)) {
        return true;
      }

      // Folder is public
      if (folder.isPublic) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Fix shared folder data loading issues
  static Future<Map<String, dynamic>?> getSharedFolderDataSafe(String folderId) async {
    try {
      if (folderId.isEmpty) return null;

      final doc = await _firestore.collection('folders').doc(folderId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final isShared = data['isShared'] ?? false;

      if (!isShared) return null;

      // Return the shared folder data with safe defaults
      return {
        'contributorIds': List<String>.from(data['contributorIds'] ?? []),
        'ownerId': data['ownerId'] ?? data['userId'] ?? '',
        'isLocked': data['isLocked'] ?? false,
        'lockedAt': data['lockedAt'],
        'isPublic': data['isPublic'] ?? false,
      };
    } catch (e) {
      return null;
    }
  }

  /// Validate and fix folder permissions
  static Future<bool> validateFolderAccess(String folderId, String userId) async {
    try {
      final folder = await _folderService.getFolder(folderId);
      if (folder == null) return false;

      return _canUserAccessFolder(folder, userId);
    } catch (e) {
      return false;
    }
  }

  /// Get user's accessible folders with error handling
  static Future<List<FolderModel>> getUserAccessibleFolders(
    String userId, {
    String? parentFolderId,
  }) async {
    try {
      if (userId.isEmpty) return [];

      Query query = _firestore.collection('folders');

      if (parentFolderId == null) {
        query = query.where('parentFolderId', isNull: true);
      } else {
        query = query.where('parentFolderId', isEqualTo: parentFolderId);
      }

      final snapshot = await query.get();
      final folders = <FolderModel>[];

      for (final doc in snapshot.docs) {
        try {
          final folder = FolderModel.fromDoc(doc);
          if (_canUserAccessFolder(folder, userId)) {
            folders.add(folder);
          }
        } catch (e) {
          // Skip folders that can't be parsed
          continue;
        }
      }

      folders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return folders;
    } catch (e) {
      return [];
    }
  }
}