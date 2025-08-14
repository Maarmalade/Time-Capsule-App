# Firestore Security Rules Testing

This document explains how to test the Firestore security rules for the Time Capsule social features.

## Overview

The security rules are implemented in `firestore.rules` and cover:
- Friend request management
- Friendship relationships
- Shared and public folder access control
- Scheduled message privacy
- User profile access

## Testing Approaches

### 1. Unit Tests (Dart)

Location: `test/firestore_security_rules_test.dart`

These tests simulate the security rule logic using mock data and validate the business logic that would be enforced by the actual security rules.

**Run the tests:**
```bash
flutter test test/firestore_security_rules_test.dart
```

### 2. Integration Tests (JavaScript)

Location: `test/firestore-security-rules.test.js`

These tests use the Firebase Rules Unit Testing library to test the actual security rules against a Firebase emulator.

**Prerequisites:**
```bash
# Install Node.js dependencies
cd test
npm install

# Install Firebase CLI (if not already installed)
npm install -g firebase-tools
```

**Run the tests:**
```bash
# Start Firebase emulator
firebase emulators:start --only firestore

# In another terminal, run the tests
cd test
npm test
```

## Security Rule Coverage

### Friend Management
- ✅ Users can only read their own sent/received friend requests
- ✅ Users can only create friend requests where they are the sender
- ✅ Users can only accept/decline requests sent to them
- ✅ Self friend requests are prevented
- ✅ Users can read and delete their own friendships
- ✅ Direct friendship creation is prevented (must go through Cloud Functions)

### Folder Access Control
- ✅ Owners can create, read, update, and delete their folders
- ✅ Contributors can read and modify shared folders (if not locked)
- ✅ Anyone can read public folders
- ✅ Private folders are only accessible to owners and contributors
- ✅ Locked folders prevent contributor modifications
- ✅ Media subcollections inherit parent folder permissions

### Scheduled Messages
- ✅ Only sender and recipient can read messages
- ✅ Users can only create messages where they are the sender
- ✅ Messages cannot be scheduled for past dates
- ✅ Text content must be non-empty and under 5KB
- ✅ Senders can cancel their own pending messages
- ✅ Non-participants cannot access messages

### User Profiles
- ✅ All authenticated users can read user profiles (for search)
- ✅ Users can only update their own profiles
- ✅ Username format validation (3-30 chars, alphanumeric + underscore)

## Firebase Emulator Configuration

The `firebase.json` file includes emulator configuration:

```json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "functions": { "port": 5001 },
    "ui": { "enabled": true, "port": 4000 }
  }
}
```

**Access the Emulator UI:**
- Open http://localhost:4000 when emulators are running
- View Firestore data, test authentication, and monitor functions

## Deployment

**Deploy security rules to Firebase:**
```bash
firebase deploy --only firestore:rules
```

**Deploy indexes:**
```bash
firebase deploy --only firestore:indexes
```

## Performance Considerations

The `firestore.indexes.json` file includes optimized indexes for:
- Friend request queries by sender/receiver and status
- Friendship lookups by user IDs
- Public folder discovery
- Scheduled message queries by status and date
- User search by username

## Security Best Practices

1. **Principle of Least Privilege**: Users can only access data they own or are explicitly granted access to
2. **Input Validation**: All user inputs are validated for format and size
3. **Audit Trail**: Friend requests maintain status history
4. **Rate Limiting**: Consider implementing client-side rate limiting for friend requests
5. **Data Privacy**: Sensitive message content should be encrypted before storage

## Troubleshooting

**Common Issues:**

1. **Permission Denied Errors**: Check that the user is authenticated and has proper access rights
2. **Index Errors**: Ensure all required indexes are deployed
3. **Validation Failures**: Verify that all required fields are present and properly formatted
4. **Emulator Connection Issues**: Ensure emulators are running and ports are not blocked

**Debug Tips:**

1. Use the Firebase Emulator UI to inspect data and rules
2. Add console.log statements in security rules for debugging
3. Test with different user contexts to verify access controls
4. Use the Rules Playground in Firebase Console for quick testing