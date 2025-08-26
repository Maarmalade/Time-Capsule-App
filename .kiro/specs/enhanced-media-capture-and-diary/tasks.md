# Implementation Plan

- [x] 1. Set up dependencies and permissions





  - Add required packages to pubspec.yaml (record, audioplayers, file_picker, permission_handler, path_provider)
  - Configure platform-specific permissions in Android and iOS manifests
  - Create PermissionService class for handling camera, microphone, and storage permissions
  - _Requirements: 1.2, 2.3, 4.2_

-

- [x] 2. Implement enhanced image capture system



- [x] 2.1 Create MediaSourceDialog widget


  - Build reusable dialog component that shows Camera/Gallery options for images
  - Implement proper styling consistent with app design system
  - Add accessibility labels and semantic properties

  - _Requirements: 1.1, 1.7_

- [x] 2.2 Implement CameraConfirmationScreen widget






  - Create full-screen confirmation interface for captured photos
  - Add X button for retake and ✓ button for confirmation functionality
  - Implement proper image preview with aspect ratio handling
  - Add navigation logic for retake and confirm actions
  - _Requirements: 1.3, 1.4, 1.5, 1.6_

- [x] 2.3 Enhance MediaService for camera capture


  - Add captureAndUploadImage method that handles ImageSource.camera
  - Integrate camera capture with existing image upload pipeline
  - Implement error handling for camera access failures
  - _Requirements: 1.2, 1.6_

- [x] 2.4 Update folder detail page for enhanced image selection


  - Modify _addImage method to show MediaSourceDialog instead of direct gallery picker
  - Integrate camera confirmation flow into existing image upload process
  - Maintain existing gallery selection functionality
  - _Requirements: 1.1, 1.7_
-

- [x] 3. Implement enhanced video capture system




- [x] 3.1 Extend MediaSourceDialog for video support

  - Add video-specific camera/gallery options to existing MediaSourceDialog
  - Implement video capture confirmation flow similar to image confirmation
  - _Requirements: 4.1, 4.2_

- [x] 3.2 Enhance video capture in MediaService


  - Add captureAndUploadVideo method for camera-based video recording
  - Integrate with existing video compression and upload pipeline
  - _Requirements: 4.3, 4.4_

- [x] 3.3 Update folder detail page for enhanced video selection


  - Modify _addVideo method to use MediaSourceDialog for source selection
  - Integrate video camera capture with existing video upload process
  - _Requirements: 4.1, 4.5_

- [x] 4. Implement audio recording system




- [x] 4.1 Create AudioRecordingService class


  - Implement core recording functionality with start, stop, pause, resume methods
  - Add state management with streams for recording state, duration, and amplitude
  - Implement playback functionality for recorded audio review
  - Add proper error handling and permission management
  - _Requirements: 2.3, 2.4, 2.5_

- [x] 4.2 Build AudioRecordingInterface widget


  - Create comprehensive UI with large record button and visual feedback
  - Implement real-time duration display and waveform visualization
  - Add pause/resume controls and playback functionality for review
  - Implement save/cancel/re-record options with proper state management
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [x] 4.3 Implement audio file selection functionality


  - Create audio file picker using file_picker package with audio filtering
  - Add audio file validation and metadata extraction
  - Implement audio file upload to Firebase Storage with proper naming
  - _Requirements: 2.6_

- [x] 4.4 Add audio support to MediaService


  - Implement uploadAudioFile method for handling audio file uploads
  - Extend createMediaWithAttribution to support audio type
  - Add audio-specific metadata handling (duration, file size)
  - _Requirements: 2.7_

- [x] 4.5 Integrate audio options into folder detail page


  - Add "Add Audio" option to folder add menu
  - Implement audio source selection dialog (Record/Select File)
  - Connect audio recording and file selection to MediaService
  - _Requirements: 2.1, 2.2_
- [x] 5. Implement digital diary system data models




- [ ] 5. Implement digital diary system data models

- [x] 5.1 Create DiaryEntryModel class


  - Implement data model extending MediaFileModel with diary-specific fields
  - Add support for rich text content and media attachments
  - Implement serialization methods (toMap/fromDoc) for Firestore integration
  - _Requirements: 3.9_

