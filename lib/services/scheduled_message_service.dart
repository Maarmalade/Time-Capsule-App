import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/scheduled_message_model.dart';
import '../utils/social_validation_utils.dart';
import '../utils/social_error_handler.dart';
import '../utils/rate_limiter.dart';
import '../utils/error_handler.dart';

class ScheduledMessageService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ScheduledMessageService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

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

      // Get both delivered messages and messages ready for delivery
      final deliveredSnapshot = await _firestore
          .collection('scheduledMessages')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
          .get();

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

      final readyMessages = readyForDeliverySnapshot.docs
          .map((doc) => ScheduledMessage.fromFirestore(doc))
          .toList();

      // Combine and sort by delivery time (delivered messages first, then ready messages)
      final allMessages = [...deliveredMessages, ...readyMessages];
      allMessages.sort((a, b) {
        if (a.isDelivered() && b.isDelivered()) {
          return (b.deliveredAt ?? DateTime.now()).compareTo(
            a.deliveredAt ?? DateTime.now(),
          );
        } else if (a.isDelivered()) {
          return -1;
        } else if (b.isDelivered()) {
          return 1;
        } else {
          return b.scheduledFor.compareTo(a.scheduledFor);
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
        .orderBy('status')
        .orderBy('deliveredAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduledMessage.fromFirestore(doc))
              .toList(),
        );
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
}
