# Requirements Document

## Introduction

This document outlines the requirements for implementing critical bug fixes and feature improvements in the Time Capsule Flutter application. The improvements focus on scheduled messaging enhancements, shared folder functionality fixes, friend interaction improvements, and profile picture consistency issues. These changes will enhance user experience and fix existing functionality gaps.

## Requirements

### Requirement 1: Enhanced Scheduled Message with Media Support

**User Story:** As a user, I want to add images or videos to my scheduled messages and have proper delivery status tracking, so that I can send rich media content at future dates with accurate status information.

#### Acceptance Criteria

1. WHEN a user creates a scheduled message THEN the system SHALL provide options to attach images or videos alongside text content
2. WHEN a user selects media for a scheduled message THEN the system SHALL validate file types and sizes before attachment
3. WHEN a scheduled message with media is created THEN the system SHALL store the media files in Firebase Storage with proper references
4. WHEN a scheduled message is delivered THEN the system SHALL update the status from "pending" to "delivered" in both sender and recipient views
5. WHEN viewing scheduled messages THEN the system SHALL display consistent status information across all user interfaces
6. WHEN a scheduled message contains media THEN the system SHALL ensure media is accessible when the message is delivered

### Requirement 2: Improved Scheduled Message Timing Validation

**User Story:** As a user, I want to schedule messages for delivery within the same hour and have proper time validation, so that I can send messages with precise timing without system errors.

#### Acceptance Criteria

1. WHEN a user selects a scheduled delivery time THEN the system SHALL validate that the time is at least 1 minute in the future
2. WHEN the current time is 1:00pm and user schedules for 1:05pm THEN the system SHALL accept and process the scheduled message
3. WHEN a user attempts to schedule a message for a past time THEN the system SHALL display a clear error message and prevent creation
4. WHEN validating scheduled time THEN the system SHALL account for the user's local timezone
5. WHEN a scheduled message is created THEN the system SHALL store the exact delivery timestamp for accurate processing
6. WHEN the delivery time arrives THEN the Cloud Function SHALL process the message within 1 minute of the scheduled time

### Requirement 3: Remove Unnecessary UI Elements from Scheduled Messages

**User Story:** As a user viewing my scheduled messages, I want a clean interface without confusing elements, so that I can focus on managing my scheduled content effectively.

#### Acceptance Criteria

1. WHEN a user views the scheduled messages main page THEN the system SHALL NOT display any resume/play icon rectangles
2. WHEN displaying scheduled message items THEN the system SHALL show only relevant information: message preview, delivery time, and status
3. WHEN a user interacts with scheduled message items THEN the system SHALL provide only necessary actions: view, edit, or delete

### Requirement 4: Fixed Shared Folder Access and Notifications

**User Story:** As a user who has been added as a contributor to a shared folder, I want to be notified and have immediate access to the folder, so that I can participate in collaborative memory creation.

#### Acceptance Criteria

1. WHEN a user is added as a contributor to a shared folder THEN the system SHALL send them a notification about the invitation
2. WHEN a user receives a shared folder invitation THEN the system SHALL display the shared folder in their folder list immediately
3. WHEN a contributor accesses a shared folder THEN the system SHALL allow them to view all existing content
4. WHEN a contributor is in a shared folder THEN the system SHALL allow them to add, edit, and delete content based on their permissions
5. WHEN a user logs into their account THEN the system SHALL display all shared folders they have access to
6. WHEN shared folder access is granted THEN the system SHALL update the user's folder list in real-time

### Requirement 5: Shared Folder Management Features

**User Story:** As the owner of a shared folder, I want to manage contributors and remove the lock folder feature, so that I can control access and have a cleaner interface.

#### Acceptance Criteria

1. WHEN a user owns a shared folder THEN the system SHALL provide an option to view and manage contributors
2. WHEN viewing contributors THEN the system SHALL display a list of all users with access to the folder
3. WHEN managing contributors THEN the system SHALL provide an option to remove contributors from the shared folder
4. WHEN a contributor is removed THEN the system SHALL immediately revoke their access to the folder
5. WHEN a contributor is removed THEN the system SHALL notify them that their access has been revoked
6. WHEN displaying folder options THEN the system SHALL NOT show any lock folder functionality
7. WHEN a contributor is removed THEN the system SHALL update the folder's contributor list in Firestore

### Requirement 6: Improved Friend Interaction Navigation

**User Story:** As a user viewing my friend's profile, I want streamlined actions that navigate to relevant features, so that I can efficiently interact with my friends' content.

#### Acceptance Criteria

1. WHEN a user clicks on a friend THEN the system SHALL display options: "Shared Folders", "Remove Friend"
2. WHEN a user selects "Shared Folders" THEN the system SHALL navigate to a view showing all folders shared between the users
3. WHEN viewing shared folders between friends THEN the system SHALL display folders where both users are contributors
4. WHEN a user selects "Remove Friend" THEN the system SHALL prompt for confirmation before removing the friendship
5. WHEN displaying friend actions THEN the system SHALL NOT show any "Send Message" option
6. WHEN navigating to shared folders THEN the system SHALL allow the user to access and interact with the shared content

### Requirement 7: Consistent Profile Picture Display

**User Story:** As a user switching between accounts, I want my profile picture to display consistently across all pages, so that I have a coherent visual identity throughout the app.

#### Acceptance Criteria

1. WHEN a user switches accounts THEN the system SHALL immediately update the profile picture in all UI components
2. WHEN displaying the home page THEN the system SHALL show the current user's correct profile picture
3. WHEN displaying the profile screen THEN the system SHALL show the current user's correct profile picture
4. WHEN displaying the memory folder screen THEN the system SHALL show the current user's correct profile picture
5. WHEN a user updates their profile picture THEN the system SHALL refresh the image across all app screens immediately
6. WHEN no profile picture is set THEN the system SHALL display a consistent default avatar across all screens
7. WHEN loading profile pictures THEN the system SHALL implement proper caching to ensure consistent display
8. WHEN switching users THEN the system SHALL clear any cached profile picture data from the previous user

### Requirement 8: Video Playback and Firebase Storage Configuration

**User Story:** As a user, I want to view videos that I have uploaded to scheduled messages, digital diary, and memory albums, so that I can properly access and play back my media content.

#### Acceptance Criteria

1. WHEN a user uploads a video to any feature THEN the system SHALL store it in Firebase Storage with proper access permissions
2. WHEN a user clicks on an uploaded video THEN the system SHALL display the video in a playable format without errors
3. WHEN Firebase Storage is accessed THEN the system SHALL handle App Check token requirements properly to avoid placeholder token warnings
4. WHEN a video is being uploaded THEN the system SHALL provide proper progress feedback and handle upload state transitions correctly
5. WHEN Firebase Storage rules are configured THEN the system SHALL allow authenticated users to read and write video files
6. WHEN a video playback fails THEN the system SHALL display a meaningful error message to the user
7. WHEN videos are stored THEN the system SHALL ensure proper file format support for common video types (mp4, mov, etc.)
8. WHEN accessing stored videos THEN the system SHALL implement proper security rules that allow legitimate access while maintaining data protection
