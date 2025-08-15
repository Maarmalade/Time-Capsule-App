# Design Document

## Overview

This design document outlines the technical approach for implementing critical bug fixes and feature improvements in the Time Capsule Flutter application. The improvements focus on enhancing scheduled messaging with media support, fixing shared folder functionality, streamlining friend interactions, and ensuring consistent profile picture display across the application.

The design leverages the existing Firebase architecture (Firestore, Storage, Authentication, Cloud Functions) and follows the current Flutter project structure with services, models, and UI components.

## Architecture

### Current Architecture Integration
The improvements will integrate with the existing architecture:
- **Models**: Extend existing models (`ScheduledMessage`, `FolderModel`) and maintain current data structures
- **Services**: Enhance existing services (`ScheduledMessageService`, `ProfilePictureService`, `FolderService`) 
- **UI Components**: Modify existing pages and widgets while maintaining current navigation patterns
- **Firebase Integration**: Utilize existing Firestore collections and Cloud Functions infrastructure

### Key Architectural Principles
1. **Minimal Disruption**: Enhance existing functionality without breaking current features
2. **Consistency**: Maintain consistent data flow and state management patterns
3. **Performance**: Implement efficient caching and real-time updates
4. **User Experience**: Provide immediate feedback and smooth interactions

## Components and Interfaces

### 1. Enhanced Scheduled Message System

#### Model Extensions
```dart
// Extend ScheduledMessage model to support multiple media types
class ScheduledMessage {
  // Existing fields...
  final List<String>? imageUrls;  // New: Support multiple images
  final String? videoUrl;         // Existing: Video support
  
  // New validation methods
  bool hasMedia() => (imageUrls?.isNotEmpty ?? false) || videoUrl != null;
  List<String> getAllMediaUrls() => [...(imageUrls ?? []), if (videoUrl != null) videoUrl!];
}
```

#### Service Enhancements
```dart
// Enhanced ScheduledMessageService
class ScheduledMessageService {
  // New method for media upload
  Future<List<String>> uploadMessageMedia(List<File> mediaFiles);
  
  // Enhanced creation with media support
  Future<String> createScheduledMessageWithMedia(
    ScheduledMessage message, 
    List<File>? images, 
    File? video
  );
  
  // Improved time validation
  bool validateScheduledTime(DateTime scheduledTime);
}
```

#### UI Components
- **MediaAttachmentWidget**: New widget for selecting and displaying media attachments
- **ScheduledMessageCard**: Enhanced to display media previews and accurate status
- **CreateScheduledMessagePage**: Updated with media selection capabilities

### 2. Fixed Shared Folder System

#### Service Modifications
```dart
// Enhanced FolderService
class FolderService {
  // New notification system for shared folder invitations
  Future<void> notifyContributorAdded(String folderId, String contributorId);
  
  // Real-time folder access updates
  Stream<List<FolderModel>> streamUserAccessibleFolders(String userId);
  
  // Contributor management
  Future<void> removeContributor(String folderId, String contributorId);
  Future<List<UserProfile>> getFolderContributors(String folderId);
}
```

#### Data Flow Improvements
1. **Immediate Access**: When a user is added as contributor, their folder list updates in real-time
2. **Notification System**: Push notifications inform users of shared folder invitations
3. **Permission Sync**: Contributor permissions are synchronized across all user sessions

### 3. Streamlined Friend Interactions

#### Navigation Enhancements
```dart
// Updated FriendActionDialog
class FriendActionDialog {
  // Simplified actions: only "Shared Folders" and "Remove Friend"
  void showFriendActions(UserProfile friend) {
    // Navigate to SharedFoldersPage with friend filter
    // Show remove friend confirmation
  }
}
```

#### New Shared Folders View
```dart
// New SharedFoldersPage for friend interactions
class SharedFoldersPage {
  final String friendId;
  
  // Display folders shared between current user and friend
  Stream<List<FolderModel>> getSharedFoldersBetweenUsers(String userId, String friendId);
}
```

### 4. Consistent Profile Picture System

#### Enhanced ProfilePictureService
```dart
class ProfilePictureService {
  // Global state management for profile pictures
  static final Map<String, String?> _profilePictureCache = {};
  static final StreamController<Map<String, String?>> _profilePictureStream = StreamController.broadcast();
  
  // Clear cache on user switch
  static void clearCacheForUser(String userId);
  
  // Update all instances when profile picture changes
  static void updateProfilePictureGlobally(String userId, String? imageUrl);
  
  // Stream for real-time updates
  static Stream<Map<String, String?>> get profilePictureUpdates;
}
```

#### Widget Integration
```dart
// Enhanced ProfilePictureWidget
class ProfilePictureWidget extends StatefulWidget {
  final String userId;
  final double size;
  
  // Automatically updates when profile picture changes globally
  // Handles caching and loading states
}
```

