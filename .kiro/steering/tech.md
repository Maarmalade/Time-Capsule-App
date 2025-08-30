---
inclusion: always
---

# Time Capsule - Technical Implementation Guide

## Core Technology Stack
- **Flutter SDK**: ^3.8.1 with Material Design 3
- **Firebase**: Complete BaaS integration (Auth, Firestore, Storage, Functions)
- **Target Platforms**: Android, iOS, Web, Windows, macOS, Linux
- **Node.js**: v22 for Cloud Functions

## Critical Implementation Rules

### Firebase Integration Patterns
```dart
// Always check authentication before operations
final user = FirebaseAuth.instance.currentUser;
if (user == null) throw Exception('User not authenticated');

// Use proper error handling for all Firebase operations
try {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data);
} on FirebaseException catch (e) {
  // Handle specific Firebase errors
}

// Dispose streams properly
StreamSubscription? _subscription;
@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

### Media Handling Requirements
- **Compression**: All media MUST be compressed before upload using `flutter_image_compress`
- **Permissions**: Check permissions before accessing camera/microphone
- **Progress Tracking**: Show upload progress for all media operations
- **Caching**: Use `cached_network_image` for all network images
- **Error Recovery**: Provide fallback UI when media operations fail

### Service Layer Architecture
- Services are singletons that wrap Firebase operations
- All service methods return `Future<T>` or `Stream<T>`
- Services handle authentication checks internally
- Use dependency injection pattern for testability

### Accessibility Implementation (WCAG 2.1 AA Required)
```dart
// Every interactive widget needs semantic labels
Semantics(
  label: 'Record audio message',
  button: true,
  child: IconButton(onPressed: _recordAudio, icon: Icon(Icons.mic)),
)

// Use design system colors that meet contrast requirements
Container(
  color: AppColors.primary, // Pre-validated for accessibility
  child: Text('Content', style: AppTypography.bodyLarge),
)
```

### Error Handling Patterns
```dart
// Service layer error handling
class DiaryService {
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw AuthException('User not authenticated');
      
      final docRef = await FirebaseFirestore.instance
          .collection('diary_entries')
          .add(entry.toJson());
      
      return entry.copyWith(id: docRef.id);
    } on FirebaseException catch (e) {
      throw DiaryException('Failed to create entry: ${e.message}');
    }
  }
}
```

### Testing Requirements
- **Unit Tests**: All services must have >80% coverage using `mockito`
- **Widget Tests**: Custom widgets require widget tests with accessibility validation
- **Integration Tests**: Critical flows tested with `firebase_auth_mocks` and `fake_cloud_firestore`
- **Accessibility Tests**: Use `flutter test --accessibility` for all UI components

### Development Commands
```bash
# Development with emulators
flutter run --dart-define=USE_EMULATOR=true

# Run with device preview for responsive testing
flutter run --dart-define=DEVICE_PREVIEW=true

# Test with coverage
flutter test --coverage

# Firebase emulator setup
firebase emulators:start --only auth,firestore,functions,storage
```

### Performance Guidelines
- Use `ListView.builder` for large lists (>20 items)
- Implement proper image sizing with `cached_network_image`
- Dispose controllers and streams in widget `dispose()` methods
- Use `const` constructors wherever possible
- Profile memory usage for media-heavy features