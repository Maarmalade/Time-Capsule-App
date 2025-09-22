import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/fcm_token_model.dart';
import '../models/notification_payload_model.dart';
import '../utils/error_handler.dart';

/// Service for handling Firebase Cloud Messaging (FCM) operations
/// Manages token retrieval, notification handling, and backend integration
class FCMService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;
  
  // Placeholder backend URL for token submission
  static const String _backendTokenUrl = 'https://api.timecapsule.app/fcm/token';
  
  static FCMService? _instance;
  
  /// Constructor for dependency injection (mainly for testing)
  FCMService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _httpClient = httpClient ?? http.Client();
  
  /// Singleton instance
  static FCMService get instance {
    _instance ??= FCMService();
    return _instance!;
  }
  
  /// Set instance for testing
  static void setInstance(FCMService instance) {
    _instance = instance;
  }
  
  /// Initialize FCM service and request permissions with comprehensive error handling
  Future<void> initialize() async {
    try {
      // Request notification permissions with enhanced retry logic
      final settings = await ErrorHandler.retryFCMOperation(
        () => _messaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        ),
      );
      
      // Handle different permission states
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          debugPrint('FCM: User granted full permission');
          break;
        case AuthorizationStatus.provisional:
          debugPrint('FCM: User granted provisional permission');
          break;
        case AuthorizationStatus.denied:
          debugPrint('FCM: User denied permission');
          throw FCMException(
            code: 'permission-denied',
            message: 'Notification permissions are required for push notifications',
          );
        case AuthorizationStatus.notDetermined:
          debugPrint('FCM: Permission not determined');
          throw FCMException(
            code: 'permission-not-determined',
            message: 'Notification permissions need to be requested',
          );
      }
      
      // Initialize local notifications with error handling
      await ErrorHandler.retryOperation(
        () => _initializeLocalNotifications(),
        maxRetries: 2,
        initialDelay: const Duration(seconds: 1),
      );
      
      // Set up message handlers
      _setupMessageHandlers();
      
      // Get and store initial token with enhanced retry logic
      await ErrorHandler.retryFCMOperation(
        () => _handleTokenRefresh(),
      );
      
      // Listen for token refresh with error handling
      _messaging.onTokenRefresh.listen(
        _onTokenRefreshWithErrorHandling,
        onError: (error) {
          ErrorHandler.logError('FCMService.onTokenRefresh.error', error);
        },
      );
      
    } on FCMException {
      rethrow; // Re-throw FCM-specific exceptions
    } catch (e) {
      ErrorHandler.logError('FCMService.initialize', e);
      throw FCMException(
        code: 'fcm-initialization-failed',
        message: 'Failed to initialize FCM service: $e',
      );
    }
  }
  
  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }
  
  /// Set up message handlers for different app states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle messages when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Handle messages when app is terminated
    _handleInitialMessage();
  }
  
  /// Get FCM token for current device with enhanced error handling
  Future<String?> getToken() async {
    try {
      final token = await ErrorHandler.retryFCMOperation(
        () async {
          final result = await _messaging.getToken();
          if (result == null) {
            throw FCMException(
              code: 'token-not-available',
              message: 'FCM token is not available - may be due to network issues or device restrictions',
            );
          }
          return result;
        },
      );
      
      final tokenPreview = token.length > 20 ? '${token.substring(0, 20)}...' : token;
      debugPrint('FCM: Retrieved token: $tokenPreview');
      return token;
    } on FCMException {
      rethrow; // Re-throw FCM exceptions with original error codes
    } catch (e) {
      ErrorHandler.logError('FCMService.getToken', e);
      throw FCMException(
        code: 'fcm-token-retrieval-failed',
        message: 'Failed to retrieve FCM token: $e',
      );
    }
  }
  
  /// Send FCM token to backend API with enhanced error handling
  Future<void> sendTokenToBackend(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FCMException(
          code: 'unauthenticated',
          message: 'User not authenticated',
        );
      }
      
      await ErrorHandler.retryFCMOperation(
        () async {
          final idToken = await user.getIdToken();
          final response = await _httpClient.post(
            Uri.parse(_backendTokenUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode({
              'token': token,
              'userId': user.uid,
              'platform': _getPlatform(),
              'timestamp': DateTime.now().toIso8601String(),
            }),
          );
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            debugPrint('FCM: Token sent to backend successfully');
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            // Authentication error - don't retry
            throw FCMException(
              code: 'authentication-error',
              message: 'Authentication failed when sending token to backend: ${response.statusCode}',
            );
          } else if (response.statusCode >= 400 && response.statusCode < 500) {
            // Client error - don't retry
            throw FCMException(
              code: 'client-error',
              message: 'Client error sending token to backend: ${response.statusCode}',
            );
          } else {
            // Server error - can retry
            throw FCMException(
              code: 'server-error',
              message: 'Server error sending token to backend: ${response.statusCode}',
            );
          }
        },
      );
    } on FCMException catch (e) {
      ErrorHandler.logError('FCMService.sendTokenToBackend', e);
      // Don't rethrow - backend token submission is not critical for app functionality
      // The token is still stored in Firestore for the app to function
    } catch (e) {
      ErrorHandler.logError('FCMService.sendTokenToBackend', e);
      // Don't rethrow - this is not critical for app functionality
    }
  }
  
  /// Store FCM token in Firestore with enhanced error handling
  Future<void> storeTokenInFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FCMException(
          code: 'unauthenticated',
          message: 'User not authenticated',
        );
      }
      
      final fcmToken = FCMTokenModel(
        userId: user.uid,
        token: token,
        lastUpdated: DateTime.now(),
        platform: _getPlatform(),
      );
      
      // Store in both fcm_tokens collection and user profile
      await ErrorHandler.retryFCMOperation(
        () async {
          // Store in fcm_tokens collection for detailed tracking
          // Use just the user ID as document ID to match Firestore rules
          await _firestore
              .collection('fcm_tokens')
              .doc(user.uid)
              .set(fcmToken.toJson());
          
          // Also store in user profile for easy access by cloud functions
          await _firestore
              .collection('users')
              .doc(user.uid)
              .update({
                'fcmToken': token,
                'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
                'platform': _getPlatform(),
              });
        },
      );
      
      debugPrint('FCM: Token stored in Firestore and user profile');
    } on FirebaseException catch (e) {
      ErrorHandler.logError('FCMService.storeTokenInFirestore', e);
      
      // Handle specific Firestore errors
      if (e.code == 'permission-denied' || e.code == 'unauthenticated') {
        throw FCMException(
          code: 'authentication-error',
          message: 'Authentication required to store FCM token',
        );
      } else if (ErrorHandler.isNetworkError(e)) {
        throw FCMException(
          code: 'network-error',
          message: 'Network error while storing FCM token',
        );
      } else {
        throw FCMException(
          code: 'firestore-error',
          message: ErrorHandler.getFirestoreErrorMessage(e),
        );
      }
    } catch (e) {
      ErrorHandler.logError('FCMService.storeTokenInFirestore', e);
      if (e is FCMException) {
        rethrow;
      }
      throw FCMException(
        code: 'storage-failed',
        message: 'Failed to store FCM token: $e',
      );
    }
  }

  /// Retrieve FCM token for current user and platform from Firestore
  Future<FCMTokenModel?> getStoredToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final doc = await _firestore
          .collection('fcm_tokens')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return FCMTokenModel.fromJson(doc.data()!);
      }
      
      return null;
    } catch (e) {
      debugPrint('FCM: Error retrieving stored token: $e');
      return null;
    }
  }

  /// Retrieve all FCM tokens for a specific user
  Future<List<FCMTokenModel>> getUserTokens(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('fcm_tokens')
          .where('userId', isEqualTo: userId)
          .get();
      
      return querySnapshot.docs
          .map((doc) => FCMTokenModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('FCM: Error retrieving user tokens: $e');
      return [];
    }
  }

  /// Retrieve all FCM tokens for current authenticated user
  Future<List<FCMTokenModel>> getCurrentUserTokens() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    
    return getUserTokens(user.uid);
  }

  /// Check if current user has a valid token for current platform
  Future<bool> hasValidToken() async {
    try {
      final storedToken = await getStoredToken();
      if (storedToken == null) return false;
      
      final currentToken = await getToken();
      return storedToken.token == currentToken;
    } catch (e) {
      debugPrint('FCM: Error checking token validity: $e');
      return false;
    }
  }
  
  /// Handle token refresh
  Future<void> _handleTokenRefresh() async {
    try {
      final token = await getToken();
      if (token != null) {
        await storeTokenInFirestore(token);
        await sendTokenToBackend(token);
      }
    } catch (e) {
      ErrorHandler.logError('FCMService._handleTokenRefresh', e);
      // Don't rethrow - this is called during initialization
    }
  }
  

  
  /// Handle token refresh events with comprehensive error handling
  void _onTokenRefreshWithErrorHandling(String token) {
    ErrorHandler.retryFCMOperation(
      () async {
        await storeTokenInFirestore(token);
        await sendTokenToBackend(token);
      },
    ).catchError((e) {
      ErrorHandler.logError('FCMService._onTokenRefreshWithErrorHandling', e);
      
      // For token refresh failures, we don't want to show user errors
      // as this happens in the background, but we should log for debugging
      if (e is FCMException) {
        debugPrint('FCM: Token refresh failed: ${e.code} - ${e.message}');
      } else {
        debugPrint('FCM: Token refresh failed with unexpected error: $e');
      }
    });
  }
  
  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM: Received foreground message: ${message.messageId}');
    showLocalNotification(message);
  }
  
  /// Handle messages when app is opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM: App opened from background message: ${message.messageId}');
    _navigateToContent(message);
  }
  
  /// Handle initial message when app is opened from terminated state
  void _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM: App opened from terminated state: ${initialMessage.messageId}');
      _navigateToContent(initialMessage);
    }
  }
  
  /// Show local notification for received message
  Future<void> showLocalNotification(RemoteMessage message) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'time_capsule_channel',
        'Time Capsule Notifications',
        channelDescription: 'Notifications for Time Capsule app',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final payload = NotificationPayload.fromRemoteMessage(message);
      
      await ErrorHandler.retryOperation(
        () => _localNotifications.show(
          message.hashCode,
          message.notification?.title ?? 'Time Capsule',
          message.notification?.body ?? 'You have a new message',
          notificationDetails,
          payload: jsonEncode(payload.toJson()),
        ),
        maxRetries: 2,
        initialDelay: const Duration(milliseconds: 500),
      );
      
      debugPrint('FCM: Local notification shown');
    } catch (e) {
      ErrorHandler.logError('FCMService.showLocalNotification', e);
      // Don't rethrow - notification display failure shouldn't crash the app
    }
  }
  
  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('FCM: Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final payloadData = jsonDecode(response.payload!);
        final payload = NotificationPayload.fromJson(payloadData);
        _handleNotificationNavigation(payload);
      } catch (e) {
        debugPrint('FCM: Error parsing notification payload: $e');
      }
    }
  }
  
  /// Navigate to content based on message data
  void _navigateToContent(RemoteMessage message) {
    final payload = NotificationPayload.fromRemoteMessage(message);
    _handleNotificationNavigation(payload);
  }
  
  /// Handle navigation based on notification payload
  void _handleNotificationNavigation(NotificationPayload payload) {
    // TODO: Implement navigation logic based on payload type
    // This will be implemented when navigation is set up
    debugPrint('FCM: Navigation to ${payload.type} with ID: ${payload.targetId}');
  }
  
  /// Clear FCM token on logout
  Future<void> clearToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete token from Firestore for current platform
        await _firestore
            .collection('fcm_tokens')
            .doc(user.uid)
            .delete();
        
        debugPrint('FCM: Token cleared from Firestore');
      }
      
      // Delete token from FCM
      await _messaging.deleteToken();
      debugPrint('FCM: Token deleted from FCM');
    } catch (e) {
      debugPrint('FCM: Error clearing token: $e');
    }
  }

  /// Clear all FCM tokens for current user (useful for complete logout)
  Future<void> clearAllUserTokens() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Get all tokens for the user
      final userTokens = await getCurrentUserTokens();
      
      // Delete each token document
      final batch = _firestore.batch();
      for (final token in userTokens) {
        final docRef = _firestore
            .collection('fcm_tokens')
            .doc(token.userId);
        batch.delete(docRef);
      }
      
      // Commit the batch delete
      await batch.commit();
      
      // Delete current device token from FCM
      await _messaging.deleteToken();
      
      debugPrint('FCM: All user tokens cleared');
    } catch (e) {
      debugPrint('FCM: Error clearing all user tokens: $e');
    }
  }
  
  /// Get current platform string
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Handling background message: ${message.messageId}');
  
  // Initialize Firebase if not already done
  // await Firebase.initializeApp();
  
  // Handle background message processing here
  // For now, just log the message
}

/// Custom exception class for FCM-related errors
class FCMException implements Exception {
  final String code;
  final String message;
  
  const FCMException({
    required this.code,
    required this.message,
  });
  
  @override
  String toString() => 'FCMException($code): $message';
}