# Time Capsule - Project Structure

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

## Key Architectural Patterns

### Page Organization
- **Feature-based folders**: Pages grouped by functionality (auth, profile, friends, etc.)
- **Consistent naming**: `*_page.dart` for screen widgets
- **Route integration**: All pages registered in `routes.dart`

### Service Layer
- **Single responsibility**: Each service handles one domain area
- **Firebase integration**: Services abstract Firebase operations
- **Error handling**: Comprehensive error management across services

### Widget Structure
- **Reusable components**: Common UI elements in `widgets/`
- **Accessibility first**: Dedicated accessible widget implementations
- **Design system integration**: All widgets use design system tokens

### Design System
- **Token-based**: Colors, typography, spacing defined as constants
- **Material 3**: Following latest Material Design principles
- **Responsive**: Adaptive layouts for different screen sizes
- **Accessible**: WCAG 2.1 AA compliance built-in

### State Management
- **Firebase Streams**: Real-time data through Firestore streams
- **Local State**: StatefulWidget for component-level state
- **Service Layer**: Business logic encapsulated in service classes

## File Naming Conventions

- **Pages**: `snake_case_page.dart`
- **Widgets**: `snake_case_widget.dart`
- **Services**: `snake_case_service.dart`
- **Models**: `snake_case_model.dart`
- **Utils**: `snake_case_utils.dart`
- **Constants**: `snake_case_constants.dart`

## Import Organization

1. Flutter/Dart imports
2. Third-party package imports
3. Local project imports (alphabetical)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/folder_model.dart';
import '../services/folder_service.dart';
import '../widgets/accessible_button.dart';
```

## Testing Structure

- **Unit tests**: `test/unit/` - Service and utility testing
- **Widget tests**: `test/widget/` - UI component testing
- **Integration tests**: `integration_test/` - End-to-end user flows
- **Accessibility tests**: `test/accessibility/` - WCAG compliance validation