- [x] 5.2 Create DiaryMediaAttachment model

  - Implement attachment model for embedded media in diary entries
  - Add support for different media types with positioning and captions
  - Implement proper serialization for Firestore storage
  - _Requirements: 3.8_

- [x] 5.3 Extend MediaService for diary entries


  - Add createDiaryEntry method for saving diary entries to Firestore
  - Implement updateDiaryEntry method for editing existing entries
  - Add diary-specific media attachment handling
  - _Requirements: 3.9_
- [x] 6. Build digital diary editor interface




- [ ] 6. Build digital diary editor interface

- [x] 6.1 Create DiaryEditorPage widget


  - Implement comprehensive diary creation interface with title and content fields
  - Add rich text editing capabilities for diary content
  - Implement floating action button for media insertion options
  - Add auto-save functionality and proper state management
  - _Requirements: 3.2, 3.3, 3.4_

- [x] 6.2 Implement media insertion in diary editor


  - Add image insertion using enhanced camera/gallery selection
  - Add video insertion with camera/gallery options
  - Add audio insertion with record/select file options
  - Implement inline media preview and management within editor
  - _Requirements: 3.5, 3.6, 3.7, 3.8_

- [x] 6.3 Create DiaryViewerPage widget


  - Implement formatted display of diary title and content
  - Add embedded media rendering with proper aspect ratios
  - Implement audio playback controls for embedded audio
  - Add edit functionality with proper permission checking
  - _Requirements: 3.10_

- [x] 6.4 Add diary entry option to folder detail page


  - Add "Add Diary Doc" option to folder add menu
  - Implement navigation to DiaryEditorPage for new diary creation
  - Integrate diary entries into folder content grid display
  - _Requirements: 3.1, 3.2_

- [x] 7. Implement unified media management





- [x] 7.1 Update folder content display for all media types


  - Extend folder detail page grid to display diary entries alongside other media
  - Implement proper thumbnails and previews for diary entries
  - Add diary entry tap handling to open DiaryViewerPage
  - _Requirements: 5.1, 5.4_

- [x] 7.2 Extend multi-select functionality for diary entries


  - Add diary entry support to MultiSelectManager
  - Implement batch operations (delete) for diary entries
  - Update BatchActionBar to handle mixed media selections including diaries
  - _Requirements: 5.2, 5.3_

- [x] 7.3 Update MediaCardWidget for diary entries


  - Add diary entry display support to existing MediaCardWidget
  - Implement proper diary entry thumbnails and metadata display
  - Add diary-specific context menu options (edit, delete)
  - _Requirements: 5.1_
- [ ] 8. Implement comprehensive error handling and validation




- [ ] 8. Implement comprehensive error handling and validation

- [x] 8.1 Add permission handling throughout the application


  - Implement permission requests for camera, microphone, and storage access
  - Add user-friendly permission denied dialogs with guidance
  - Implement graceful fallbacks when permissions are denied
  - _Requirements: 1.2, 2.3, 4.2_

- [x] 8.2 Implement media validation and error recovery


  - Add file type and size validation for all media types
  - Implement error recovery for failed uploads with retry mechanisms
  - Add user feedback for upload progress and completion
  - _Requirements: 2.7, 6.7_

- [x] 8.3 Add comprehensive error handling for audio operations


  - Implement error handling for recording failures with clear user feedback
  - Add recovery mechanisms for interrupted recordings
  - Implement proper cleanup of temporary audio files
  - _Requirements: 2.4, 2.5, 6.6_


- [ ] 9. Add accessibility support and testing





- [x] 9.1 Implement accessibility features for new interfaces


  - Add proper semantic labels and hints for all new UI components
  - Implement screen reader support for audio recording interface
  - Add keyboard navigation support for diary editor
  - Test with TalkBack/VoiceOver for full accessibility compliance
  - _Requirements: All requirements (accessibility is cross-cutting)_

- [x] 9.2 Add comprehensive testing coverage


  - Write unit tests for AudioRecordingService, DiaryEntryModel, and enhanced MediaService
  - Create widget tests for all new UI components
  - Implement integration tests for complete media capture and diary creation flows
  - Add accessibility testing for all new features
  - _Requirements: All requirements (testing validates implementation)_