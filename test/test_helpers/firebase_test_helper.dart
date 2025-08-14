import 'package:firebase_core/firebase_core.dart';

void setupFirebaseAuthMocks() {
  // This function can be used to set up Firebase mocks for testing
  // Currently empty as the setup is done in individual test files
}

class MockFirebaseOptions extends FirebaseOptions {
  const MockFirebaseOptions()
    : super(
        apiKey: 'mock-api-key',
        appId: 'mock-app-id',
        messagingSenderId: 'mock-sender-id',
        projectId: 'mock-project-id',
      );
}
