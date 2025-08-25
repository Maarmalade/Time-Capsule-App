# Time Capsule - Technical Stack

## Framework & Platform
- **Flutter SDK**: ^3.8.1 - Cross-platform mobile development
- **Dart**: Primary programming language
- **Target Platforms**: Android, iOS, Web, Windows, macOS, Linux

## Backend & Services
- **Firebase Core**: ^3.15.1 - Backend-as-a-Service platform
- **Firebase Auth**: ^5.6.2 - User authentication and management
- **Cloud Firestore**: ^5.6.2 - NoSQL document database
- **Firebase Storage**: ^12.3.6 - File storage for images/videos
- **Cloud Functions**: ^5.6.2 - Serverless backend logic (Node.js 22)
- **Firebase App Check**: ^0.3.1+3 - App security and abuse prevention

## Key Dependencies
- **UI/UX**: Google Fonts ^6.1.0, Material Design 3
- **Media**: image_picker ^1.0.7, flutter_image_compress ^2.2.0, cached_network_image ^3.3.1
- **Video**: video_player ^2.9.2, chewie ^1.8.5
- **Calendar**: table_calendar ^3.0.9
- **Development**: device_preview ^1.3.1

## Development Tools
- **Linting**: flutter_lints ^5.0.0 (standard Flutter linting rules)
- **Testing**: mockito ^5.4.4, build_runner ^2.4.9, fake_cloud_firestore ^3.0.3, firebase_auth_mocks ^0.14.0
- **Functions Testing**: jest ^29.7.0, firebase-functions-test ^3.1.0

## Common Commands

### Flutter Development
```bash
# Install dependencies
flutter pub get

# Run app in development
flutter run

# Run with device preview (responsive testing)
flutter run --dart-define=DEVICE_PREVIEW=true

# Build for production
flutter build apk --release
flutter build ios --release

# Run tests
flutter test
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format .
```

### Firebase Functions
```bash
# Navigate to functions directory first
cd functions

# Install dependencies
npm install

# Start local emulator
npm run serve
# or
firebase emulators:start --only functions

# Deploy functions
npm run deploy
# or
firebase deploy --only functions

# Run tests
npm test
npm run test:coverage

# View logs
npm run logs
```

### Firebase Emulator Suite
```bash
# Start all emulators (from project root)
firebase emulators:start

# Start specific emulators
firebase emulators:start --only auth,firestore,functions

# Access emulator UI at http://localhost:4000
```

## Architecture Patterns
- **Clean Architecture**: Separation of concerns with services, models, and UI layers
- **Provider/State Management**: Implicit state management through Firebase streams
- **Repository Pattern**: Service classes handle data access and business logic
- **Design System**: Centralized theming and component system in `lib/design_system/`

## Code Style
- Follows `package:flutter_lints/flutter.yaml` standards
- Material Design 3 principles
- Comprehensive accessibility implementation (WCAG 2.1 AA)
- Professional UI with Inter/Roboto typography
- 8px grid-based spacing system