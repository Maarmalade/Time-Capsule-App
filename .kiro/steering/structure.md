---
inclusion: always
---

# Time Capsule - Architecture & Code Structure Guidelines

## Core Architecture Patterns

### Service Layer (Business Logic)
- **Single Responsibility**: Each service handles one domain (auth, storage, media, etc.)
- **Firebase Abstraction**: Services wrap Firebase operations with error handling
- **Authentication Check**: Always validate `FirebaseAuth.instance.currentUser` before operations
- **Stream-based**: Return `Stream<T>` for real-time data, `Future<T>` for operations
- **Error Transformation**: Convert Firebase exceptions to domain-specific exceptions

### Page Structure (`lib/pages/`)
- **Feature Grouping**: Organize by domain (`auth/`, `diary/`, `memory_album/`, `friends/`)
- **Naming**: All pages end with `_page.dart`
- **Route Registration**: Register in `routes.dart` with named routes
- **State Management**: Use `StatefulWidget` for local state, Firebase streams for data
- **Lifecycle**: Always dispose streams/controllers in `dispose()` method

### Widget Architecture (`lib/widgets/`)
- **Atomic Design**: Build from small, reusable components
- **Accessibility First**: Include `semanticsLabel` and proper roles
- **Design System**: Use `design_system/` tokens, never hardcode colors/spacing
- **Error States**: Include loading, error, and empty states for data widgets

### Model Patterns (`lib/models/`)
- **Immutable**: Use `@immutable` annotation, implement `copyWith()` methods
- **JSON Serialization**: Include `fromJson()` and `toJson()` for Firestore
- **Validation**: Validate data integrity in constructors
- **Type Safety**: Use enums for status fields, avoid magic strings

## Critical Implementation Rules

### Firebase Integration
- **Authentication**: Always check `FirebaseAuth.instance.currentUser` before operations
- **Error Handling**: Wrap all Firebase operations in try-catch blocks
- **Streams**: Always dispose Firebase streams in widget `dispose()` method
- **Security**: Validate user permissions before database operations

### Media & Performance
- **Compression**: All media must be compressed before upload using `flutter_image_compress`
- **Caching**: Use `cached_network_image` for all network images
- **Lists**: Use `ListView.builder` for lists with >20 items
- **Memory**: Profile memory usage for media-heavy features

### Accessibility (WCAG 2.1 AA Required)
- **Semantic Labels**: Every interactive element needs `semanticsLabel`
- **Focus Management**: Implement proper focus order for screen readers
- **Contrast**: Use design system colors that meet contrast requirements
- **Testing**: Run accessibility tests on all new UI components

## Code Style & File Organization

### File Naming Conventions
- **Pages**: `snake_case_page.dart` (e.g., `diary_editor_page.dart`)
- **Widgets**: `snake_case_widget.dart` (e.g., `audio_player_widget.dart`)
- **Services**: `snake_case_service.dart` (e.g., `media_service.dart`)
- **Models**: `snake_case_model.dart` (e.g., `diary_entry_model.dart`)

### Import Organization (Strict Order)
```dart
// 1. Flutter/Dart core imports
import 'package:flutter/material.dart';

// 2. Third-party packages (alphabetical)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 3. Local imports (alphabetical, relative paths)
import '../models/diary_entry_model.dart';
import '../services/diary_service.dart';
```

### Class Structure Template
```dart
class ExamplePage extends StatefulWidget {
  static const String routeName = '/example';
  
  const ExamplePage({super.key, required this.param});
  final String param;
  
  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {
  late final ExampleService _service;
  late final TextEditingController _controller;
  bool _isLoading = false;
  
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
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
  
  void _handleAction() {
    // Implementation
  }
}
```

## Key Directory Structure

### Core Directories
- `lib/pages/` - UI screens grouped by feature domain
- `lib/services/` - Business logic and Firebase operations
- `lib/models/` - Data models with JSON serialization
- `lib/widgets/` - Reusable UI components
- `lib/design_system/` - Colors, typography, spacing tokens
- `lib/utils/` - Helper functions and utilities

### Service Layer Requirements
- Each service handles one domain (auth, storage, media, etc.)
- Services return `Stream<T>` for real-time data, `Future<T>` for operations
- All service methods must handle Firebase exceptions
- Services should not directly instantiate other services