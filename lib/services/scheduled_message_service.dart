import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scheduled_message_model.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

class ScheduledMessageService {
  final FirebaseFirestore _firestore;

  ScheduledMessageService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create scheduled message with future date validation
  Future<String> createScheduledMessage(ScheduledMessage message) async {
    try {
      // Validate message data
      if (message.senderId.isEmpty) {
        throw Exception('Sender ID is required');
      }

      if (message.recipientId.isEmpty) {
        throw Exception('Recipient ID is required');
      }

      if (message.textContent.isEmpty) {
        throw Exception('Message content is required');
      }

      // Validate future date
      if (!message.scheduledFor.isAfter(DateTime.now())) {
        throw Exception('Scheduled delivery date must be in the future');
      }

      // Validate scheduled date is not too far in the future (e.g., max 10 years)
      final maxFutureDate = DateTime.now().add(const Duration(days: 365 * 10));
      if (message.scheduledFor.isAfter(maxFutureDate)) {
        throw Exception('Scheduled delivery date cannot be more than 10 years in the future');
      }

      // Sanitize text content
      final sanitizedContent = ValidationUtils.sanitizeText(message.textContent);
      if (!ValidationUtils.isSafeForDisplay(sanitizedContent)) {
        throw Exception('Message content contains invalid characters');
      }

      // Validate text content length
      if (sanitizedContent.length > 5000) {
        throw Exception('Message content cannot exceed 5000 characters');
      }

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
      return ref.id;
    } on FirebaseException catch (e) {
      throw Exception(ErrorHandler.getErrorMessage(e));
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Failed to create scheduled message: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Get scheduled messages for a user (messages they sent)
  Future<List<ScheduledMessage>> getScheduledMessages(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      final snapshot = await _firestore
          .collection('scheduledMessages')
          .where('senderId', isEqualTo: userId)
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
      throw Exception('Failed to get scheduled messages: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Get received messages for a user (messages delivered to them)
  Future<List<ScheduledMessage>> getReceivedMessages(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      final snapshot = await _firestore
          .collection('scheduledMessages')
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
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
      throw Exception('Failed to get received messages: ${ErrorHandler.getErrorMessage(e)}');
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
      throw Exception('Failed to cancel scheduled message: ${ErrorHandler.getErrorMessage(e)}');
    }
  }

  // Stream scheduled messages for a user
  Stream<List<ScheduledMessage>> streamScheduledMessages(String userId) {
    return _firestore
        .collection('scheduledMessages')
        .where('senderId', isEqualTo: userId)
        .orderBy('scheduledFor', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduledMessage.fromFirestore(doc))
            .toList());
  }

  // Stream received messages for a user
  Stream<List<ScheduledMessage>> streamReceivedMessages(String userId) {
    return _firestore
        .collection('scheduledMessages')
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: 'delivered')
        .orderBy('deliveredAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduledMessage.fromFirestore(doc))
            .toList());
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
      throw Exception('Failed to get scheduled message: ${ErrorHandler.getErrorMessage(e)}');
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
      throw Exception('Failed to get pending messages for delivery: ${ErrorHandler.getErrorMessage(e)}');
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

      final updateData = <String, dynamic>{
        'status': status.name,
      };

      if (status == ScheduledMessageStatus.delivered) {
        updateData['deliveredAt'] = Timestamp.fromDate(deliveredAt ?? DateTime.now());
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
      throw Exception('Failed to update message status: ${ErrorHandler.getErrorMessage(e)}');
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
      throw Exception('Failed to get message counts: ${ErrorHandler.getErrorMessage(e)}');
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