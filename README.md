# Time Capsule - Digital Memory & Diary App

A Flutter cross-platform application for creating and sharing digital memories through memory albums and diary entries with rich media support.

## 🚀 Features

- **Memory Albums**: Hierarchical folder system for organizing personal collections
- **Digital Diary**: Rich text diary entries with multimedia attachments
- **Social Features**: Friend system and collaborative memory sharing
- **Media Support**: Photos, videos, audio recordings with automatic compression
- **Scheduled Messages**: Time-delayed message delivery system
- **Real-time Sync**: Firebase-powered real-time data synchronization

## 📱 Platform Support

Currently optimized for **Android** development with Firebase integration.

## 🏗️ Project Structure

### Core Directories

```
lib/
├── models/          # Data models and business entities
├── services/        # Business logic and Firebase operations
├── pages/           # UI screens organized by feature
├── widgets/         # Reusable UI components
├── utils/           # Helper functions and utilities
└── design_system/   # Design tokens and theming
```

### 📊 Models (`lib/models/`)
Data models that define the structure of your app's entities:

- **`diary_entry_model.dart`** - Diary entry data structure with media attachments
- **`folder_model.dart`** - Memory album folder structure and metadata
- **`user_profile.dart`** - User profile information and settings
- **`friend_request_model.dart`** - Friend request system data
- **`scheduled_message_model.dart`** - Time-delayed message structure
- **`notification_payload_model.dart`** - Push notification data format
- **`media_file_model.dart`** - Media file metadata and references

### 🔧 Services (`lib/services/`)
Business logic layer that handles Firebase operations and app functionality:

- **`auth_service.dart`** - User authentication and session management
- **`folder_service.dart`** - Memory album CRUD operations
- **`media_service.dart`** - Media upload, compression, and management
- **`friend_service.dart`** - Friend system and social features
- **`notification_service.dart`** - Push notifications and alerts
- **`scheduled_message_service.dart`** - Time-delayed message delivery
- **`storage_service.dart`** - Firebase Storage operations
- **`fcm_service.dart`** - Firebase Cloud Messaging integration
- **`error_resolution_service.dart`** - Centralized error handling

### 📱 Pages (`lib/pages/`)
UI screens organized by feature domain:

#### Authentication (`auth/`)
- **`login.dart`** - User login screen
- **`register.dart`** - User registration flow
- **`username_setup_page.dart`** - Initial username configuration

#### Home (`home/`)
- **`home_page.dart`** - Main dashboard and navigation
- **`home_panel_grid.dart`** - Feature grid layout

#### Memory Albums (`memory_album/`)
- **`memory_album_page.dart`** - Album overview and management
- **`folder_detail_page.dart`** - Individual folder content view
- **`media_viewer_page.dart`** - Full-screen media viewing

#### Diary (`diary/`)
- **`digital_diary_page.dart`** - Diary entries overview
- **`diary_editor_page.dart`** - Rich text diary editor
- **`diary_viewer_page.dart`** - Read-only diary entry view

#### Friends (`friends/`)
- **`add_friend_page.dart`** - Friend search and invitation
- **`friend_requests_page.dart`** - Incoming/outgoing requests
- **`friends_page.dart`** - Friends list and management

#### Profile (`profile/`)
- **`profile_page.dart`** - User profile and settings
- **`edit_username_page.dart`** - Username modification
- **`change_password_page.dart`** - Password update flow

### 🧩 Widgets (`lib/widgets/`)
Reusable UI components for consistent design:

- **`media_attachment_widget.dart`** - Media display and interaction
- **`audio_player_widget.dart`** - Audio playback controls
- **`video_player_widget.dart`** - Video playback interface
- **`nostalgia_reminder_widget.dart`** - Memory reminder notifications
- **`profile_picture_widget.dart`** - User avatar display
- **`friend_request_card.dart`** - Friend request UI component
- **`splash_screen.dart`** - App loading screen

### 🛠️ Utils (`lib/utils/`)
Helper functions and utilities:

- **`error_handler.dart`** - Centralized error management
- **`validation_utils.dart`** - Input validation helpers
- **`upload_utils.dart`** - Media upload optimization
- **`accessibility_utils.dart`** - WCAG 2.1 AA compliance helpers
- **`rate_limiter.dart`** - API call rate limiting
- **`retry_mechanism.dart`** - Network retry logic

### 🎨 Design System (`lib/design_system/`)
Consistent design tokens and theming:

- **`app_colors.dart`** - Color palette and semantic colors
- **`app_typography.dart`** - Text styles and font definitions
- **`app_spacing.dart`** - Consistent spacing values
- **`app_theme.dart`** - Material Design 3 theme configuration
- **`responsive_layout.dart`** - Responsive design utilities

## 🔥 Firebase Integration

### Services Used
- **Authentication** - User login/registration
- **Firestore** - Real-time database for app data
- **Storage** - Media file storage with compression
- **Cloud Functions** - Server-side logic (Node.js)
- **Cloud Messaging** - Push notifications

### Configuration Files
- **`firebase.json`** - Firebase project configuration
- **`firestore.rules`** - Database security rules
- **`firestore.indexes.json`** - Database query optimization
- **`storage.rules`** - File storage security rules

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.8.1
- Android Studio / VS Code
- Firebase CLI
- Node.js v22 (for Cloud Functions)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd time_capsule
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase setup**
   ```bash
   firebase login
   firebase use --add
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Development Commands

```bash
# Run with Firebase emulators
flutter run --dart-define=USE_EMULATOR=true

# Start Firebase emulators
firebase emulators:start --only auth,firestore,functions,storage

# Build for Android
flutter build apk --release
```

## 🧪 Testing & Quality

### Code Quality Standards
- Unit tests with >80% coverage
- Widget tests with accessibility validation
- Firebase integration tests using mocks
- Performance profiling for media operations

### Accessibility
- WCAG 2.1 AA compliance
- Screen reader support
- Keyboard navigation
- High contrast mode support

## 📚 Architecture Patterns

### Service Layer Pattern
- Single responsibility services
- Firebase operation abstraction
- Consistent error handling
- Stream-based real-time data

### Widget Architecture
- Atomic design principles
- Accessibility-first approach
- Design system consistency
- Proper state management

## 🤝 Contributing

1. Follow the established folder structure
2. Use the design system components
3. Include accessibility features
4. Write tests for new functionality
5. Follow Firebase integration patterns

