# Design Document

## Overview

This design document outlines the implementation of enhanced media capture capabilities and a digital diary system for the Time Capsule app. The solution extends the existing media management architecture to support camera integration, comprehensive audio handling, and structured diary entries while maintaining consistency with the current design system and user experience patterns.

## Architecture

### High-Level Architecture

The enhanced media system builds upon the existing Flutter/Firebase architecture with the following key components:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
├─────────────────────────────────────────────────────────────┤
│ Enhanced Folder Detail Page │ Digital Diary Editor          │
│ Media Capture Dialogs       │ Audio Recording Interface     │
│ Camera Confirmation Screen  │ Media Selection Dialogs       │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer                            │
├─────────────────────────────────────────────────────────────┤
│ Enhanced Media Service      │ Audio Recording Service       │
│ Camera Capture Service      │ Digital Diary Service         │
│ File Picker Service         │ Media Compression Service     │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
├─────────────────────────────────────────────────────────────┤
│ Extended MediaFileModel     │ DiaryEntryModel               │
│ Firebase Storage            │ Cloud Firestore              │
└─────────────────────────────────────────────────────────────┘
```

### Package Dependencies

The implementation requires adding the following packages to `pubspec.yaml`:

- `record: ^5.0.4` - Audio recording functionality
- `audioplayers: ^6.0.0` - Audio playback capabilities  
- `file_picker: ^8.0.0` - File selection from device storage
- `permission_handler: ^11.3.1` - Camera and microphone permissions
- `path_provider: ^2.1.2` - Temporary file storage for recordings

## Components and Interfaces

### 1. Enhanced Media Selection System

#### MediaSourceDialog Widget
A reusable dialog component that presents source selection options:

```dart
class MediaSourceDialog extends StatelessWidget {
  final String mediaType; // 'image', 'video', 'audio'
  final Function(MediaSource) onSourceSelected;
  
  // Displays appropriate options based on mediaType:
  // - Image: Camera, Gallery
  // - Video: Camera, Gallery  
  // - Audio: Record, Select File
}
```

#### CameraConfirmationScreen Widget
A full-screen confirmation interface for camera captures:

```dart
class CameraConfirmationScreen extends StatefulWidget {
  final XFile capturedMedia;
  final MediaType mediaType;
  final Function(bool) onConfirmation;
  
  // Features:
  // - Full-screen preview of captured content
  // - X button (retake) and ✓ button (confirm)
  // - Consistent with app design system
}
```

### 2. Audio Recording System

#### AudioRecordingService
Manages audio recording operations with comprehensive state management:

```dart
class AudioRecordingService {
  // Core recording functionality
  Future<void> startRecording(String outputPath);
  Future<String?> stopRecording();
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  
  // State management
  Stream<RecordingState> get recordingStateStream;
  Stream<Duration> get recordingDurationStream;
  Stream<double> get amplitudeStream;
  
  // Playback for review
  Future<void> playRecording(String filePath);
  Future<void> stopPlayback();
}
```

#### AudioRecordingInterface Widget
A comprehensive audio recording UI component:

```dart
class AudioRecordingInterface extends StatefulWidget {
  final Function(String) onRecordingComplete;
  final Function() onCancel;
  
  // Features:
  // - Large record button with visual feedback
  // - Real-time duration display
  // - Waveform visualization using amplitude stream
  // - Pause/resume functionality
  // - Playback controls for review
  // - Save/cancel/re-record options
}
```

### 3. Digital Diary System

#### DiaryEntryModel
Extended data model for structured diary entries:

```dart
class DiaryEntryModel {
  final String id;
  final String folderId;
  final String title;
  final String content;
  final List<DiaryMediaAttachment> attachments;
  final Timestamp createdAt;
  final Timestamp? lastModified;
  final String? uploadedBy; // For shared folders
  
  // Supports rich text content with embedded media references
  // Attachments maintain order and positioning within content
}

class DiaryMediaAttachment {
  final String id;
  final String type; // 'image', 'video', 'audio'
  final String url;
  final String? caption;
  final int position; // Position within content
}
```

#### DiaryEditorPage Widget
A comprehensive diary creation and editing interface:

```dart
class DiaryEditorPage extends StatefulWidget {
  final String folderId;
  final DiaryEntryModel? existingEntry; // null for new entries
  
  // Features:
  // - Editable title field with validation
  // - Rich text editor for content
  // - Floating action button for media insertion
  // - Inline media preview and management
  // - Auto-save functionality
  // - Consistent with app design system
}
```

#### DiaryViewerPage Widget
A dedicated viewer for diary entries:

```dart
class DiaryViewerPage extends StatefulWidget {
  final DiaryEntryModel diary;
  final bool canEdit;
  
  // Features:
  // - Formatted display of title and content
  // - Embedded media with proper aspect ratios
  // - Audio playback controls
  // - Edit button (if permissions allow)
  // - Share functionality
}
```

### 4. Enhanced Media Management

#### Enhanced MediaService
Extended service with new media type support:

```dart
class MediaService {
  // Existing methods remain unchanged
  
