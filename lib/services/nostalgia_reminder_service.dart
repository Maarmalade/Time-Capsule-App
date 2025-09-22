import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diary_entry_model.dart';
import '../utils/error_handler.dart';

class NostalgiaReminderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get favorite entries for today from previous years with comprehensive error handling
  static Stream<List<DiaryEntryModel>> getFavoriteEntriesForToday(String folderId) {
    try {
      // Validate input parameters
      if (folderId.isEmpty) {
        ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForToday', 
            'Invalid folderId: empty string provided');
        return Stream.value([]);
      }

      final user = _auth.currentUser;
      if (user == null) {
        ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForToday', 
            'User not authenticated');
        return Stream.value([]);
      }

      return _createSafeStream(folderId);
    } catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForToday', e, 
          stackTrace: stackTrace);
      return Stream.value([]);
    }
  }

  /// Check if user has any favorite entries with comprehensive error handling
  static Future<bool> hasFavoriteEntries(String folderId) async {
    try {
      // Validate input parameters
      if (folderId.isEmpty) {
        ErrorHandler.logError('NostalgiaReminderService.hasFavoriteEntries', 
            'Invalid folderId: empty string provided');
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) {
        ErrorHandler.logError('NostalgiaReminderService.hasFavoriteEntries', 
            'User not authenticated');
        return false;
      }

      // Use retry logic for network operations
      final snapshot = await ErrorHandler.retryOperation(
        () => _firestore
            .collection('diary_entries')
            .where('folderId', isEqualTo: folderId)
            .where('isFavorite', isEqualTo: true)
            .limit(1)
            .get(),
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: (error) {
          // Retry on network errors but not on permission errors
          return ErrorHandler.isNetworkError(error) && !ErrorHandler.isAuthError(error);
        },
      );

      // Validate snapshot
      if (snapshot.docs.isEmpty) {
        return false;
      }

      // Additional validation - check if documents actually contain valid data
      for (final doc in snapshot.docs) {
        try {
          if (doc.exists) {
            final data = doc.data();
            // Verify the document has required fields
            if (data.containsKey('isFavorite') && data['isFavorite'] == true) {
              return true;
            }
          }
        } catch (e) {
          ErrorHandler.logError('NostalgiaReminderService.validateDocument', e);
          // Continue checking other documents
          continue;
        }
      }

      return false;
    } on FirebaseException catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.hasFavoriteEntries.firebase', e, 
          stackTrace: stackTrace);
      
      // Handle specific Firebase errors
      if (e.code == 'permission-denied') {
        ErrorHandler.logError('NostalgiaReminderService.hasFavoriteEntries', 
            'Permission denied - user may not have access to folder $folderId');
      } else if (e.code == 'unavailable') {
        ErrorHandler.logError('NostalgiaReminderService.hasFavoriteEntries', 
            'Firestore service temporarily unavailable');
      }
      
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.hasFavoriteEntries', e, 
          stackTrace: stackTrace);
      return false;
    }
  }

  /// Get favorite entries count for analytics with error handling
  static Future<int> getFavoriteEntriesCount(String folderId) async {
    try {
      // Validate input parameters
      if (folderId.isEmpty) {
        ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesCount', 
            'Invalid folderId: empty string provided');
        return 0;
      }

      final user = _auth.currentUser;
      if (user == null) {
        ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesCount', 
            'User not authenticated');
        return 0;
      }

      // Use retry logic for network operations
      final snapshot = await ErrorHandler.retryOperation(
        () => _firestore
            .collection('diary_entries')
            .where('folderId', isEqualTo: folderId)
            .where('isFavorite', isEqualTo: true)
            .get(),
        maxRetries: 2,
        shouldRetry: (error) => ErrorHandler.isNetworkError(error),
      );

      return snapshot.docs.length;
    } on FirebaseException catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesCount.firebase', e, 
          stackTrace: stackTrace);
      return 0;
    } catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesCount', e, 
          stackTrace: stackTrace);
      return 0;
    }
  }

  /// Get favorite entries for a specific date range with error handling
  static Future<List<DiaryEntryModel>> getFavoriteEntriesForDateRange(
    String folderId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Validate input parameters
      if (folderId.isEmpty) {
        ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForDateRange', 
            'Invalid folderId: empty string provided');
        return [];
      }

      if (startDate.isAfter(endDate)) {
        ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForDateRange', 
            'Invalid date range: startDate is after endDate');
        return [];
      }

      final user = _auth.currentUser;
      if (user == null) {
        ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForDateRange', 
            'User not authenticated');
        return [];
      }

      // Convert dates to Firestore timestamps
      final startTimestamp = Timestamp.fromDate(startDate);
      final endTimestamp = Timestamp.fromDate(endDate);

      // Use retry logic for network operations
      final snapshot = await ErrorHandler.retryOperation(
        () => _firestore
            .collection('diary_entries')
            .where('folderId', isEqualTo: folderId)
            .where('isFavorite', isEqualTo: true)
            .where('diaryDate', isGreaterThanOrEqualTo: startTimestamp)
            .where('diaryDate', isLessThanOrEqualTo: endTimestamp)
            .orderBy('diaryDate', descending: true)
            .get(),
        maxRetries: 3,
        shouldRetry: (error) => ErrorHandler.isNetworkError(error),
      );

      final entries = <DiaryEntryModel>[];
      
      // Process each document with individual error handling
      for (final doc in snapshot.docs) {
        try {
          if (doc.exists) {
            final entry = DiaryEntryModel.fromDoc(doc);
            entries.add(entry);
          }
        } catch (e) {
          ErrorHandler.logError('NostalgiaReminderService.processDateRangeDocument', e);
          // Continue processing other documents
          continue;
        }
      }

      return entries;
    } on FirebaseException catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForDateRange.firebase', e, 
          stackTrace: stackTrace);
      return [];
    } catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.getFavoriteEntriesForDateRange', e, 
          stackTrace: stackTrace);
      return [];
    }
  }

  /// Validate folder access with comprehensive error handling
  static Future<bool> validateFolderAccess(String folderId) async {
    try {
      // Validate input parameters
      if (folderId.isEmpty) {
        ErrorHandler.logError('NostalgiaReminderService.validateFolderAccess', 
            'Invalid folderId: empty string provided');
        return false;
      }

      final user = _auth.currentUser;
      if (user == null) {
        ErrorHandler.logError('NostalgiaReminderService.validateFolderAccess', 
            'User not authenticated');
        return false;
      }

      // Try to access the folder to validate permissions
      final folderSnapshot = await ErrorHandler.retryOperation(
        () => _firestore
            .collection('folders')
            .doc(folderId)
            .get(),
        maxRetries: 2,
        shouldRetry: (error) => ErrorHandler.isNetworkError(error),
      );

      if (!folderSnapshot.exists) {
        ErrorHandler.logError('NostalgiaReminderService.validateFolderAccess', 
            'Folder $folderId does not exist');
        return false;
      }

      // Additional validation - check if user has access to this folder
      final folderData = folderSnapshot.data();
      if (folderData == null) {
        ErrorHandler.logError('NostalgiaReminderService.validateFolderAccess', 
            'Folder $folderId has no data');
        return false;
      }

      // Check if user is owner or has access (basic validation)
      final ownerId = folderData['ownerId'] as String?;
      if (ownerId == user.uid) {
        return true;
      }

      // Check shared access (if applicable)
      final sharedWith = folderData['sharedWith'] as List<dynamic>?;
      if (sharedWith?.contains(user.uid) == true) {
        return true;
      }

      ErrorHandler.logError('NostalgiaReminderService.validateFolderAccess', 
          'User ${user.uid} does not have access to folder $folderId');
      return false;
    } on FirebaseException catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.validateFolderAccess.firebase', e, 
          stackTrace: stackTrace);
      
      // Handle specific permission errors
      if (e.code == 'permission-denied') {
        return false; // User definitely doesn't have access
      }
      
      // For other errors, assume no access for security
      return false;
    } catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.validateFolderAccess', e, 
          stackTrace: stackTrace);
      return false;
    }
  }

  /// Get throwback message for empty state
  static String getThrowbackMessage() {
    return 'There are no favourited diary entries from past years. '
           'Favourite a diary entry now so you can see it in the following years!';
  }

  /// Get contextual error message for nostalgia reminder failures
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Unable to access your diary entries. Please check your permissions and try again.';
        case 'unavailable':
          return 'The diary service is temporarily unavailable. Please try again later.';
        case 'deadline-exceeded':
          return 'Request timed out while loading your memories. Please check your connection and try again.';
        case 'not-found':
          return 'Your diary folder was not found. Please refresh the page and try again.';
        default:
          return 'Unable to load your favorite memories. Please try again later.';
      }
    }
    
    if (ErrorHandler.isNetworkError(error)) {
      return 'Network connection issue. Please check your internet and try again.';
    }
    
    return 'Unable to load your favorite memories. Please try again later.';
  }

  /// Validate diary entry data integrity
  static bool _validateDiaryEntryData(Map<String, dynamic> data) {
    try {
      // Check required fields
      final requiredFields = ['folderId', 'title', 'content', 'createdAt', 'diaryDate'];
      for (final field in requiredFields) {
        if (!data.containsKey(field)) {
          ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', 
              'Missing required field: $field');
          return false;
        }
      }

      // Validate data types
      if (data['folderId'] is! String || (data['folderId'] as String).isEmpty) {
        ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', 
            'Invalid folderId type or empty');
        return false;
      }

      if (data['title'] is! String) {
        ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', 
            'Invalid title type');
        return false;
      }

      if (data['content'] is! String) {
        ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', 
            'Invalid content type');
        return false;
      }

      // Validate timestamps
      if (data['createdAt'] is! Timestamp) {
        ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', 
            'Invalid createdAt type');
        return false;
      }

      if (data['diaryDate'] is! Timestamp) {
        ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', 
            'Invalid diaryDate type');
        return false;
      }

      // Validate favorite flag if present
      if (data.containsKey('isFavorite') && data['isFavorite'] is! bool) {
        ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', 
            'Invalid isFavorite type');
        return false;
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('NostalgiaReminderService._validateDiaryEntryData', e);
      return false;
    }
  }

  /// Create a safe stream that handles all possible errors
  static Stream<List<DiaryEntryModel>> _createSafeStream(String folderId) {
    return _firestore
        .collection('diary_entries')
        .where('folderId', isEqualTo: folderId)
        .where('isFavorite', isEqualTo: true)
        .snapshots()
        .timeout(const Duration(seconds: 30))
        .handleError((error, stackTrace) {
          ErrorHandler.logError('NostalgiaReminderService._createSafeStream', error, 
              stackTrace: stackTrace);
          return <DiaryEntryModel>[];
        })
        .map((snapshot) {
          try {
            return _processSnapshot(snapshot);
          } catch (e, stackTrace) {
            ErrorHandler.logError('NostalgiaReminderService._processSnapshot', e, 
                stackTrace: stackTrace);
            return <DiaryEntryModel>[];
          }
        });
  }

  /// Process Firestore snapshot with comprehensive error handling
  static List<DiaryEntryModel> _processSnapshot(QuerySnapshot snapshot) {
    try {
      // Validate snapshot
      if (snapshot.docs.isEmpty) {
        return <DiaryEntryModel>[];
      }

      final now = DateTime.now();
      final todayMonth = now.month;
      final todayDay = now.day;
      final currentYear = now.year;
      final entries = <DiaryEntryModel>[];
      
      // Process each document with individual error handling
      for (final doc in snapshot.docs) {
        try {
          // Validate document data exists
          if (!doc.exists) {
            ErrorHandler.logError('NostalgiaReminderService._processSnapshot', 
                'Document ${doc.id} does not exist');
            continue;
          }

          // Additional validation for document data
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null || data.isEmpty) {
            ErrorHandler.logError('NostalgiaReminderService._processSnapshot', 
                'Document ${doc.id} has no data');
            continue;
          }

          // Validate data integrity
          if (!_validateDiaryEntryData(data)) {
            continue; // Skip invalid entries
          }

          // Verify this is actually a favorite entry
          if (data['isFavorite'] != true) {
            continue; // Skip non-favorite entries
          }

          final entry = DiaryEntryModel.fromDoc(doc);
          
          // Additional null safety check for diaryDate
          final diaryDate = entry.diaryDate;
          final entryDate = diaryDate.toDate();
          
          // Filter entries for today's date from previous years
          if (entryDate.month == todayMonth &&
              entryDate.day == todayDay &&
              entryDate.year < currentYear) {
            entries.add(entry);
          }
        } catch (e, stackTrace) {
          ErrorHandler.logError('NostalgiaReminderService._processSnapshot', e, 
              stackTrace: stackTrace);
          // Continue processing other documents even if one fails
          continue;
        }
      }

      // Sort by year (most recent first) with error handling
      try {
        entries.sort((a, b) {
          try {
            return b.diaryDate.compareTo(a.diaryDate);
          } catch (e) {
            ErrorHandler.logError('NostalgiaReminderService._processSnapshot.sort', e);
            return 0; // Keep original order if comparison fails
          }
        });
      } catch (e) {
        ErrorHandler.logError('NostalgiaReminderService._processSnapshot.sort', e);
        // Return unsorted entries if sorting fails
      }

      return entries;
    } catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService._processSnapshot', e, 
          stackTrace: stackTrace);
      return <DiaryEntryModel>[];
    }
  }

  /// Health check for the nostalgia reminder service
  static Future<Map<String, dynamic>> performHealthCheck() async {
    final healthStatus = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'service': 'NostalgiaReminderService',
      'status': 'unknown',
      'checks': <String, dynamic>{},
    };

    try {
      // Check authentication
      final user = _auth.currentUser;
      healthStatus['checks']['authentication'] = {
        'status': user != null ? 'pass' : 'fail',
        'message': user != null ? 'User authenticated' : 'No authenticated user',
      };

      if (user == null) {
        healthStatus['status'] = 'fail';
        return healthStatus;
      }

      // Check Firestore connectivity
      try {
        await _firestore.enableNetwork();
        healthStatus['checks']['firestore_connectivity'] = {
          'status': 'pass',
          'message': 'Firestore connection active',
        };
      } catch (e) {
        healthStatus['checks']['firestore_connectivity'] = {
          'status': 'fail',
          'message': 'Firestore connection failed: $e',
        };
        healthStatus['status'] = 'degraded';
      }

      // Test basic query capability
      try {
        await _firestore
            .collection('diary_entries')
            .limit(1)
            .get();
        healthStatus['checks']['query_capability'] = {
          'status': 'pass',
          'message': 'Basic queries working',
        };
      } catch (e) {
        healthStatus['checks']['query_capability'] = {
          'status': 'fail',
          'message': 'Query capability failed: $e',
        };
        healthStatus['status'] = 'fail';
      }

      // Set overall status if not already failed
      if (healthStatus['status'] == 'unknown') {
        healthStatus['status'] = 'pass';
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError('NostalgiaReminderService.performHealthCheck', e, 
          stackTrace: stackTrace);
      healthStatus['status'] = 'fail';
      healthStatus['error'] = e.toString();
    }

    return healthStatus;
  }
}