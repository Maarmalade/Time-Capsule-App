# MediaAttachmentWidget

A Flutter widget for selecting and managing media attachments (images and videos) for scheduled messages in the Time Capsule app.

## Features

- **Multiple Image Selection**: Select up to a configurable number of images (default: 5)
- **Single Video Selection**: Select one video file
- **Image Previews**: Display thumbnail previews of selected images with remove capability
- **Video Preview**: Show video placeholder with play indicator
- **File Validation**: Validate file types and sizes with user feedback
- **Size Limits**: Configurable size limits for images and videos
- **Error Handling**: Display validation errors and file selection issues

## Usage

```dart
import 'package:time_capsule/widgets/media_attachment_widget.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  List<File> _selectedImages = [];
  File? _selectedVideo;

  @override
  Widget build(BuildContext context) {
    return MediaAttachmentWidget(
      selectedImages: _selectedImages,
      selectedVideo: _selectedVideo,
      onImagesChanged: (images) {
        setState(() {
          _selectedImages = images;
        });
      },
      onVideoChanged: (video) {
        setState(() {
          _selectedVideo = video;
        });
      },
      maxImages: 5,           // Optional: default is 5
      maxImageSizeMB: 10,     // Optional: default is 10MB
      maxVideoSizeMB: 50,     // Optional: default is 50MB
    );
  }
}
```

## Parameters

### Required Parameters

- `selectedImages` (List<File>): Currently selected image files
- `selectedVideo` (File?): Currently selected video file (null if none)
- `onImagesChanged` (Function(List<File>)): Callback when image selection changes
- `onVideoChanged` (Function(File?)): Callback when video selection changes

### Optional Parameters

- `maxImages` (int): Maximum number of images allowed (default: 5)
- `maxImageSizeMB` (int): Maximum size per image in MB (default: 10)
- `maxVideoSizeMB` (int): Maximum size for video in MB (default: 50)

## File Type Support

### Supported Image Formats
- JPEG (.jpg, .jpeg)
- PNG (.png)
- GIF (.gif)
- WebP (.webp)

### Supported Video Formats
- MP4 (.mp4)
- MOV (.mov)
- AVI (.avi)
- MKV (.mkv)
- WebM (.webm)

## Validation Rules

### Image Validation
- File size must not exceed `maxImageSizeMB`
- File type must be in supported formats
- Total number of images must not exceed `maxImages`

### Video Validation
- File size must not exceed `maxVideoSizeMB`
- File type must be in supported formats
- Only one video can be selected at a time
- Maximum video duration: 5 minutes (enforced by image_picker)

## UI Components

### Selection Buttons
- **Add Images Button**: Shows current count and allows image selection
- **Add/Remove Video Button**: Changes based on video selection state

### Media Previews
- **Image Previews**: Horizontal scrollable list with thumbnails and remove buttons
- **Video Preview**: Placeholder with play indicator and file information

### Validation Feedback
- **Error Messages**: Display validation errors in a styled container
- **File Size Display**: Show file sizes on media previews

## Error Handling

The widget handles various error scenarios:

- **File Size Exceeded**: Shows specific error with actual vs. maximum size
- **Unsupported Format**: Displays error for invalid file types
- **Selection Limit**: Prevents selection when maximum is reached
- **File Access Errors**: Handles file system access issues

## Integration with ScheduledMessage

This widget is designed to work with the enhanced ScheduledMessage model:

```dart
// Example integration
final scheduledMessage = ScheduledMessage(
  // ... other fields
  imageUrls: await uploadImages(_selectedImages),
  videoUrl: _selectedVideo != null ? await uploadVideo(_selectedVideo!) : null,
);
```

## Dependencies

- `image_picker`: For selecting images and videos from device gallery
- `flutter/material.dart`: For Material Design components

## Testing

The widget includes comprehensive tests:

- Unit tests for widget rendering and state management
- Integration tests for user interactions
- Validation tests for file size and type checking

Run tests with:
```bash
flutter test test/widgets/media_attachment_widget_test.dart
flutter test test/widgets/media_attachment_widget_integration_test.dart
```

## Accessibility

The widget follows Flutter accessibility guidelines:

- Semantic labels for buttons and interactive elements
- Proper contrast ratios for text and backgrounds
- Screen reader support for media previews
- Keyboard navigation support

## Performance Considerations

- **Image Compression**: Images are compressed during selection (quality: 85%)
- **Size Limits**: Prevents memory issues with large files
- **Lazy Loading**: File size calculations are performed asynchronously
- **Efficient Rendering**: Uses ListView for horizontal image scrolling

## Future Enhancements

Potential improvements for future versions:

- **Drag and Drop**: Support for drag-and-drop file selection
- **Cloud Storage**: Direct upload to Firebase Storage
- **Image Editing**: Basic image editing capabilities
- **Video Thumbnails**: Generate actual video thumbnails
- **Progress Indicators**: Show upload progress for large files