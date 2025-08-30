---
inclusion: always
---

# Time Capsule - Project Structure & Architecture Guidelines

## Root Directory Structure

```
time_capsule/
├── lib/                    # Flutter application source code
├── functions/              # Firebase Cloud Functions (Node.js)
├── android/               # Android platform-specific code
├── ios/                   # iOS platform-specific code
├── web/                   # Web platform-specific code
├── windows/               # Windows platform-specific code
├── macos/                 # macOS platform-specific code
├── linux/                 # Linux platform-specific code
├── test/                  # Unit and widget tests
├── integration_test/      # Integration tests
├── .kiro/                 # Kiro AI assistant configuration
├── firebase.json          # Firebase project configuration
├── firestore.rules        # Firestore security rules
├── storage.rules          # Firebase Storage security rules
├── pubspec.yaml           # Flutter dependencies and metadata
└── analysis_options.yaml  # Dart analyzer configuration
```

## Flutter App Structure (`lib/`)

```
lib/
├── main.dart                    # App entry point and configuration
├── routes.dart                  # Route definitions and navigation
├── firebase_options.dart        # Firebase configuration (auto-generated)
├── constants/                   # App-wide constants
│   └── route_constants.dart     # Route name constants
├── models/                      # Data models and entities
│   ├── folder_model.dart        # Memory folder data structure
│   └── shared_folder_notification_model.dart
├── services/                    # Business logic and data access
│   ├── folder_service.dart      # Folder management logic
│   ├── profile_picture_service.dart
│   ├── storage_service.dart     # Firebase Storage operations
│   ├── video_service.dart       # Video handling and compression
│   └── scheduled_message_service.dart
├── pages/                       # UI screens and page widgets
│   ├── auth/                    # Authentication screens
│   ├── home/                    # Home dashboard
│   ├── profile/                 # User profile management
│   ├── friends/                 # Social features
│   ├── memory_album/            # Memory management
│   ├── shared_folder/           # Shared folder features
│   ├── scheduled_messages/      # Message scheduling
│   └── public_folders/          # Public content discovery
├── widgets/                     # Reusable UI components
│   ├── accessibility/           # Accessible widget implementations
│   ├── home_panel_card.dart     # Dashboard cards
│   ├── video_player_widget.dart # Video playback
│   ├── media_attachment_widget.dart # Media handling
│   └── notification_badge_widget.dart
├── design_system/               # Centralized design tokens and themes
│   ├── app_colors.dart          # Color palette
│   ├── app_typography.dart      # Text styles
│   ├── app_spacing.dart         # Spacing and layout
│   ├── app_theme.dart           # Complete theme configuration
│   ├── app_buttons.dart         # Button styles
│   ├── app_cards.dart           # Card components
│   ├── responsive_*.dart        # Responsive design utilities
│   └── README.md                # Design system documentation
├── accessibility/               # Accessibility utilities and guidelines
│   └── README.md                # Accessibility implementation guide
└── utils/                       # Helper functions and utilities
    ├── accessibility_utils.dart # Accessibility helpers
    ├── contrast_checker.dart    # WCAG compliance validation
    ├── comprehensive_error_handler.dart
    └── folder_access_fix.dart
```

## Firebase Functions Structure (`functions/`)

```
functions/
├── index.js                # Cloud Functions entry point
├── package.json           # Node.js dependencies and scripts
├── package-lock.json      # Dependency lock file
├── node_modules/          # Node.js dependencies (auto-generated)
├── test/                  # Function unit tests
└── README.md              # Functions documentation
```

## Critical Implementation Rules

### Firebase Integration
- **Authentication**: Always check `FirebaseAuth.instance.currentUser` before operations
- **Firestore**: Use `FirebaseFirestore.instance` with proper error handling
- **Storage**: Implement upload progress tracking and compression for media
- **Security**: Validate user permissions before any database operations

### Media Handling
- **Compression**: All images/videos must be compressed before upload
- **Caching**: Use `cached_network_image` for all network images
- **Permissions**: Check camera/microphone permissions before access
- **Error Recovery**: Provide fallback options when media operations fail

