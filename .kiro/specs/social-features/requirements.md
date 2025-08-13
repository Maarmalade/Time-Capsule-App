# Requirements Document

## Introduction

This document outlines the requirements for implementing social features in the Time Capsule Flutter application. The features enable users to connect with friends, share memory folders collaboratively, schedule messages for future delivery, and create public memory folders. These features leverage Firebase Firestore, Storage, Authentication, and Cloud Functions to provide a comprehensive social experience while maintaining security and privacy.

## Requirements

### Requirement 1: Add Friend by Username

**User Story:** As a user, I want to search for other users by username and send friend requests, so that I can connect with people I know and build my social network within the app.

#### Acceptance Criteria

1. WHEN a user enters a username in the search field THEN the system SHALL display matching users with their profile information
2. WHEN a user selects another user from search results THEN the system SHALL provide an option to send a friend request
3. WHEN a user sends a friend request THEN the system SHALL store the request in Firestore with pending status
4. WHEN a friend request is sent THEN the system SHALL prevent duplicate requests to the same user
5. IF a user searches for their own username THEN the system SHALL exclude their own profile from results
6. WHEN a friend request is created THEN the system SHALL include sender ID, receiver ID, timestamp, and status fields

### Requirement 2: Accept Friend Request

**User Story:** As a user, I want to view and respond to incoming friend requests, so that I can control who becomes part of my friend network.

#### Acceptance Criteria

1. WHEN a user has pending friend requests THEN the system SHALL display them in a dedicated requests section
2. WHEN a user views a friend request THEN the system SHALL show the sender's username and profile information
3. WHEN a user accepts a friend request THEN the system SHALL add both users to each other's friend lists
4. WHEN a user declines a friend request THEN the system SHALL remove the request without creating a friendship
5. WHEN a friend request is accepted THEN the system SHALL update the request status to accepted
6. WHEN a friendship is created THEN the system SHALL store bidirectional friend relationships in Firestore
7. IF a user accepts a friend request THEN the system SHALL send a notification to the original sender

### Requirement 3: Shared Memory Folder

**User Story:** As a user, I want to invite friends to contribute content to a memory folder, so that we can collaboratively create shared memories together.

#### Acceptance Criteria

1. WHEN a user creates a memory folder THEN the system SHALL provide an option to make it shared
2. WHEN a user makes a folder shared THEN the system SHALL allow them to invite friends from their friend list
3. WHEN friends are invited to a shared folder THEN the system SHALL store contributor permissions in Firestore
4. WHEN a contributor accesses a shared folder THEN the system SHALL allow them to upload messages, photos, and videos

7. IF a user is not a contributor THEN the system SHALL deny access to the shared folder
8. WHEN a contributor uploads content THEN the system SHALL track the contributor's identity with the content

### Requirement 4: Scheduled Message to Future Friends or Myself

**User Story:** As a user, I want to schedule diary-style messages with text and video to be delivered to myself or friends at a future date, so that I can create meaningful time-delayed communications.

#### Acceptance Criteria

1. WHEN a user creates a scheduled message THEN the system SHALL allow them to select themselves or a friend as the recipient
2. WHEN creating a scheduled message THEN the system SHALL require a future delivery date and time
3. WHEN composing a scheduled message THEN the system SHALL support both text content and video attachment
4. WHEN a scheduled message is created THEN the system SHALL store it in Firestore with pending delivery status
5. WHEN the scheduled delivery time arrives THEN the Cloud Function SHALL update the message status to delivered
6. WHEN a message is delivered THEN the system SHALL make it visible to the recipient in their messages section
7. IF the delivery date is in the past THEN the system SHALL reject the scheduled message creation
8. WHEN a scheduled message is delivered THEN the system SHALL send a push notification to the recipient
