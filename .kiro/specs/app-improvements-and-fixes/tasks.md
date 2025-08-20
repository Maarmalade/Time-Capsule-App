# Implementation Plan

- [x] 1. Enhance ScheduledMessage model for media support





  - Extend ScheduledMessage model to include imageUrls field for multiple image support
  - Add validation methods for media content (hasMedia(), getAllMediaUrls())
  - Update fromFirestore() and toFirestore() methods to handle new image fields
  - Modify copyWith() method to include imageUrls parameter
  - _Requirements: 1.1, 1.3, 1.6_
-

- [x] 2. Implement media upload functionality in ScheduledMessageService




  - Add uploadMessageMedia() method to handle multiple image uploads to Firebase Storage
  - Create createScheduledMessageWithMedia() method that combines text, images, and video
  - Implement proper file validation for image types and sizes
  - Add error handling for media upload failures with retry mechanisms
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 3. Improve scheduled message time validation





  - Update validateScheduledTime() method to allow scheduling within same hour (minimum 1 minute future)
  - Fix timezone handling in time validation logic
  - Add proper error messages for invalid scheduling times
  - Update createScheduledMessage() to use enhanced validation
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_
-

- [x] 4. Fix scheduled message status synchronization




  - Update Cloud Function to properly set deliveredAt timestamp when status changes to delivered
  - Modify getReceivedMessages() to show consistent status across sender and recipient views
  - Fix status display inconsistencies in UI components
  - Ensure status updates propagate to all relevant UI screens
  - _Requirements: 1.4, 1.5_

- [x] 5. Create MediaAttachmentWidget for scheduled messages





  - Build widget for selecting multiple images and single video for scheduled messages
  - Implement image preview functionality with remove capability
  - Add video thumbnail preview with play indicator
  - Include file size and type validation feedback
  - _Requirements: 1.1, 1.2_
-

- [x] 6. Update ScheduledMessageCard to display media and accurate status




  - Modify card to show image thumbnails in a horizontal scroll view
  - Add video preview with play button overlay
  - Update status display to show consistent information (pending/delivered)
  - Remove any unnecessary UI elements like resume/play icons
  - _Requirements: 1.5, 3.1, 3.2_

- [x] 7. Enhance CreateScheduledMessagePage with media selection





  - Add media selection buttons for images and video
  - Integrate MediaAttachmentWidget into the message creation flow
  - Update form validation to handle media attachments
  - Implement progress indicators for media upload during message creation
  - _Requirements: 1.1, 1.2, 1.6_
-

- [x] 8. Remove unnecessary UI elements from scheduled messages




  - Remove resume/play icon rectangles from scheduled messages main page
  - Clean up ScheduledMessageCard to show only relevant information
  - Simplify scheduled message item interactions to essential actions only
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 9. Implement shared folder notification system





  - Create SharedFolderNotification model with proper Firestore serialization
  - Add notifyContributorAdded() method to FolderService
  - Implement notification creation when users are added as contributors
  - Create notification display system for users to see folder invitations
  - _Requirements: 4.1, 4.2_
-

- [x] 10. Fix shared folder access and real-time updates








  - Modify streamUserAccessibleFolders() to include folders where user is contributor
  - Update folder list queries to show shared folders immediately when access is granted
  - Implement real-time updates for folder access changes
  - Fix contributor access validation in folder viewing logic
  - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6_
-

- [x] 11. Add contributor management features for folder owners




- [ ] 11. Add contributor management features for folder owners


  - Implement getFolderContributors() method to retrieve contributor list
  - Create removeContributor() method with proper access validation
  - Build contributor management UI for folder owners
  - Add confirmation dialogs for contributor removal
  - Send notifications when contributors are removed

  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

-

- [ ] 12. Remove lock folder functionality






  - Remove isLocked and lockedAt fields from FolderModel usage in UI

  - Update folder optio

ns menus to exclude lock folder functionality
  - Clean up any lock-related UI components and logic
  - _Requirements: 5.6_



- [x] 13. Simplify friend interaction dialog





  - Update friend action dialog t
o show only "Shared Folders" and "Remove Friend" options
  - Remove "Send Message" functionality from friend interactions
  - Implement navigation to Share

dFoldersPage when "Shared Folders" is selected
  --_Requirements: 6.1, 6.4, 6.5_





- [ ] 14. Create SharedFoldersPage for friend interactions


  - Build new page to display folders shared between current user and selected friend

  - Implement getSharedFoldersBetweenUsers() query method

  - Add navigation from friend actions to this shared folders view
  - Allow users to access and interact with shared folder content from this page



  - _Requirements: 6.2, 6.3, 6.6_



- [ ] 15. Enhance ProfilePictureService with global state management


  - Add static profile picture cache with Map<String, String?> structur
e


  - Implement StreamController for broadcasting profile picture updates
  - Create clearCacheForUser() method for user switching scenarios
  - Add updateProfilePicture

Globally() method for consistent updates
  - _Requirements: 7.1, 7.8_

- [ ] 16. Fix profile picture consistency across all screens







  - Update ProfilePictureWidget to listen to global profil

e picture updates
  - Implement automatic cache clearing when users switch a
ccounts
  - Ensure profile pictures update immediately across home, profile, and memory screens
  - Add proper error handling and default avatar fallbacks




  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.6_
- [ ] 17. Implement profile picture caching and refresh logic









- [ ] 17. Implement profile picture caching and refresh logic

  - Add intelligent caching with expiration policies in ProfilePictureService
  - Implement background refresh of expired cache entries
  - Create efficient memory management for profile picture cache


  - Add cache invalidation when profile pictures are updated
  - _Requirements: 7.5, 7.7_

- [ ] 18. Update Cloud Function for proper message delivery status


  - Modify message delivery Cloud Function to set proper deliveredAt timestamp
  - Ensure status updates from 'pending' to 'delivered' are atomic
  - Add error handling for delivery status update failures
  - Test Cloud Function triggers for scheduled message processing
  - _Requirements: 1.4, 1.5, 2.6_

- [ ] 19. Add comprehensive error handling and validation



  - Implement proper error messages for media upload failures
  - Add validation feedback for scheduled message time selection
  - Create fallback mechanisms for shared folder access issues
  - Add error handling for profile picture loading and caching failures
  - _Requirements: 1.2, 2.3, 4.6, 7.6_

- [x] 20. Fix Firebase Storage configuration and App Check integration





  - Configure Firebase App Check to eliminate placeholder token warnings
  - Update Firebase Storage security rules to properly handle video file access
  - Implement proper authentication for video file downloads
  - Add error handling for App Check token failures



  - _Requirements: 8.3, 8.4, 8.8_

- [ ] 21. Implement video playback functionality


  - Create VideoPlayerWidget with proper error handling and loading states



  - Add video thumbnail generation for preview purposes
  - Implement proper video player lifecycle management
  - Add support for common video formats (mp4, mov, etc.)
  - _Requirements: 8.1, 8.2, 8.7_

- [ ] 22. Fix video upload state management


  - Properly handle Firebase Storage upload state transitions
  - Add progress indicators for video upload process
  - Implement retry mechanisms for failed video uploads
  - Fix upload task cancellation and state management issues
  - _Requirements: 8.4, 8.6_

- [ ] 23. Test and validate all implemented features


  - Test scheduled message creation with multiple images and video
  - Verify video playback functionality across all features (scheduled messages, digital diary, memory albums)
  - Test shared folder contributor notifications and access
  - Test friend interaction navigation to shared folders
  - Validate profile picture consistency when switching users
  - Ensure all UI elements are properly updated and unnecessary elements removed
  - _Requirements: All requirements validation_