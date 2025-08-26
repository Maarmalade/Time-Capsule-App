# Firestore Diary Entry Structure

## 📍 Database Location

Diary entries are stored in Firestore using the following hierarchical structure:

```
/folders/{folderId}/media/{diaryId}
```

### Path Breakdown:
- **Collection**: `folders` (top-level collection)
- **Document**: `{folderId}` (specific folder/album ID)
- **Sub-collection**: `media` (contains all media items including diary entries)
- **Document**: `{diaryId}` (specific diary entry ID, auto-generated)

## 📋 Document Structure

Each diary entry document contains the following fields:

### Core Fields
```json
{
  "id": "auto-generated-document-id",
  "folderId": "folder-id-reference",
  "title": "My Diary Entry Title",
  "content": "The main text content of the diary entry...",
  "type": "diary",
  "createdAt": "2024-08-26T10:30:00Z",
  "lastModified": "2024-08-26T15:45:00Z",
  "diaryDate": "2024-08-26T00:00:00Z"
}
```

### Favorite Feature
```json
{
  "isFavorite": true
}
```

### Shared Folder Fields (when applicable)
```json
{
  "uploadedBy": "user-id-who-created-entry",
  "uploadedAt": "2024-08-26T10:30:00Z"
}
```

### Media Attachments
```json
{
  "attachments": [
    {
      "id": "attachment-id",
      "type": "image",
      "url": "https://firebase-storage-url/image.jpg",
      "caption": "Optional caption",
      "position": 0
    },
    {
      "id": "attachment-id-2",
      "type": "audio",
      "url": "https://firebase-storage-url/audio.m4a",
      "caption": null,
      "position": 1
    }
  ]
}
```

## 🔍 Complete Example Document

```json
{
  "id": "diary_entry_123456789",
  "folderId": "personal_diary_folder",
  "title": "My Amazing Day",
  "content": "Today was incredible! I went to the beach and saw the most beautiful sunset. The colors were absolutely stunning - oranges, pinks, and purples painting the sky. I took some photos and recorded the sound of the waves.",
  "type": "diary",
  "createdAt": {
    "_seconds": 1724668200,
    "_nanoseconds": 0
  },
  "lastModified": {
    "_seconds": 1724671800,
    "_nanoseconds": 0
  },
  "diaryDate": {
    "_seconds": 1724630400,
    "_nanoseconds": 0
  },
  "isFavorite": true,
  "uploadedBy": "user_abc123",
  "uploadedAt": {
    "_seconds": 1724668200,
    "_nanoseconds": 0
  },
  "attachments": [
    {
      "id": "img_001",
      "type": "image",
      "url": "https://firebasestorage.googleapis.com/v0/b/project/o/images%2Fsunset.jpg",
      "caption": "Beautiful sunset at the beach",
      "position": 0
    },
    {
      "id": "audio_001",
      "type": "audio",
      "url": "https://firebasestorage.googleapis.com/v0/b/project/o/audio%2Fwaves.m4a",
      "caption": "Sound of ocean waves",
      "position": 1
    }
  ]
}
```

## 🗂️ Folder Types

### Personal Diary Folder
- **Folder ID**: Usually `"personal_diary"` or user-specific ID
- **Access**: Private to the user
- **Location**: `/folders/personal_diary/media/{diaryId}`

### Shared Diary Folders
- **Folder ID**: Shared folder ID (e.g., `"family_memories_2024"`)
- **Access**: Multiple users can contribute
- **Location**: `/folders/{sharedFolderId}/media/{diaryId}`
- **Additional Fields**: `uploadedBy`, `uploadedAt`

## 🔍 Query Patterns

### Get All Diary Entries for a Folder
```dart
_firestore
  .collection('folders')
  .doc(folderId)
  .collection('media')
  .where('type', isEqualTo: 'diary')
  .orderBy('diaryDate', descending: true)
```

### Get Favorite Entries for Nostalgia Reminders
```dart
_firestore
  .collection('folders')
  .doc(folderId)
  .collection('media')
  .where('type', isEqualTo: 'diary')
  .where('isFavorite', isEqualTo: true)
```

### Get Diary Entry by ID
```dart
_firestore
  .collection('folders')
  .doc(folderId)
  .collection('media')
  .doc(diaryId)
```

## 📊 Firestore Indexes

Required composite indexes for efficient queries:

### Index 1: Basic Diary Queries
```json
{
  "collectionGroup": "media",
  "fields": [
    {"fieldPath": "type", "order": "ASCENDING"},
    {"fieldPath": "diaryDate", "order": "DESCENDING"}
  ]
}
```

### Index 2: Favorite Queries
```json
{
  "collectionGroup": "media",
  "fields": [
    {"fieldPath": "type", "order": "ASCENDING"},
    {"fieldPath": "isFavorite", "order": "ASCENDING"},
    {"fieldPath": "diaryDate", "order": "ASCENDING"}
  ]
}
```

## 🔐 Security Rules

Example Firestore security rules for diary entries:

```javascript
// Allow users to read/write their own diary entries
match /folders/{folderId}/media/{mediaId} {
  allow read, write: if request.auth != null && 
    resource.data.type == 'diary' && 
    (
      // Personal folder access
      folderId == 'personal_diary_' + request.auth.uid ||
      // Shared folder access (check folder permissions)
      exists(/databases/$(database)/documents/folders/$(folderId)) &&
      request.auth.uid in get(/databases/$(database)/documents/folders/$(folderId)).data.members
    );
}
```

## 🚀 Key Features

### Date Handling
- **`createdAt`**: When the document was first created in Firestore
- **`lastModified`**: When the document was last updated
- **`diaryDate`**: The actual date the diary entry represents (used for calendar display and nostalgia reminders)

### Favorite System
- **`isFavorite`**: Boolean flag for nostalgia reminders
- **Nostalgia Logic**: Queries entries where `isFavorite = true` and `diaryDate` matches current month/day from previous years

### Media Attachments
- **Embedded Array**: Attachments stored as array within diary document
- **Firebase Storage**: Actual media files stored in Firebase Storage
- **Position-based**: Attachments have position for content ordering

### Multi-user Support
- **Personal Folders**: Single user access
- **Shared Folders**: Multiple contributors with `uploadedBy` attribution
- **Permissions**: Folder-level access control

## 📝 Usage Examples

### Creating a Diary Entry
```dart
final diary = DiaryEntryModel(
  id: '', // Auto-generated
  folderId: 'personal_diary',
  title: 'My Day',
  content: 'Today was amazing...',
  diaryDate: Timestamp.fromDate(DateTime.now()),
  isFavorite: false,
  attachments: [],
  // ... other fields
);

final diaryId = await mediaService.createDiaryEntry(
  folderId: 'personal_diary',
  diary: diary,
  userId: currentUserId,
);
```

### Querying Favorites for Nostalgia
```dart
final favoritesStream = mediaService.getFavoriteEntriesForToday('personal_diary');
favoritesStream.listen((favorites) {
  // Display nostalgia reminders
});
```

This structure provides a flexible, scalable way to store diary entries with rich media attachments, favorite functionality, and multi-user support while maintaining efficient querying capabilities.