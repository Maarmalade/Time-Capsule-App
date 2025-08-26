import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'constants/route_constants.dart';
import 'services/profile_picture_service.dart';
import 'design_system/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for professional appearance
  AppTheme.setSystemUIOverlayStyle();
  
  // Configure Google Fonts license handling
  GoogleFonts.config.allowRuntimeFetching = true;
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase App Check
  await FirebaseAppCheck.instance.activate(
    // Use debug provider for development
    androidProvider: AndroidProvider.debug,
  );
  
  runApp(const MyApp());
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
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Capsule',
      // Apply the comprehensive professional UI theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: AppTheme.getThemeMode(),
      initialRoute: Routes.login,
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
