# How to Test the Favorite Feature

## Quick Manual Testing Steps

### 1. Basic Favorite Toggle Test
1. **Open the app** and navigate to Digital Diary
2. **Create a new diary entry** for today's date
3. **Add some content** (text, image, or audio)
4. **Tap the star icon** in the editor - it should turn yellow
5. **Save the entry**
6. **Open the entry again** - star should still be yellow
7. **Tap the star again** - it should turn gray (unfavorited)

### 2. Nostalgia Reminder Test (Same Day)
1. **Create a diary entry** with today's date
2. **Mark it as favorite** (yellow star)
3. **Save the entry**
4. **Go to Home page** - you should see the entry in a home panel card
5. **Go to Digital Diary** - you should see it in the nostalgia section

### 3. Nostalgia Reminder Test (Previous Years)
**Option A: Change Device Date (Easiest)**
1. **Create a diary entry** and mark as favorite
2. **Go to device Settings** → Date & Time
3. **Change date to next year, same month/day**
4. **Open the app** - your entry should appear as "1 year ago"

**Option B: Create Test Data**
1. Use Firebase Console to manually create entries with past dates
2. Set `isFavorite: true` and `diaryDate` to previous years

## Visual Indicators to Check

### ✅ What Should Work:
- **Yellow star** in diary editor when favorited
- **Gray star** when not favorited
- **Yellow border** around calendar dates with favorites
- **Black border** around calendar dates with regular entries
- **Nostalgia widget** appears on Digital Diary page when favorites exist
- **Home panel card** shows favorite entry with image preview
- **"X year(s) ago"** text displays correctly

### ❌ What to Watch For:
- Star doesn't change color when tapped
- Favorite status doesn't persist after saving
- Nostalgia widget doesn't appear
- Wrong entries showing in nostalgia (other users' data)
- Calendar borders wrong colors
- App crashes when toggling favorites

## Detailed Testing Scenarios

### Scenario 1: First-Time User
```
1. Create account and login
2. Write first diary entry
3. Mark as favorite
4. Check home page (should show the entry)
5. Check digital diary (should show in nostalgia if same date)
```

### Scenario 2: Multiple Favorites
```
1. Create 3 diary entries on same date (different years)
2. Mark all as favorites
3. Check nostalgia widget shows all 3
4. Verify horizontal scrolling works
5. Tap each entry to ensure navigation works
```

### Scenario 3: Different Media Types
```
1. Create text-only favorite → Should show book icon
2. Create image favorite → Should show image preview
3. Create audio favorite → Should show audio icon with play button
4. Create video favorite → Should show video icon with play button
```

### Scenario 4: Privacy Test
```
1. Login as User A, create favorites
2. Logout and login as User B
3. User B should NOT see User A's favorites
4. Create User B's own favorites
5. Verify each user only sees their own data
```

## Automated Testing

### Run Existing Tests
```bash
# Run all tests
flutter test

# Run specific test files
flutter test test/unit/diary_entry_model_test.dart
flutter test test/unit/enhanced_media_service_test.dart
```

### Create Test Data Script
```dart
// Create this file: test_favorite_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void createTestFavorites() async {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final folderId = 'personal-diary-$userId';
  
  // Create entries for testing
  final testEntries = [
    {
      'title': 'Test Favorite 2023',
      'content': 'This is a test favorite from last year',
      'diaryDate': Timestamp.fromDate(DateTime(2023, 8, 26)),
      'isFavorite': true,
      'type': 'diary',
    },
    {
      'title': 'Test Favorite 2022', 
      'content': 'This is a test favorite from 2 years ago',
      'diaryDate': Timestamp.fromDate(DateTime(2022, 8, 26)),
      'isFavorite': true,
      'type': 'diary',
    }
  ];
  
  for (final entry in testEntries) {
    await FirebaseFirestore.instance
        .collection('folders')
        .doc(folderId)
        .collection('media')
        .add(entry);
  }
}
```

## Debugging Tips

### Check Firebase Console
1. Go to Firebase Console → Firestore Database
2. Navigate to `folders/{personal-diary-userId}/media`
3. Look for entries with `isFavorite: true`
4. Verify `diaryDate` field format

### Check App Logs
```bash
# Run app with verbose logging
flutter run --verbose

# Look for these log messages:
# - "Found X favorite entries for today"
# - "Successfully toggled favorite status"
# - Any error messages related to favorites
```

### Common Issues & Solutions

**Issue**: Star doesn't change color
- **Check**: `AppColors.favoriteYellow` is defined
- **Check**: `toggleDiaryFavorite` method is called

**Issue**: Nostalgia widget doesn't appear
- **Check**: User is authenticated
- **Check**: Favorite entries exist for same month/day
- **Check**: `getFavoriteEntriesForToday` returns data

**Issue**: Wrong user's data showing
- **Check**: `personalDiaryFolderId` uses correct user ID
- **Check**: Firebase Auth is working properly

## Quick Verification Checklist

- [ ] Can create diary entry
- [ ] Can toggle favorite (star turns yellow/gray)
- [ ] Favorite status persists after save
- [ ] Calendar shows yellow borders for favorites
- [ ] Nostalgia widget appears with favorites
- [ ] Home panel shows favorite entries
- [ ] Can navigate to full entry from nostalgia
- [ ] Different users see only their own favorites
- [ ] Audio/image/video previews work in nostalgia
- [ ] "X year(s) ago" text is accurate

## Performance Testing

### Large Dataset Test
1. Create 50+ diary entries over multiple years
2. Mark 10+ as favorites across different dates
3. Check app performance when loading nostalgia
4. Verify smooth scrolling in nostalgia widget

### Network Test
1. Test with slow internet connection
2. Verify loading states show properly
3. Check offline behavior (should show cached favorites)

This testing approach will help you verify that the favorite feature works correctly across all scenarios!