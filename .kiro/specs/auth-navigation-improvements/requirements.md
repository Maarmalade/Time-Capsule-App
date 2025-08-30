# Requirements Document

## Introduction

This document outlines the requirements for implementing persistent authentication, Firebase Cloud Messaging (FCM) integration, navigation improvements, and enhanced nostalgia reminder functionality in the Time Capsule Flutter application. These improvements focus on creating a seamless user experience with automatic login, push notifications for scheduled messages, improved navigation flow, and better handling of empty states in the nostalgia reminder feature.

## Requirements

### Requirement 1: Persistent Authentication and Auto-Login

**User Story:** As a user, I want the app to remember my login status and automatically log me in when I restart the app, so that I don't have to enter my credentials every time.

#### Acceptance Criteria

1. WHEN the app starts THEN the system SHALL check if a valid authentication token exists
2. WHEN a valid authentication token is found THEN the system SHALL automatically navigate to the HomePage without showing the LoginPage
3. WHEN no valid authentication token is found THEN the system SHALL display the LoginPage
4. WHEN an authentication token is expired or invalid THEN the system SHALL redirect the user to the LoginPage
5. WHEN a user successfully logs in THEN the system SHALL store the authentication state persistently
6. WHEN Firebase Auth state changes THEN the system SHALL update the app navigation accordingly
7. WHEN the app detects token expiration during use THEN the system SHALL gracefully redirect to login with appropriate messaging

### Requirement 2: Firebase Cloud Messaging Integration for Scheduled Messages

**User Story:** As a user, I want to receive push notifications on my device when scheduled messages are delivered to me, so that I'm immediately aware of new content.

#### Acceptance Criteria

1. WHEN a user logs in THEN the system SHALL retrieve the FCM device token and send it to the backend API
2. WHEN the FCM token is retrieved THEN the system SHALL store it in the user's Firestore document
3. WHEN a scheduled message is delivered THEN the system SHALL send a push notification to the recipient's device
4. WHEN the app is in the foreground THEN the system SHALL display an in-app notification for received messages
5. WHEN the app is in the background THEN the system SHALL show a system notification that opens the relevant content when tapped
6. WHEN a push notification is received THEN the system SHALL display a local notification using flutter_local_notifications
7. WHEN the user taps a notification THEN the system SHALL navigate to the appropriate scheduled message or content
8. WHEN FCM permissions are required THEN the system SHALL request notification permissions from the user

### Requirement 3: Homepage Navigation Improvements

**User Story:** As a user on the HomePage, I want clean navigation without unnecessary back buttons and with logout functionality moved to the profile section, so that I have a more intuitive user interface.

#### Acceptance Criteria

1. WHEN displaying the HomePage THEN the system SHALL NOT show a back button in the app bar
2. WHEN a user tries to navigate back from HomePage THEN the system SHALL prevent navigation to the LoginPage
3. WHEN the HomePage is displayed THEN the system SHALL NOT show the three vertical dots menu in the app bar
4. WHEN a user accesses their profile page THEN the system SHALL display a logout option
5. WHEN a user selects logout from the profile page THEN the system SHALL sign out the user and navigate to the LoginPage
6. WHEN logout is performed THEN the system SHALL clear all stored authentication data
7. WHEN logout is performed THEN the system SHALL clear any cached user data and FCM tokens

### Requirement 4: Enhanced Nostalgia Reminder with Throwback Feature

**User Story:** As a user viewing the nostalgia reminder panel, I want to see meaningful content even when I don't have favorited diary entries, so that the feature provides value and encourages engagement.

#### Acceptance Criteria

1. WHEN the nostalgia reminder panel has no favorited diary entries to display THEN the system SHALL show "Throwback" as the panel title
2. WHEN a user clicks on the Throwback panel with no favorited entries THEN the system SHALL display the message: "There are no favourited diary entries from past years. Favourite a diary entry now so you can see it in the following years!"
3. WHEN there are favorited diary entries from previous years on the same date THEN the system SHALL display the favorited diary entry instead of the throwback message
4. WHEN displaying a favorited diary entry in nostalgia reminder THEN the system SHALL show the entry content and allow the user to view the full entry
5. WHEN the system checks for nostalgia content THEN it SHALL look for favorited diary entries from the same date in previous years
6. WHEN multiple favorited entries exist for the same date THEN the system SHALL display the most recent one or provide a way to cycle through them
7. WHEN no favorited entries exist for any past years THEN the system SHALL consistently show the throwback encouragement message
