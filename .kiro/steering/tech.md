---
inclusion: always
---

---
inclusion: always
---

# Time Capsule - Technical Implementation Guide

## Technology Stack
- **Flutter**: ^3.8.1 with Material Design 3
- **Firebase**: Auth, Firestore, Storage, Functions, FCM
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux
- **Cloud Functions**: Node.js v22

## Firebase Integration Rules

### Authentication Pattern
```dart
// ALWAYS check auth before Firebase operations
final user = FirebaseAuth.instance.currentUser;
if (user == null) throw AuthException('User not authenticated');

// Use AuthStateManager for centralized auth state
final authManager = AuthStateManager();
if (!authManager.isAuthenticated) return;
```

### Error Handling (Required)
```dart
// Wrap ALL Firebase operations
try {
  await FirebaseFirestore.instance.collection('users').doc(user.uid).set(data);
} on FirebaseException catch (e) {
  throw ServiceException('Operation failed: ${e.message}');
} catch (e) {
  throw ServiceException('Unexpected error: $e');
}
```

### Stream Management (Critical)
```dart
// ALWAYS dispose streams to prevent memory leaks
StreamSubscription? _subscription;

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

## Service Layer Requirements

### Service Structure
- Services are singletons wrapping Firebase operations
- Return `Future<T>` for operations, `Stream<T>` for real-time data
- Handle auth validation internally
- Transform Firebase exceptions to domain exceptions

### Example Service Pattern
```dart
class ExampleService {
  static final _instance = ExampleService._internal();
  factory ExampleService() => _instance;
  ExampleService._internal();

  Future<Model> createItem(Model item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw AuthException('Not authenticated');
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('items')
          .add(item.toJson());
      return item.copyWith(id: doc.id);
    } on FirebaseException catch (e) {
      throw ServiceException('Create failed: ${e.message}');
    }
  }
}
```

## Media Handling (Mandatory)

### Compression & Upload
- **MUST** compress all media using `flutter_image_compress` before upload
- Check permissions before camera/microphone access
- Show progress indicators for all upload operations
- Use `cached_network_image` for network images
- Implement fallback UI for media failures

### Performance Requirements
- Use `ListView.builder` for lists >20 items
- Dispose all controllers in `dispose()` method
- Use `const` constructors wherever possible
- Profile memory usage for media features

## Accessibility (WCAG 2.1 AA)

### Required Implementation
```dart
// Every interactive element needs semantics
Semantics(
  label: 'Descriptive action label',
  button: true,
  child: IconButton(onPressed: _action, icon: Icon(Icons.add)),
)

// Use design system for accessibility compliance
Container(
  color: AppColors.primary, // Pre-validated contrast
  child: Text('Content', style: AppTypography.bodyLarge),
)
```

## Error Handling Strategy

### Custom Exceptions
- `AuthException`: Authentication failures
- `ServiceException`: Firebase operation failures  
- `ValidationException`: Input validation errors
- `NetworkException`: Connectivity issues

### User-Facing Errors
- Show contextual messages, not technical details
- Provide actionable recovery steps
- Use snackbars for temporary errors, dialogs for critical issues
- Implement retry mechanisms for network failures

## Development Commands

```bash
# Run with Firebase emulators
flutter run --dart-define=USE_EMULATOR=true

# Test with coverage
flutter test --coverage

# Start Firebase emulators
firebase emulators:start --only auth,firestore,functions,storage

# Accessibility testing
flutter test --accessibility
```

## Code Quality Standards

### Testing Requirements
- Unit tests: >80% coverage using `mockito`
- Widget tests: Include accessibility validation
- Integration tests: Use `firebase_auth_mocks` and `fake_cloud_firestore`
- Run accessibility tests on all UI components

### Performance Monitoring
- Profile memory usage for media operations
- Monitor Firebase usage and costs
- Test on low-end devices for performance validation
- Implement proper loading states for async operations