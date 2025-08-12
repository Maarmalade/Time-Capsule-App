# Design Document

## Overview

This design document outlines the implementation of user profile management and enhanced file management features for the time capsule Flutter app. The solution integrates with the existing Firebase Authentication, Firestore, and Firebase Storage infrastructure while maintaining the current app architecture and UI patterns.

## Architecture

### High-Level Architecture
The feature follows the existing app's layered architecture:
- **Presentation Layer**: Flutter pages and widgets with state management
- **Service Layer**: Business logic services for user profile and file operations
- **Data Layer**: Firebase Authentication, Firestore, and Firebase Storage
- **Model Layer**: Data models for user profiles and enhanced file metadata

### Key Components Integration
- Extends existing authentication flow with username creation
- Enhances current user model with profile information
- Integrates with existing folder and media services for file management
- Maintains current navigation and routing patterns

## Components and Interfaces

### 1. User Profile Management

#### UserProfileService
```dart
class UserProfileService {
  Future<void> createUserProfile(String userId, String username, String email);
  Future<UserProfile?> getUserProfile(String userId);
  Future<void> updateUsername(String userId, String newUsername);
  Future<bool> isUsernameAvailable(String username);
  Future<void> updateProfilePicture(String userId, File imageFile);
  Future<void> updatePassword(String currentPassword, String newPassword);
}
```

#### Enhanced UserModel
```dart
class UserProfile {
  final String id;
  final String email;
  final String username;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### Profile Pages
- **UsernameSetupPage**: Post-authentication username creation
- **ProfilePage**: Complete profile management interface
- **EditProfilePage**: Dedicated editing interface for profile updates

### 2. Enhanced File Management

#### Enhanced FolderService & MediaService
```dart
// Extensions to existing services
class FolderService {
  // Existing methods...
  Future<void> updateFolderName(String folderId, String newName);
  Future<void> deleteFolder(String folderId);
  Future<void> deleteFolders(List<String> folderIds);
}

class MediaService {
  // Existing methods...
  Future<void> updateFileName(String fileId, String newName);
  Future<void> deleteFile(String fileId);
  Future<void> deleteFiles(List<String> fileIds);
}
```

#### UI Components
- **OptionsMenuWidget**: Small options icon with edit/delete menu
- **MultiSelectManager**: State management for multi-selection mode
- **BatchActionBar**: Action bar for multi-select operations
- **ConfirmationDialog**: Reusable confirmation dialogs

### 3. Navigation and Routing

#### Enhanced Routes
```dart
class Routes {
  // Existing routes...
  static const String usernameSetup = '/username-setup';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
}
```

## Data Models

### Enhanced User Profile Schema (Firestore)
```json
{
  "users/{userId}": {
    "email": "string",
    "username": "string",
    "profilePictureUrl": "string?",
    "createdAt": "timestamp",
    "updatedAt": "timestamp"
  }
}
```

### Enhanced Folder/Media Metadata
```json
{
  "folders/{folderId}": {
    // Existing fields...
    "lastModified": "timestamp"
  },
  "media/{mediaId}": {
    // Existing fields...
    "lastModified": "timestamp"
  }
}
```

### Profile Picture Storage Structure
```
/users/{userId}/profile/
  - profile_picture.jpg
  - profile_picture_thumb.jpg (optimized thumbnail)
```

## User Interface Design

### 1. Username Setup Flow
- **Trigger**: After successful Firebase Authentication (new users)
- **Design**: Full-screen modal with username input, validation, and creation
- **Validation**: Real-time username availability checking
- **Navigation**: Automatic redirect to home after completion

### 2. Profile Page Layout
```
┌─────────────────────────────────┐
│ [Back] Profile         [Edit]   │
├─────────────────────────────────┤
│        [Profile Picture]        │
│                                 │
│         @username               │
│      user@email.com             │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Change Username             │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Change Password             │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Change Profile Picture      │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### 3. Enhanced Memory Cards
```
┌─────────────────────────────────┐
│ [Folder/File Name]      [⋮]    │ ← Options icon
│                                 │
│        [Content Preview]        │
│                                 │
│ [Selection Indicator]           │ ← Multi-select mode
└─────────────────────────────────┘
```

### 4. Multi-Select Mode
- **Activation**: Long press on any memory card
- **Visual Feedback**: Selected items highlighted with checkmarks
- **Action Bar**: Bottom bar with delete button and selection count
- **Exit**: Tap outside selection or cancel button

## Error Handling

### Username Validation
- **Duplicate Username**: "Username already taken. Please try another."
- **Invalid Format**: "Username must be 3-20 characters, letters, numbers, and underscores only."
- **Network Error**: "Unable to check username availability. Please try again."

### Profile Picture Upload
- **File Size**: "Image too large. Please select an image under 5MB."
- **File Type**: "Please select a valid image file (JPG, PNG)."
- **Upload Failure**: "Failed to upload image. Please try again."

### Password Change
- **Current Password Wrong**: "Current password is incorrect."
- **Weak Password**: "Password must be at least 6 characters long."
- **Network Error**: "Unable to update password. Please try again."

### File Operations
- **Delete Confirmation**: "Are you sure you want to delete [X] item(s)? This action cannot be undone."
- **Delete Failure**: "Failed to delete some items. Please try again."
- **Network Error**: "Unable to perform operation. Please check your connection."

## Testing Strategy

### Unit Tests
- **UserProfileService**: Username validation, profile CRUD operations
- **Enhanced File Services**: File/folder operations, batch operations
- **Models**: Data serialization and validation

### Widget Tests
- **Profile Pages**: UI interactions, form validation, navigation
- **Options Menu**: Menu display, action handling
- **Multi-Select**: Selection state management, batch operations

### Integration Tests
- **Authentication Flow**: Complete signup with username creation
- **Profile Management**: End-to-end profile updates
- **File Management**: Complete file operations including multi-select

### Firebase Security Rules Testing
- **User Profile Access**: Users can only access their own profiles
- **File Operations**: Users can only modify their own files
- **Profile Picture Storage**: Proper access controls for user images

## Performance Considerations

### Image Optimization
- **Profile Pictures**: Automatic resizing to 300x300px for storage
- **Thumbnails**: Generate 100x100px thumbnails for UI display
- **Compression**: Use flutter_image_compress for optimal file sizes

### Caching Strategy
- **Profile Data**: Cache user profiles locally with TTL
- **Profile Pictures**: Cache images with proper invalidation
- **File Lists**: Maintain local cache for better performance

### Batch Operations
- **Firestore Batching**: Use batch writes for multi-delete operations
- **Storage Cleanup**: Implement proper cleanup for deleted files
- **Progress Indicators**: Show progress for long-running operations

## Security Considerations

### Authentication & Authorization
- **Profile Access**: Users can only access and modify their own profiles
- **Username Uniqueness**: Server-side validation to prevent duplicates
- **Password Changes**: Require current password verification

### Data Validation
- **Input Sanitization**: Validate all user inputs on client and server
- **File Upload Security**: Validate file types and sizes
- **Username Constraints**: Enforce character limits and allowed characters

### Firebase Security Rules
```javascript
// Enhanced security rules for user profiles
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}

// Storage rules for profile pictures
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/profile/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```