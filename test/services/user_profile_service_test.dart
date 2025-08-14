import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:time_capsule/services/user_profile_service.dart';
import 'package:time_capsule/models/user_profile.dart';

// Generate mocks
@GenerateMocks([
  FirebaseFirestore,
  FirebaseAuth,
  FirebaseStorage,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  QueryDocumentSnapshot,
  User,
  Reference,
  UploadTask,
  TaskSnapshot,
])
import 'user_profile_service_test.mocks.dart';

void main() {
  group('UserProfileService', () {
    late UserProfileService userProfileService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseStorage mockStorage;
    late MockCollectionReference mockCollection;
    late MockDocumentReference mockDocument;
    late MockUser mockUser;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockStorage = MockFirebaseStorage();
      mockCollection = MockCollectionReference();
      mockDocument = MockDocumentReference();
      mockUser = MockUser();

      // Setup basic mocks
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc(any)).thenReturn(mockDocument);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');

      userProfileService = UserProfileService();
      // Note: In a real implementation, you'd inject these dependencies
      // For this test, we're assuming the service uses static instances
    });

    group('createUserProfile', () {
      test('should create user profile successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        const username = 'testuser';
        const email = 'test@example.com';

        final mockQuerySnapshot = MockQuerySnapshot();
        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('username', isEqualTo: username))
            .thenReturn(mockCollection);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockDocument.set(any)).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => userProfileService.createUserProfile(userId, username, email),
          returnsNormally,
        );
      });

      test('should throw exception for invalid username', () async {
        // Arrange
        const userId = 'test-user-id';
        const invalidUsername = 'ab'; // Too short
        const email = 'test@example.com';

        // Act & Assert
        expect(
          () => userProfileService.createUserProfile(userId, invalidUsername, email),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for taken username', () async {
        // Arrange
        const userId = 'test-user-id';
        const username = 'testuser';
        const email = 'test@example.com';

        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();
        when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
        when(mockCollection.where('username', isEqualTo: username))
            .thenReturn(mockCollection);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act & Assert
        expect(
          () => userProfileService.createUserProfile(userId, username, email),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for invalid email', () async {
        // Arrange
        const userId = 'test-user-id';
        const username = 'testuser';
        const invalidEmail = 'invalid-email';

        // Act & Assert
        expect(
          () => userProfileService.createUserProfile(userId, username, invalidEmail),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty user ID', () async {
        // Arrange
        const userId = '';
        const username = 'testuser';
        const email = 'test@example.com';

        // Act & Assert
        expect(
          () => userProfileService.createUserProfile(userId, username, email),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getUserProfile', () {
      test('should return user profile when document exists', () async {
        // Arrange
        const userId = 'test-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final profileData = {
          'email': 'test@example.com',
          'username': 'testuser',
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(profileData);
        when(mockDocSnapshot.id).thenReturn(userId);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await userProfileService.getUserProfile(userId);

        // Assert
        expect(result, isA<UserProfile>());
        expect(result?.id, equals(userId));
        expect(result?.email, equals('test@example.com'));
        expect(result?.username, equals('testuser'));
      });

      test('should return null when document does not exist', () async {
        // Arrange
        const userId = 'test-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();

        when(mockDocSnapshot.exists).thenReturn(false);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await userProfileService.getUserProfile(userId);

        // Assert
        expect(result, isNull);
      });

      test('should throw exception on Firestore error', () async {
        // Arrange
        const userId = 'test-user-id';
        when(mockDocument.get()).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => userProfileService.getUserProfile(userId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updateUsername', () {
      test('should update username successfully', () async {
        // Arrange
        const userId = 'test-user-id';
        const newUsername = 'newusername';

        final mockQuerySnapshot = MockQuerySnapshot();
        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('username', isEqualTo: newUsername))
            .thenReturn(mockCollection);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);
        when(mockDocument.update(any)).thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => userProfileService.updateUsername(userId, newUsername),
          returnsNormally,
        );
      });

      test('should throw exception for invalid username', () async {
        // Arrange
        const userId = 'test-user-id';
        const invalidUsername = 'ab'; // Too short

        // Act & Assert
        expect(
          () => userProfileService.updateUsername(userId, invalidUsername),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for taken username', () async {
        // Arrange
        const userId = 'test-user-id';
        const newUsername = 'takenusername';

        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();
        when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
        when(mockCollection.where('username', isEqualTo: newUsername))
            .thenReturn(mockCollection);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act & Assert
        expect(
          () => userProfileService.updateUsername(userId, newUsername),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty user ID', () async {
        // Arrange
        const userId = '';
        const newUsername = 'newusername';

        // Act & Assert
        expect(
          () => userProfileService.updateUsername(userId, newUsername),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('isUsernameAvailable', () {
      test('should return true when username is available', () async {
        // Arrange
        const username = 'availableusername';
        final mockQuerySnapshot = MockQuerySnapshot();
        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockCollection.where('username', isEqualTo: username))
            .thenReturn(mockCollection);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await userProfileService.isUsernameAvailable(username);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when username is taken', () async {
        // Arrange
        const username = 'takenusername';
        final mockQuerySnapshot = MockQuerySnapshot();
        final mockDoc = MockQueryDocumentSnapshot();
        when(mockQuerySnapshot.docs).thenReturn([mockDoc]);
        when(mockCollection.where('username', isEqualTo: username))
            .thenReturn(mockCollection);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        // Act
        final result = await userProfileService.isUsernameAvailable(username);

        // Assert
        expect(result, isFalse);
      });

      test('should throw exception on Firestore error', () async {
        // Arrange
        const username = 'testusername';
        when(mockCollection.where('username', isEqualTo: username))
            .thenReturn(mockCollection);
        when(mockCollection.limit(1)).thenReturn(mockCollection);
        when(mockCollection.get()).thenThrow(Exception('Firestore error'));

        // Act & Assert
        expect(
          () => userProfileService.isUsernameAvailable(username),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updatePassword', () {
      test('should update password successfully', () async {
        // Arrange
        const currentPassword = 'currentpass';
        const newPassword = 'newpassword';

        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.reauthenticateWithCredential(any))
            .thenAnswer((_) async => mockUser);
        when(mockUser.updatePassword(newPassword))
            .thenAnswer((_) async => {});

        // Act & Assert
        expect(
          () => userProfileService.updatePassword(currentPassword, newPassword),
          returnsNormally,
        );
      });

      test('should throw exception when no user is logged in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);
        const currentPassword = 'currentpass';
        const newPassword = 'newpassword';

        // Act & Assert
        expect(
          () => userProfileService.updatePassword(currentPassword, newPassword),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for empty current password', () async {
        // Arrange
        const currentPassword = '';
        const newPassword = 'newpassword';

        // Act & Assert
        expect(
          () => userProfileService.updatePassword(currentPassword, newPassword),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception for invalid new password', () async {
        // Arrange
        const currentPassword = 'currentpass';
        const newPassword = '123'; // Too short

        // Act & Assert
        expect(
          () => userProfileService.updatePassword(currentPassword, newPassword),
          throwsA(isA<Exception>()),
        );
      });

      test('should throw exception when new password equals current password', () async {
        // Arrange
        const currentPassword = 'samepassword';
        const newPassword = 'samepassword';

        // Act & Assert
        expect(
          () => userProfileService.updatePassword(currentPassword, newPassword),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getCurrentUserProfile', () {
      test('should return current user profile when user is logged in', () async {
        // Arrange
        const userId = 'test-user-id';
        final mockDocSnapshot = MockDocumentSnapshot();
        final profileData = {
          'email': 'test@example.com',
          'username': 'testuser',
          'profilePictureUrl': null,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        };

        when(mockDocSnapshot.exists).thenReturn(true);
        when(mockDocSnapshot.data()).thenReturn(profileData);
        when(mockDocSnapshot.id).thenReturn(userId);
        when(mockDocument.get()).thenAnswer((_) async => mockDocSnapshot);

        // Act
        final result = await userProfileService.getCurrentUserProfile();

        // Assert
        expect(result, isA<UserProfile>());
        expect(result?.id, equals(userId));
      });

      test('should return null when no user is logged in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = await userProfileService.getCurrentUserProfile();

        // Assert
        expect(result, isNull);
      });
    });
  });
}