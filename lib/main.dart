import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'services/profile_picture_service.dart';
import 'services/auth_state_manager.dart';
import 'services/fcm_service.dart';
import 'services/app_check_manager.dart';
import 'design_system/app_theme.dart';
import 'widgets/splash_screen.dart';
import 'pages/auth/login.dart';
import 'pages/home/home_page.dart';
import 'utils/error_handler.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set system UI overlay style for professional appearance
    AppTheme.setSystemUIOverlayStyle();
    
    // Configure Google Fonts license handling
    GoogleFonts.config.allowRuntimeFetching = true;
    
    // Initialize Firebase with error handling
    await ErrorHandler.retryOperation(
      () => Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      maxRetries: 3,
      initialDelay: const Duration(seconds: 2),
    );
    
    // Initialize App Check using AppCheckManager
    await AppCheckManager.initialize();
    
    // Log App Check status for development debugging
    debugPrint('App Check Status: ${AppCheckManager.status}');
    if (AppCheckManager.isDevelopment) {
      debugPrint('Development mode detected - Cloud functions will work without App Check');
      final configIssues = AppCheckManager.validateConfiguration();
      for (final issue in configIssues) {
        debugPrint('App Check Config: $issue');
      }
    }
    
    // Register FCM background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize FCM service with enhanced error handling
    try {
      await FCMService.instance.initialize();
    } catch (e) {
      // FCM initialization failure shouldn't prevent app startup
      ErrorHandler.logError('main.FCMService', e);
      
      // Log specific FCM initialization issues for debugging
      if (e.toString().contains('permission')) {
        debugPrint('FCM: Notification permissions not granted at startup');
      } else if (ErrorHandler.isNetworkError(e)) {
        debugPrint('FCM: Network error during initialization - will retry later');
      } else {
        debugPrint('FCM: Initialization failed: $e');
      }
    }
    
    runApp(const MyApp());
  } catch (e, stackTrace) {
    // Critical initialization error - log and show error app
    ErrorHandler.logError('main.initialization', e, stackTrace: stackTrace);
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _previousUserId;

  @override
  void initState() {
    super.initState();
    _listenToAuthStateChanges();
  }

  void _listenToAuthStateChanges() {
    FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        try {
          final currentUserId = user?.uid;
          
          // If user changed (including logout), clear cache for previous user
          if (_previousUserId != null && _previousUserId != currentUserId) {
            ProfilePictureService.clearCacheForUser(_previousUserId!);
          }
          
          // If user logged out completely, clear all cache
          if (currentUserId == null && _previousUserId != null) {
            ProfilePictureService.clearAllCache();
          }
          
          _previousUserId = currentUserId;
        } catch (e) {
          ErrorHandler.logError('MyApp._listenToAuthStateChanges', e);
        }
      },
      onError: (error) {
        ErrorHandler.logError('MyApp.authStateChanges.onError', error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Capsule',
      // Apply the comprehensive professional UI theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: AppTheme.getThemeMode(),
      // Use StreamBuilder-based routing instead of static initialRoute
      home: StreamBuilder<User?>(
        stream: AuthStateManager.authStateChanges,
        builder: (context, snapshot) {
          // Handle stream errors
          if (snapshot.hasError) {
            ErrorHandler.logError('MyApp.authStateStream', snapshot.error);
            return ErrorPage(
              error: 'Authentication error: ${snapshot.error}',
              onRetry: () {
                setState(() {}); // Rebuild to retry
              },
            );
          }
          
          // Show splash screen while waiting for auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }
          
          // Navigate based on authentication state
          if (snapshot.hasData && snapshot.data != null) {
            debugPrint('Main: User authenticated (${snapshot.data!.uid}), showing HomePage');
            // User is authenticated, refresh FCM token for existing user
            AuthStateManager.refreshFCMTokenForExistingUser().catchError((e) {
              // Don't fail app startup if FCM token refresh fails
              ErrorHandler.logError('MyApp.refreshFCMTokenForExistingUser', e);
            });
            
            // Send all authenticated users directly to HomePage
            // Profile setup can be handled within the app if needed
            return const HomePage();
          } else {
            debugPrint('Main: User not authenticated, showing LoginPage');
            // User is not authenticated, go to login page
            return const LoginPage();
          }
        },
      ),
      onGenerateRoute: generateRoute,
      // Ensure proper theme application and professional appearance
      debugShowCheckedModeBanner: false,
      // Configure builder to ensure theme is properly applied
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling respects system settings while maintaining design consistency
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Error app shown when critical initialization fails
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Capsule - Error',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'The app failed to start properly. Please restart the app or contact support if this continues.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Error: $error',
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Error page shown for recoverable errors
class ErrorPage extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  
  const ErrorPage({
    super.key,
    required this.error,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