### Accessibility Requirements
- **Semantic Labels**: Every interactive element needs `semanticsLabel`
- **Focus Management**: Implement proper focus order for screen readers
- **Contrast**: Validate color combinations meet WCAG AA standards
- **Testing**: Run accessibility tests on all new UI components

### Performance Guidelines
- **Lazy Loading**: Use `ListView.builder` for large lists
- **Image Optimization**: Implement proper image sizing and caching
- **Stream Management**: Always dispose of Firebase streams
- **Memory Management**: Profile memory usage for media-heavy features

## Architecture Patterns & Code Organization

### Service Layer Architecture
- **Single Responsibility**: Each service handles one domain (auth, storage, media, etc.)
- **Firebase Abstraction**: Services wrap Firebase operations with error handling
- **Dependency Injection**: Services injected into pages/widgets, not directly instantiated
- **Stream-based**: Use Firebase streams for real-time data, return `Stream<T>` from services
- **Error Boundaries**: All service methods must handle and transform Firebase exceptions

### Page Structure Rules
- **Feature Grouping**: Group pages by domain (`auth/`, `diary/`, `memory_album/`, etc.)
- **Naming Convention**: All pages end with `_page.dart`
- **Route Registration**: Every page must be registered in `routes.dart` with named routes
- **State Management**: Use `StatefulWidget` for local state, Firebase streams for data
- **Lifecycle**: Dispose of streams and controllers in `dispose()` method

### Widget Composition
- **Atomic Design**: Build complex UIs from small, reusable components
- **Accessibility First**: Every custom widget must include semantic labels and roles
- **Design System**: Use tokens from `design_system/` - never hardcode colors/spacing
- **Responsive**: Widgets should adapt to different screen sizes using `MediaQuery`
- **Error States**: Include loading, error, and empty states for all data-dependent widgets

### Model & Data Patterns
- **Immutable Models**: Use `@immutable` annotation, implement `copyWith()` methods
- **JSON Serialization**: Include `fromJson()` and `toJson()` for Firestore integration
- **Validation**: Models should validate data integrity in constructors
- **Type Safety**: Use enums for status fields, avoid magic strings

## Code Style & Conventions

### File Naming
- **Pages**: `snake_case_page.dart` (e.g., `diary_editor_page.dart`)
- **Widgets**: `snake_case_widget.dart` (e.g., `audio_player_widget.dart`)
- **Services**: `snake_case_service.dart` (e.g., `media_service.dart`)
- **Models**: `snake_case_model.dart` (e.g., `diary_entry_model.dart`)
- **Utils**: `snake_case_utils.dart` (e.g., `validation_utils.dart`)

### Import Organization (Strict Order)
```dart
// 1. Flutter/Dart core imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 2. Third-party packages (alphabetical)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 3. Local imports (alphabetical, relative paths)
import '../models/diary_entry_model.dart';
import '../services/diary_service.dart';
import '../widgets/audio_player_widget.dart';
```

### Class Structure Template
```dart
class ExamplePage extends StatefulWidget {
  // 1. Static constants
  static const String routeName = '/example';
  
  // 2. Constructor parameters
  const ExamplePage({super.key, required this.param});
  final String param;
  
  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  // 1. Services (injected)
  late final ExampleService _service;
  
  // 2. Controllers
  late final TextEditingController _controller;
  
  // 3. State variables
  bool _isLoading = false;
  
  // 4. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _service = ExampleService();
    _controller = TextEditingController();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  // 5. Build method
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
  
  // 6. Private helper methods
  void _handleAction() {
    // Implementation
  }
}
```

### Testing Requirements
- **Unit Tests**: All services must have >80% coverage
- **Widget Tests**: All custom widgets must have widget tests
- **Integration Tests**: Critical user flows must have integration tests
- **Accessibility Tests**: All pages must pass accessibility validation
- **Mock Strategy**: Use `mockito` for service mocking, `fake_cloud_firestore` for Firestore