## Data Models

### Enhanced ScheduledMessage Model
```dart
class ScheduledMessage {
  final String id;
  final String senderId;
  final String recipientId;
  final String textContent;
  final List<String>? imageUrls;     // New: Multiple image support
  final String? videoUrl;
  final DateTime scheduledFor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ScheduledMessageStatus status;
  final DateTime? deliveredAt;
  
  // Enhanced validation
  bool isValidScheduledTime() {
    final now = DateTime.now();
    return scheduledFor.isAfter(now.add(Duration(minutes: 1)));
  }
}
```

### Shared Folder Notification Model
```dart
class SharedFolderNotification {
  final String id;
  final String folderId;
  final String folderName;
  final String ownerId;
  final String ownerUsername;
  final String contributorId;
  final DateTime createdAt;
  final bool isRead;
  
  Map<String, dynamic> toFirestore();
  factory SharedFolderNotification.fromFirestore(DocumentSnapshot doc);
}
```

### Profile Picture Cache Model
```dart
class ProfilePictureCache {
  final String userId;
  final String? imageUrl;
  final DateTime lastUpdated;
  final bool isLoading;
  
  bool isExpired() => DateTime.now().difference(lastUpdated) > Duration(minutes: 5);
}
```

## Error Handling

### Scheduled Message Errors
- **Time Validation**: Clear error messages for invalid scheduling times
- **Media Upload**: Progress indicators and retry mechanisms for media uploads
- **Status Sync**: Automatic retry for status update failures

### Shared Folder Errors
- **Access Denied**: Graceful handling when folder access is revoked
- **Notification Failures**: Fallback mechanisms for notification delivery
- **Sync Issues**: Automatic retry for folder list synchronization

### Profile Picture Errors
- **Cache Failures**: Fallback to default avatars when cache fails
- **Network Issues**: Offline support with cached images
- **Upload Errors**: Clear feedback for profile picture upload failures

## Testing Strategy

### Unit Testing
- **Model Validation**: Test enhanced model validation methods
- **Service Logic**: Test media upload, folder access, and profile picture caching
- **Time Validation**: Test scheduled message time validation edge cases

### Integration Testing
- **Firebase Integration**: Test Firestore queries and Cloud Function triggers
- **Media Upload**: Test image and video upload workflows
- **Real-time Updates**: Test stream subscriptions and cache invalidation

### Widget Testing
- **UI Components**: Test media attachment widgets and profile picture displays
- **Navigation**: Test friend action navigation and shared folder access
- **State Management**: Test profile picture consistency across screens

### End-to-End Testing
- **Scheduled Messages**: Complete workflow from creation to delivery with media
- **Shared Folders**: Full contributor invitation and access workflow
- **Profile Consistency**: User switching and profile picture updates across screens

## Implementation Phases

### Phase 1: Scheduled Message Enhancements
1. Extend ScheduledMessage model for media support
2. Implement media upload functionality in ScheduledMessageService
3. Update UI components for media attachment
4. Fix status synchronization issues
5. Improve time validation logic

### Phase 2: Shared Folder Fixes
1. Implement notification system for folder invitations
2. Fix real-time folder access updates
3. Add contributor management features
4. Remove lock folder functionality
5. Test contributor access workflows

### Phase 3: Friend Interaction Improvements
1. Simplify friend action dialog
2. Implement SharedFoldersPage for friend interactions
3. Remove send message functionality
4. Update navigation flows
5. Test friend-to-folder navigation

### Phase 4: Profile Picture Consistency
1. Enhance ProfilePictureService with global state management
2. Implement cache clearing on user switch
3. Update ProfilePictureWidget for real-time updates
4. Test consistency across all screens
5. Handle edge cases and error scenarios

## Security Considerations

### Media Upload Security
- File type validation for images and videos
- File size limits to prevent abuse
- Virus scanning for uploaded media
- Secure storage with proper access controls

### Shared Folder Security
- Proper permission validation for contributor access
- Audit logging for folder access changes
- Rate limiting for folder invitation notifications
- Secure contributor removal workflows

### Profile Picture Security
- Image validation and sanitization
- Secure caching mechanisms
- Proper cleanup of old profile pictures
- Access control for profile picture URLs

## Performance Optimizations

### Media Handling
- Image compression before upload
- Progressive loading for media previews
- Efficient caching of media thumbnails
- Background upload with progress tracking

### Real-time Updates
- Optimized Firestore queries with proper indexing
- Efficient stream subscriptions with automatic cleanup
- Debounced updates to prevent excessive re-renders
- Smart caching to reduce network requests

### Profile Picture Management
- Intelligent caching with expiration policies
- Lazy loading of profile pictures
- Efficient memory management for image cache
- Background refresh of expired cache entries