  // New methods for enhanced functionality
  Future<String> createDiaryEntry(String folderId, DiaryEntryModel diary);
  Future<void> updateDiaryEntry(String folderId, String diaryId, DiaryEntryModel diary);
  Future<String> uploadAudioFile(String folderId, String filePath, String title);
  Future<MediaFileModel> captureAndUploadImage(String folderId, ImageSource source);
  Future<MediaFileModel> captureAndUploadVideo(String folderId, ImageSource source);
}
```

## Data Models

### Extended MediaFileModel
The existing model supports the new audio type and diary entries:

```dart
class MediaFileModel {
  // Existing fields remain unchanged
  final String type; // Now supports: 'image', 'video', 'text', 'audio', 'diary'
  
  // New optional fields for enhanced functionality
  final Duration? duration; // For audio and video files
  final Map<String, dynamic>? metadata; // Extensible metadata storage
  final String? uploadedBy; // For shared folder attribution
  final Timestamp? uploadedAt; // Upload timestamp for shared folders
}
```

### DiaryEntryModel Structure
```dart
class DiaryEntryModel extends MediaFileModel {
  final String content; // Rich text content
  final List<DiaryMediaAttachment> attachments;
  
  // Inherits from MediaFileModel with type = 'diary'
  // Uses existing folder structure and permissions
}
```

## Error Handling

### Permission Management
Comprehensive permission handling for camera, microphone, and storage access:

```dart
class PermissionService {
  Future<bool> requestCameraPermission();
  Future<bool> requestMicrophonePermission();
  Future<bool> requestStoragePermission();
  Future<void> showPermissionDeniedDialog(BuildContext context, String permission);
}
```

### Error Recovery Strategies
- **Camera failures**: Graceful fallback to gallery selection
- **Recording failures**: Clear error messages with retry options
- **Storage failures**: Temporary local storage with retry mechanisms
- **Network failures**: Offline capability with sync when connection restored

## Testing Strategy

### Unit Tests
- **AudioRecordingService**: Recording state management, file operations
- **MediaService**: Enhanced media creation and management
- **DiaryEntryModel**: Data serialization and validation
- **PermissionService**: Permission request handling

### Widget Tests
- **MediaSourceDialog**: Source selection interactions
- **AudioRecordingInterface**: Recording controls and state display
- **DiaryEditorPage**: Content editing and media insertion
- **CameraConfirmationScreen**: Confirmation flow interactions

### Integration Tests
- **End-to-end media capture**: Camera → confirmation → save flow
- **Audio recording workflow**: Record → review → save flow
- **Diary creation**: Create → add media → save → view flow
- **Cross-platform compatibility**: iOS and Android specific behaviors

### Accessibility Tests
- **Screen reader compatibility**: All new interfaces support TalkBack/VoiceOver
- **Keyboard navigation**: Full keyboard accessibility for all controls
- **High contrast support**: Proper contrast ratios for all UI elements
- **Font scaling**: Support for system font size preferences

## Implementation Phases

### Phase 1: Enhanced Image/Video Capture
- Implement MediaSourceDialog for image and video selection
- Add camera capture with confirmation screen
- Extend existing image/video upload flows
- Update folder detail page add menu

### Phase 2: Audio Recording System
- Implement AudioRecordingService with full state management
- Create AudioRecordingInterface widget
- Add audio file selection capability
- Integrate audio options into folder add menu

### Phase 3: Digital Diary System
- Implement DiaryEntryModel and related data structures
- Create DiaryEditorPage with rich text editing
- Implement DiaryViewerPage for viewing entries
- Add "Add Diary Doc" option to folder menu

### Phase 4: Integration and Polish
- Integrate all new features into existing folder management
- Implement comprehensive error handling
- Add accessibility features and testing
- Performance optimization and testing

## Security Considerations

### File Upload Security
- **File type validation**: Strict validation of uploaded file types
- **File size limits**: Configurable limits for different media types
- **Malware scanning**: Integration with Firebase App Check for security
- **Content moderation**: Placeholder for future content filtering

### Privacy Protection
- **Local storage encryption**: Temporary files encrypted on device
- **Secure deletion**: Proper cleanup of temporary recording files
- **Permission transparency**: Clear explanation of permission requirements
- **Data retention**: Configurable retention policies for different content types

## Performance Considerations

### Media Compression
- **Image compression**: Maintain existing flutter_image_compress integration
- **Video compression**: Leverage existing video compression pipeline
- **Audio compression**: Implement efficient audio encoding (AAC/MP3)
- **Progressive upload**: Background upload with progress indication

### Memory Management
- **Streaming playback**: Audio/video streaming to minimize memory usage
- **Image caching**: Leverage existing cached_network_image implementation
- **Temporary file cleanup**: Automatic cleanup of recording artifacts
- **Background processing**: Non-blocking media processing operations