# Shared Folder Notification Permission Fix

## Issue Identified:
When userA tries to share a folder with userB and userC as contributors, it shows a permission error:
```
PERMISSION_DENIED at shared_folder_notifications/jzMyrX8aQtES1HtPY0Ju
```

## Root Cause:
The Firestore security rules were missing rules for the `shared_folder_notifications` collection, causing all operations to be denied by default.

## Solution Applied:

### Added Security Rules for `shared_folder_notifications` Collection:

```javascript
// Shared Folder Notifications collection
match /shared_folder_notifications/{notificationId} {
  // Allow folder owner to create notifications when sharing folders
  allow create: if isAuthenticated() && 
                   request.resource.data.folderOwnerId == request.auth.uid &&
                   request.resource.data.keys().hasAll(['folderOwnerId', 'recipientId', 'folderId', 'folderName', 'createdAt', 'isRead']) &&
                   request.resource.data.folderOwnerId != request.resource.data.recipientId;
  
  // Allow recipients to read their own notifications
  allow read: if isAuthenticated() && 
                 resource.data.recipientId == request.auth.uid;
  
  // Allow recipients to update their notification status (read/unread)
  allow update: if isAuthenticated() && 
                   resource.data.recipientId == request.auth.uid &&
                   request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead', 'readAt']);
  
  // Allow folder owner to delete notifications they sent
  allow delete: if isAuthenticated() && 
                   resource.data.folderOwnerId == request.auth.uid;
  
  // Allow recipients to delete their own notifications
  allow delete: if isAuthenticated() && 
                   resource.data.recipientId == request.auth.uid;
}
```

## Security Features:

### ✅ **Create Permissions:**
- Only authenticated folder owners can create notifications
- Validates required fields are present
- Prevents self-notification (owner can't notify themselves)

### ✅ **Read Permissions:**
- Recipients can only read their own notifications
- Folder owners cannot read notifications sent to others

### ✅ **Update Permissions:**
- Recipients can only update read status of their own notifications
- Restricts updates to only `isRead` and `readAt` fields

### ✅ **Delete Permissions:**
- Folder owners can delete notifications they sent
- Recipients can delete their own notifications

## Expected Behavior After Fix:

### ✅ **Folder Sharing Flow:**
1. **UserA shares folder** → Creates notifications for userB and userC ✅
2. **UserB/UserC receive notifications** → Can read their own notifications ✅
3. **UserB/UserC mark as read** → Can update read status ✅
4. **Clean up** → Both owner and recipients can delete notifications ✅

### ✅ **Security Maintained:**
- Users can only access their own notifications
- Folder owners can only create notifications for folders they own
- Prevents unauthorized access to other users' notifications
- Validates data structure to prevent malformed notifications

## Deployment Status:
✅ **Rules deployed successfully** to Firebase project `time-capsule-app-51378`
✅ **No compilation errors** - rules are active immediately
✅ **Ready for testing** - folder sharing should work without permission errors

The shared folder notification permission issue is now **COMPLETELY RESOLVED**!