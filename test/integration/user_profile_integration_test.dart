import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_capsule/main.dart';
import 'package:time_capsule/services/user_profile_service.dart';
import 'package:time_capsule/models/user_profile.dart';

// Generate mocks
@GenerateMocks([
  FirebaseAuth,
  FirebaseFirestore,
  User,
  UserCredential,
])
import 'user_profile_integration_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User Profile Integration Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late UserProfileService userProfileService;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      userProfileService = UserProfileService();

      // Setup basic user mock
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('Complete user registration and profile setup flow', (WidgetTester tester) async {
      // Mock successful registration
      final mockUserCredential = MockUserCredential();
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // Mock username availability check
      when(mockFirestore.collection('users')).thenReturn(MockCollectionReference());
      // ... additional Firestore mocks would be needed

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: mockAuth),
            Provider<FirebaseFirestore>.value(value: mockFirestore),
            Provider<UserProfileService>.value(value: userProfileService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to registration
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Fill registration form
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'password123');

      // Submit registration
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should navigate to username setup
      expect(find.text('Create Username'), findsOneWidget);

      // Enter username
      await tester.enterText(find.byType(TextFormField), 'testuser');
      await tester.pumpAndSettle(); // Wait for availability check

      // Submit username
      await tester.tap(find.text('Create Username'));
      await tester.pumpAndSettle();

      // Should navigate to main app
      expect(find.text('Time Capsule'), findsOneWidget);
    });

    testWidgets('Complete profile management flow', (WidgetTester tester) async {
      // Setup existing user profile
      final testProfile = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Mock profile service calls
      when(userProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testProfile);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: mockAuth),
            Provider<UserProfileService>.value(value: userProfileService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to profile page
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Verify profile information is displayed
      expect(find.text('@testuser'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);

      // Test username change flow
      await tester.tap(find.text('Change Username'));
      await tester.pumpAndSettle();

      // Change username
      await tester.enterText(find.byType(TextFormField), 'newusername');
      await tester.pumpAndSettle(); // Wait for availability check

      when(userProfileService.updateUsername(any, 'newusername'))
          .thenAnswer((_) async {});

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Username updated successfully'), findsOneWidget);

      // Navigate back to profile
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // Test password change flow
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Enter password change form
      await tester.enterText(find.byType(TextFormField).at(0), 'currentpass');
      await tester.enterText(find.byType(TextFormField).at(1), 'newpassword');
      await tester.enterText(find.byType(TextFormField).at(2), 'newpassword');

      when(userProfileService.updatePassword('currentpass', 'newpassword'))
          .thenAnswer((_) async {});

      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Password changed successfully'), findsOneWidget);
    });

    testWidgets('Profile picture upload and management flow', (WidgetTester tester) async {
      // Setup existing user profile
      final testProfile = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(userProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testProfile);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: mockAuth),
            Provider<UserProfileService>.value(value: userProfileService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to profile page
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Tap on profile picture to change it
      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      // Should show image picker options
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);

      // Select gallery option
      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      // Note: In a real integration test, you would need to mock
      // the image picker and file system interactions
    });

    testWidgets('Error handling in profile operations', (WidgetTester tester) async {
      // Setup user profile service to throw errors
      when(userProfileService.getCurrentUserProfile())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: mockAuth),
            Provider<UserProfileService>.value(value: userProfileService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to profile page
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Network error'), findsOneWidget);

      // Should show retry button
      expect(find.text('Retry'), findsOneWidget);

      // Test retry functionality
      when(userProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => UserProfile(
            id: 'test-user-id',
            email: 'test@example.com',
            username: 'testuser',
            profilePictureUrl: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Should now show profile
      expect(find.text('@testuser'), findsOneWidget);
    });

    testWidgets('Username validation and availability checking', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: mockAuth),
            Provider<UserProfileService>.value(value: userProfileService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to username setup (assuming user just registered)
      // This would typically happen after registration
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<UserProfileService>.value(
            value: userProfileService,
            child: const UsernameSetupPage(),
          ),
        ),
      );

      // Test various username validation scenarios
      
      // Test too short username
      await tester.enterText(find.byType(TextFormField), 'ab');
      await tester.tap(find.text('Create Username'));
      await tester.pump();
      expect(find.text('Username must be at least 3 characters long'), findsOneWidget);

      // Test too long username
      await tester.enterText(find.byType(TextFormField), 'a' * 21);
      await tester.tap(find.text('Create Username'));
      await tester.pump();
      expect(find.text('Username must be no more than 20 characters long'), findsOneWidget);

      // Test invalid characters
      await tester.enterText(find.byType(TextFormField), 'user@name');
      await tester.tap(find.text('Create Username'));
      await tester.pump();
      expect(find.text('Username can only contain letters, numbers, and underscores'), findsOneWidget);

      // Test taken username
      when(userProfileService.isUsernameAvailable('takenuser'))
          .thenAnswer((_) async => false);

      await tester.enterText(find.byType(TextFormField), 'takenuser');
      await tester.pumpAndSettle();
      expect(find.text('Username taken'), findsOneWidget);

      // Test available username
      when(userProfileService.isUsernameAvailable('availableuser'))
          .thenAnswer((_) async => true);

      await tester.enterText(find.byType(TextFormField), 'availableuser');
      await tester.pumpAndSettle();
      expect(find.text('Username available'), findsOneWidget);
    });

    testWidgets('Logout flow from profile page', (WidgetTester tester) async {
      // Setup existing user profile
      final testProfile = UserProfile(
        id: 'test-user-id',
        email: 'test@example.com',
        username: 'testuser',
        profilePictureUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(userProfileService.getCurrentUserProfile())
          .thenAnswer((_) async => testProfile);
      when(mockAuth.signOut()).thenAnswer((_) async {
        return;
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<FirebaseAuth>.value(value: mockAuth),
            Provider<UserProfileService>.value(value: userProfileService),
          ],
          child: const MyApp(),
        ),
      );

      // Navigate to profile page
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Find and tap logout button
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Confirm Logout'), findsOneWidget);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);

      // Confirm logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Should navigate back to login page
      expect(find.text('Login'), findsOneWidget);
      verify(mockAuth.signOut()).called(1);
    });
  });
}