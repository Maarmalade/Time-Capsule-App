import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/scheduled_message_model.dart';
import '../utils/social_validation_utils.dart';
import '../utils/social_error_handler.dart';
import '../utils/rate_limiter.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';
import 'storage_service.dart';

class ScheduledMessageService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final StorageService _storageService;

  ScheduledMessageService({
    FirebaseFirestore? firestore, 
    FirebaseAuth? auth,
    StorageService? storageService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storageService = storageService ?? StorageService();

  /// Uploads multiple media files for scheduled messages with retry mechanism
  Future<List<String>> uploadMessageMedia(List<File> mediaFiles) async {
    if (mediaFiles.isEmpty) {
      return [];
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User must be logged in to upload media');
    }

    final uploadedUrls = <String>[];
    final errors = <String>[];

    for (int i = 0; i < mediaFiles.length; i++) {
      final file = mediaFiles[i];
      
      try {
        // Validate file before upload
        final fileName = file.path.toLowerCase();
        final extension = fileName.substring(fileName.lastIndexOf('.'));
        
        String? validationError;
        if (ValidationUtils.allowedImageExtensions.contains(extension)) {
          validationError = ValidationUtils.validateFileUpload(file, expectedType: 'image');
        } else if (ValidationUtils.allowedVideoExtensions.contains(extension)) {
          validationError = ValidationUtils.validateFileUpload(file, expectedType: 'video');
        } else {
          validationError = 'Unsupported file type. Only images and videos are allowed.';
        }

        if (validationError != null) {
          errors.add('File ${i + 1}: $validationError');
          continue;
        }

        // Generate unique path for the media file
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final mediaPath = 'scheduled_messages/${currentUser.uid}/$timestamp-$i$extension';

        // Upload with retry mechanism
        String? uploadUrl;
        int retryCount = 0;
        const maxRetries = 3;

        while (retryCount < maxRetries && uploadUrl == null) {
          try {
            uploadUrl = await _storageService.uploadFile(file, mediaPath);
          } catch (e) {
            retryCount++;
            if (retryCount >= maxRetries) {
              errors.add('File ${i + 1}: Failed to upload after $maxRetries attempts - ${e.toString()}');
            } else {
              // Wait before retry with exponential backoff
              await Future.delayed(Duration(seconds: retryCount * 2));
            }
          }
        }

        if (uploadUrl != null) {
          uploadedUrls.add(uploadUrl);
        }
      } catch (e) {
        errors.add('File ${i + 1}: Unexpected error - ${e.toString()}');
      }
    }

    // If there were errors but some uploads succeeded, continue with partial success
    if (errors.isNotEmpty && uploadedUrls.isEmpty) {
      throw Exception('All media uploads failed: ${errors.join(', ')}');
    } else if (errors.isNotEmpty && uploadedUrls.isNotEmpty) {
      // Some uploads failed but others succeeded - this is handled by returning partial results
      // In production, you might want to log this to a proper logging service
    }

    return uploadedUrls;
  }

  /// Creates a scheduled message with media support
  Future<String> createScheduledMessageWithMedia(
    ScheduledMessage message,
    List<File>? images,
    File? video,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to create scheduled messages');
      }

      // Validate scheduled time with enhanced error messages
      final timeValidationError = getScheduledTimeValidationError(message.scheduledFor);
      if (timeValidationError != null) {
        throw Exception(timeValidationError);
      }

      // Prepare media files for upload
      final mediaFiles = <File>[];
      if (images != null && images.isNotEmpty) {
        mediaFiles.addAll(images);
      }
      if (video != null) {
        mediaFiles.add(video);
      }

      // Upload media files if any
      List<String> uploadedUrls = [];
      if (mediaFiles.isNotEmpty) {
        uploadedUrls = await uploadMessageMedia(mediaFiles);
      }

      // Separate image URLs and video URL
      List<String>? imageUrls;
      String? videoUrl;

      if (uploadedUrls.isNotEmpty) {
        imageUrls = <String>[];
        
        for (final url in uploadedUrls) {
          // Determine if URL is for image or video based on file extension in the URL
          if (url.contains('.mp4') || url.contains('.mov') || url.contains('.avi') || 
              url.contains('.mkv') || url.contains('.webm')) {
            videoUrl = url;
          } else {
            imageUrls.add(url);
          }
        }

        // If no images were found, set imageUrls to null
        if (imageUrls.isEmpty) {
          imageUrls = null;
        }
      }

      // Create message with uploaded media URLs
      final messageWithMedia = message.copyWith(
        imageUrls: imageUrls,
        videoUrl: videoUrl,
      );

      // Use existing createScheduledMessage method for the rest of the logic
      return await createScheduledMessage(messageWithMedia);
    } catch (e) {
      // Clean up uploaded media if message creation fails
      if (e.toString().contains('Failed to create scheduled message')) {
        // Note: In a production app, you might want to implement cleanup
        // of uploaded media files here, but it's complex due to async nature
      }
      rethrow;
    }
  }

  /// Validates scheduled time with improved logic (minimum 1 minute future)
  /// Returns true if the scheduled time is valid, false otherwise
  bool validateScheduledTime(DateTime scheduledTime) {
    final now = DateTime.now();
    final minimumFutureTime = now.add(const Duration(minutes: 1));
    return scheduledTime.isAfter(minimumFutureTime);
  }

  /// Gets a detailed error message for invalid scheduled times
  /// Returns null if the time is valid, error message string if invalid
  String? getScheduledTimeValidationError(DateTime scheduledTime) {
    final now = DateTime.now();
    final minimumFutureTime = now.add(const Duration(minutes: 1));
    
    if (scheduledTime.isBefore(now)) {
      return 'Cannot schedule messages in the past. Please select a future time.';
    }
    
    if (scheduledTime.isBefore(minimumFutureTime)) {
      final secondsUntilValid = minimumFutureTime.difference(now).inSeconds;
      return 'Message must be scheduled at least 1 minute in the future. Please wait $secondsUntilValid seconds or select a later time.';
    }
    
    // Check if scheduling too far in the future (10 years max)
    final maxFutureTime = now.add(const Duration(days: 365 * 10));
    if (scheduledTime.isAfter(maxFutureTime)) {
      return 'Cannot schedule messages more than 10 years in the future.';
    }
    
    return null; // Time is valid
  }

  // Create scheduled message with future date validation
  Future<String> createScheduledMessage(ScheduledMessage message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to create scheduled messages');
      }

      // Check rate limiting
      if (!SocialRateLimiters.canCreateScheduledMessage(currentUser.uid)) {
        final waitTime = SocialRateLimiters.getTimeUntilNextScheduledMessage(
          currentUser.uid,
        );
        throw Exception(
          'Too many scheduled messages. Please wait ${waitTime?.inMinutes ?? 60} minutes before creating another.',
        );
      }

      // Get current user message count for validation
      final userMessageCounts = await getMessageCounts(currentUser.uid);
      final userMessageCount = userMessageCounts['scheduled'] ?? 0;

      // Validate scheduled time with enhanced error messages
      final timeValidationError = getScheduledTimeValidationError(message.scheduledFor);
      if (timeValidationError != null) {
        throw Exception(timeValidationError);
      }

      // Validate scheduled message
      final validationResult = SocialValidationUtils.validateScheduledMessage(
        senderId: message.senderId,
        recipientId: message.recipientId,
        textContent: message.textContent,
        scheduledFor: message.scheduledFor,
        videoUrl: message.videoUrl,
        userMessageCount: userMessageCount,
      );

      if (validationResult.hasError) {
        throw Exception(validationResult.errorMessage);
      }

      final sanitizedContent = validationResult.data as String;

      // Create document reference
      final ref = _firestore.collection('scheduledMessages').doc();

      // Create message with sanitized content and generated ID
      final messageWithId = message.copyWith(
        id: ref.id,
        textContent: sanitizedContent,
        status: ScheduledMessageStatus.pending,
        createdAt: DateTime.now(),
      );

      // Validate the complete message
      if (!messageWithId.isValid()) {
        throw Exception('Invalid message data');
      }

      await ref.set(messageWithId.toFirestore());

      // Record the scheduled message for rate limiting
      SocialRateLimiters.recordScheduledMessage(currentUser.uid);

      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(SocialErrorHandler.getScheduledMessageErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to create scheduled message: ${SocialErrorHandler.getScheduledMessageErrorMessage(e)}',
      );
    }
  }

  // Get scheduled messages for a user (messages they sent)
  // Get scheduled messages for a user (messages they sent that are still pending)
  Future<List<ScheduledMessage>> getScheduledMessages(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      final snapshot = await _firestore
          .collection('scheduledMessages')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending') // Only pending messages
          .orderBy('scheduledFor', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledMessage.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get scheduled messages: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Get received messages for a user (messages delivered to them)
  Future<List<ScheduledMessage>> getReceivedMessages(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Get delivered messages
      final deliveredSnapshot = await _firestore
          .collection('scheduledMessages')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
          .get();

      // Get messages that are ready for delivery (pending and past scheduled time)
      final readyForDeliverySnapshot = await _firestore
          .collection('scheduledMessages')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where(
            'scheduledFor',
            isLessThanOrEqualTo: Timestamp.fromDate(DateTime.now()),
          )
          .orderBy('scheduledFor', descending: true)
          .get();

      final deliveredMessages = deliveredSnapshot.docs
          .map((doc) => ScheduledMessage.fromFirestore(doc))
          .toList();

      // For ready messages, treat them as delivered for display purposes
      // but maintain their actual status for backend processing
      final readyMessages = readyForDeliverySnapshot.docs
          .map((doc) => ScheduledMessage.fromFirestore(doc))
          .toList();

      // Combine and sort by delivery time
      final allMessages = [...deliveredMessages, ...readyMessages];
      allMessages.sort((a, b) {
        // Sort delivered messages by deliveredAt, ready messages by scheduledFor
        final aTime = a.isDelivered() ? (a.deliveredAt ?? a.scheduledFor) : a.scheduledFor;
        final bTime = b.isDelivered() ? (b.deliveredAt ?? b.scheduledFor) : b.scheduledFor;
        
        // Delivered messages come first, then by time descending
        if (a.isDelivered() && !b.isDelivered()) {
          return -1;
        } else if (!a.isDelivered() && b.isDelivered()) {
          return 1;
        } else {
          return bTime.compareTo(aTime);
        }
      });

      return allMessages;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get received messages: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Cancel scheduled message (only if pending)
  Future<void> cancelScheduledMessage(String messageId) async {
    try {
      if (messageId.isEmpty) {
        throw Exception('Message ID is required');
      }

      // Get current message data
      final messageDoc = await _firestore
          .collection('scheduledMessages')
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        throw Exception('Scheduled message not found');
      }

      final message = ScheduledMessage.fromFirestore(messageDoc);

      // Only allow cancellation of pending messages
      if (!message.isPending()) {
        throw Exception('Can only cancel pending messages');
      }

      // Delete the message document
      await _firestore.collection('scheduledMessages').doc(messageId).delete();
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to cancel scheduled message: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Stream scheduled messages for a user (only pending messages)
  Stream<List<ScheduledMessage>> streamScheduledMessages(String userId) {
    return _firestore
        .collection('scheduledMessages')
        .where('senderId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending') // Only pending messages
        .orderBy('scheduledFor', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduledMessage.fromFirestore(doc))
              .toList(),
        );
  }

  // Stream received messages for a user
  Stream<List<ScheduledMessage>> streamReceivedMessages(String userId) {
    return _firestore
        .collection('scheduledMessages')
        .where('recipientId', isEqualTo: userId)
        .where('status', whereIn: ['delivered', 'pending'])
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final messages = snapshot.docs
              .map((doc) => ScheduledMessage.fromFirestore(doc))
              .where((message) => 
                  message.isDelivered() || 
                  (message.isPending() && message.scheduledFor.isBefore(now))
              )
              .toList();
          
          // Sort messages: delivered first, then by time descending
          messages.sort((a, b) {
            final aTime = a.isDelivered() ? (a.deliveredAt ?? a.scheduledFor) : a.scheduledFor;
            final bTime = b.isDelivered() ? (b.deliveredAt ?? b.scheduledFor) : b.scheduledFor;
            
            if (a.isDelivered() && !b.isDelivered()) {
              return -1;
            } else if (!a.isDelivered() && b.isDelivered()) {
              return 1;
            } else {
              return bTime.compareTo(aTime);
            }
          });
          
          return messages;
        });
  }

  // Manual trigger for message delivery (for testing purposes)
  Future<Map<String, dynamic>> triggerMessageDelivery() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to trigger message delivery');
      }

      // Call the Firebase Function to trigger message delivery
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('triggerMessageDelivery');

      final result = await callable.call();
      return result.data as Map<String, dynamic>;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to trigger message delivery: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Get a specific scheduled message by ID
  Future<ScheduledMessage?> getScheduledMessage(String messageId) async {
    try {
      if (messageId.isEmpty) {
        return null;
      }

      final doc = await _firestore
          .collection('scheduledMessages')
          .doc(messageId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ScheduledMessage.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get scheduled message: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Get pending messages ready for delivery (used by Cloud Functions)
  Future<List<ScheduledMessage>> getPendingMessagesForDelivery() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('scheduledMessages')
          .where('status', isEqualTo: 'pending')
          .where('scheduledFor', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      return snapshot.docs
          .map((doc) => ScheduledMessage.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get pending messages for delivery: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Update message status (used by Cloud Functions)
  Future<void> updateMessageStatus(
    String messageId,
    ScheduledMessageStatus status, {
    DateTime? deliveredAt,
  }) async {
    try {
      if (messageId.isEmpty) {
        throw Exception('Message ID is required');
      }

      final updateData = <String, dynamic>{'status': status.name};

      if (status == ScheduledMessageStatus.delivered) {
        updateData['deliveredAt'] = Timestamp.fromDate(
          deliveredAt ?? DateTime.now(),
        );
      }

      await _firestore
          .collection('scheduledMessages')
          .doc(messageId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to update message status: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Get message count for a user (for UI display)
  Future<Map<String, int>> getMessageCounts(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      // Get scheduled messages count
      final scheduledSnapshot = await _firestore
          .collection('scheduledMessages')
          .where('senderId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      // Get received messages count
      final receivedSnapshot = await _firestore
          .collection('scheduledMessages')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .get();

      return {
        'scheduled': scheduledSnapshot.docs.length,
        'received': receivedSnapshot.docs.length,
      };
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to get message counts: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  // Check if user can access a message (sender or recipient)
  Future<bool> canUserAccessMessage(String messageId, String userId) async {
    try {
      final message = await getScheduledMessage(messageId);
      if (message == null) {
        return false;
      }

      return message.senderId == userId || message.recipientId == userId;
    } catch (e) {
      return false;
    }
  }

  /// Force refresh of message status from Firestore
  /// This method can be used to ensure UI shows the latest status
  Future<ScheduledMessage?> refreshMessageStatus(String messageId) async {
    try {
      if (messageId.isEmpty) {
        return null;
      }

      // Force a fresh read from Firestore (not from cache)
      final doc = await _firestore
          .collection('scheduledMessages')
          .doc(messageId)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) {
        return null;
      }

      return ScheduledMessage.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to refresh message status: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }

  /// Batch refresh multiple message statuses
  Future<List<ScheduledMessage>> refreshMultipleMessageStatuses(List<String> messageIds) async {
    try {
      if (messageIds.isEmpty) {
        return [];
      }

      final refreshedMessages = <ScheduledMessage>[];
      
      // Process in batches of 10 to avoid Firestore limits
      for (int i = 0; i < messageIds.length; i += 10) {
        final batch = messageIds.skip(i).take(10).toList();
        final futures = batch.map((id) => refreshMessageStatus(id));
        final results = await Future.wait(futures);
        
        refreshedMessages.addAll(results.whereType<ScheduledMessage>());
      }

      return refreshedMessages;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Failed to refresh multiple message statuses: ${ErrorHandler.getErrorMessage(e)}',
      );
    }
  }
}
