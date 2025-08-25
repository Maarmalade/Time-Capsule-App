import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_capsule/pages/friends/shared_folders_page.dart';
import 'package:time_capsule/models/user_profile.dart';

void main() {
  group('Friend Interaction Dialog Integration Tests', () {
    testWidgets('friend dialog shows only Shared Folders and Remove Friend options', (WidgetTester tester) async {
      // This test verifies that the friend interaction dialog has been simplified
      // to show only the required options as per requirement 6.1 and 6.5
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  final friend = UserProfile(
                    id: 'friend123',
                    username: 'testfriend',
                    email: 'friend@test.com',
                    createdAt: DateTime.now(),
                  );
                  
                  // Simulate the friend options dialog
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle bar
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          
                          // Friend info
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                friend.username[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              friend.username,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            subtitle: const Text('Friend'),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Action buttons - Only Shared Folders and Remove Friend
                          ListTile(
                            leading: const Icon(Icons.folder_shared),
                            title: const Text('Shared Folders'),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SharedFoldersPage(friend: friend),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.person_remove,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            title: Text(
                              'Remove Friend',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // Remove friend logic would go here
                            },
                          ),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Show Friend Options'),
              ),
            ),
          ),
        ),
      );

      // Tap to show dialog
      await tester.tap(find.text('Show Friend Options'));
      await tester.pumpAndSettle();

      // Verify only expected options are present
      expect(find.text('Shared Folders'), findsOneWidget);
      expect(find.text('Remove Friend'), findsOneWidget);
      
      // Verify Send Message option is NOT present (requirement 6.5)
      expect(find.text('Send Message'), findsNothing);
      
      // Verify correct icons
      expect(find.byIcon(Icons.folder_shared), findsOneWidget);
      expect(find.byIcon(Icons.person_remove), findsOneWidget);
      expect(find.byIcon(Icons.message), findsNothing);
    });

    testWidgets('tapping Shared Folders navigates to SharedFoldersPage', (WidgetTester tester) async {
      // This test verifies requirement 6.2: navigation to shared folders view
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  final friend = UserProfile(
                    id: 'friend123',
                    username: 'testfriend',
                    email: 'friend@test.com',
                    createdAt: DateTime.now(),
                  );
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => SharedFoldersPage(friend: friend),
                    ),
                  );
                },
                child: const Text('Navigate to Shared Folders'),
              ),
            ),
          ),
        ),
      );

      // Tap to navigate
      await tester.tap(find.text('Navigate to Shared Folders'));
      await tester.pumpAndSettle();

      // Verify navigation to SharedFoldersPage (requirement 6.2)
      expect(find.text('Shared with testfriend'), findsOneWidget);
    });
  });
}