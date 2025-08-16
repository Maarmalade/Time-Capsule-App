import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/scheduled_message_service.dart';

/// Test utility to verify message delivery functionality
class MessageDeliveryTest {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final ScheduledMessageService _messageService = ScheduledMessageService();

  /// Test if Cloud Functions are working properly
  static Future<Map<String, dynamic>> testCloudFunctionDelivery() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to test delivery');
      }

      // Call the manual trigger function
      final callable = _functions.httpsCallable('triggerMessageDelivery');
      final result = await callable.call();
      
      return {
        'success': true,
        'data': result.data,
        'message': 'Cloud Function test completed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Cloud Function test failed',
      };
    }
  }

  /// Force refresh all pending messages for current user
  static Future<void> forceRefreshPendingMessages() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get all pending messages for the user
      final pendingMessages = await _messageService.getScheduledMessages(currentUser.uid);
      
      // Force status update
      await _messageService.forceStatusUpdate();
      
      // Refresh each message individually
      final messageIds = pendingMessages.map((m) => m.id).toList();
      await _messageService.refreshMultipleMessageStatuses(messageIds);
      
    } catch (e) {
      print('Error refreshing pending messages: $e');
    }
  }

  /// Test delivery of a specific message
  static Future<Map<String, dynamic>> testSpecificMessageDelivery(String messageId) async {
    try {
      final callable = _functions.httpsCallable('testMessageDelivery');
      final result = await callable.call({
        'messageId': messageId,
        'forceDelivery': true,
      });
      
      return {
        'success': true,
        'data': result.data,
        'message': 'Message delivery test completed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Message delivery test failed',
      };
    }
  }
}