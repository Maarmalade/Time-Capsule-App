# Requirements Document

## Introduction

This feature enhances the Time Capsule app's media capture capabilities and introduces a digital diary system. The enhancements include camera integration for direct photo capture, comprehensive audio recording and file selection, and a new digital diary template that allows users to create rich, multimedia diary entries within memory folders.

## Requirements

### Requirement 1: Enhanced Image Capture Options

**User Story:** As a user, I want to choose between camera and gallery when adding images, so that I can capture moments directly or select existing photos.

#### Acceptance Criteria

1. WHEN user taps "Add Image" THEN system SHALL display a choice between "Camera" and "Gallery" options
2. WHEN user selects "Camera" THEN system SHALL open the device camera interface
3. WHEN user takes a photo with camera THEN system SHALL display a confirmation screen with the captured image
4. WHEN user is on photo confirmation screen THEN system SHALL provide "X" button to retake photo and "✓" button to confirm and use the photo
5. WHEN user taps "X" on confirmation screen THEN system SHALL return to camera interface for retaking
6. WHEN user taps "✓" on confirmation screen THEN system SHALL process and save the image to the current folder
7. WHEN user selects "Gallery" THEN system SHALL open the device gallery picker as currently implemented

### Requirement 2: Comprehensive Audio Support

**User Story:** As a user, I want to record audio directly or select audio files from my device, so that I can add voice notes and audio memories to my folders.

#### Acceptance Criteria

1. WHEN user is in a memory folder THEN system SHALL provide "Add Audio" option in the add menu
2. WHEN user taps "Add Audio" THEN system SHALL display choice between "Record Audio" and "Select Audio File" options
3. WHEN user selects "Record Audio" THEN system SHALL open audio recording interface with record/stop/play controls
4. WHEN user is recording audio THEN system SHALL display recording duration and visual recording indicator
5. WHEN user completes audio recording THEN system SHALL provide options to play back, re-record, or save the recording
6. WHEN user selects "Select Audio File" THEN system SHALL open device file picker filtered for audio files
7. WHEN audio file is selected or recorded THEN system SHALL save it to the current folder with appropriate metadata

### Requirement 3: Digital Diary Template System

**User Story:** As a user, I want to create structured diary entries with multimedia content, so that I can document my experiences in a rich, organized format.

#### Acceptance Criteria

1. WHEN user is in a memory folder THEN system SHALL provide "Add Diary Doc" option in the add menu
2. WHEN user selects "Add Diary Doc" THEN system SHALL open digital diary creation interface
3. WHEN user is creating diary entry THEN system SHALL provide editable title field with placeholder "Diary Entry Title"
4. WHEN user is creating diary entry THEN system SHALL provide rich text content area for writing
5. WHEN user is writing diary content THEN system SHALL provide options to add images, videos, and audio files
6. WHEN user taps image option in diary THEN system SHALL provide camera/gallery choice as specified in Requirement 1
7. WHEN user taps audio option in diary THEN system SHALL provide record/select choice as specified in Requirement 2
8. WHEN user adds media to diary THEN system SHALL embed media inline with content or as attachments
9. WHEN user saves diary entry THEN system SHALL create a structured diary document in the current folder
10. WHEN user views saved diary entry THEN system SHALL display title, content, and embedded media in organized layout

### Requirement 4: Enhanced Video Capture Options

**User Story:** As a user, I want to choose between camera and gallery when adding videos, so that I can record moments directly or select existing videos.

#### Acceptance Criteria

1. WHEN user taps "Add Video" THEN system SHALL display choice between "Camera" and "Gallery" options
2. WHEN user selects "Camera" for video THEN system SHALL open device camera in video recording mode
3. WHEN user records video with camera THEN system SHALL provide standard video recording controls
4. WHEN user completes video recording THEN system SHALL provide preview and confirmation options
5. WHEN user selects "Gallery" for video THEN system SHALL open device gallery picker for video files as currently implemented

### Requirement 5: Unified Media Management

**User Story:** As a user, I want all media types (images, videos, audio, diary entries) to be consistently managed within folders, so that I have a unified experience across all content types.

#### Acceptance Criteria

1. WHEN user views folder contents THEN system SHALL display all media types (images, videos, audio, diary entries) in unified grid
2. WHEN user long-presses any media item THEN system SHALL enable multi-select mode for batch operations
3. WHEN user performs batch operations THEN system SHALL support all media types including diary entries
4. WHEN user taps on diary entry THEN system SHALL open diary viewer with full content and embedded media
5. WHEN user edits diary entry THEN system SHALL maintain all original functionality for title, content, and media editing

### Requirement 6: Audio Recording Interface Enhancement

**User Story:** As a user, I want an intuitive audio recording interface, so that I can easily create voice notes and audio memories.

#### Acceptance Criteria

1. WHEN audio recording interface opens THEN system SHALL display large record button, duration timer, and waveform visualization
2. WHEN user starts recording THEN system SHALL show visual feedback with animated recording indicator
3. WHEN user is recording THEN system SHALL display real-time duration and provide pause/resume functionality
4. WHEN recording is paused THEN system SHALL maintain recorded content and allow resuming
5. WHEN user stops recording THEN system SHALL provide playback controls to review the recording
6. WHEN user reviews recording THEN system SHALL offer options to save, re-record, or cancel
7. IF recording exceeds maximum duration THEN system SHALL automatically stop and notify user