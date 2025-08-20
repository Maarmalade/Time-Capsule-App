import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'constants/route_constants.dart';
import 'services/profile_picture_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: Routes.login,
      onGenerateRoute: generateRoute,
    );
  }
}
