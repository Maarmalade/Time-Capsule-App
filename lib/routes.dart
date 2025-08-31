import 'package:flutter/material.dart';
import 'pages/auth/login.dart';
import 'pages/auth/register.dart';
import 'pages/auth/username_setup_page.dart';
import 'pages/home/home_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/edit_username_page.dart';
import 'pages/profile/change_password_page.dart';
import 'pages/friends/friends_page.dart';
import 'pages/friends/add_friend_page.dart';
import 'pages/friends/friend_requests_page.dart';
import 'pages/shared_folder/shared_folder_settings_page.dart';
import 'pages/memory_album/convert_to_shared_folder_page.dart';
import 'pages/scheduled_messages/scheduled_messages_page.dart';
import 'pages/scheduled_messages/delivered_messages_page.dart';
import 'pages/public_folders/public_folders_page.dart';
import 'models/folder_model.dart';
import 'constants/route_constants.dart';


Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
    case Routes.login:
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case Routes.register:
      return MaterialPageRoute(builder: (_) => const RegisterPage());
    case Routes.usernameSetup:
      return MaterialPageRoute(builder: (_) => const UsernameSetupPage());
    case Routes.home:
      return MaterialPageRoute(builder: (_) => const HomePage());
    case Routes.profile:
      return MaterialPageRoute(builder: (_) => const ProfilePage());
    case Routes.editUsername:
      final args = settings.arguments as Map<String, dynamic>?;
      final currentUsername = args?['currentUsername'] as String? ?? '';
      return MaterialPageRoute(
        builder: (_) => EditUsernamePage(currentUsername: currentUsername),
      );
    case Routes.changePassword:
      return MaterialPageRoute(builder: (_) => const ChangePasswordPage());

    // Social features routes
    case Routes.friends:
      return MaterialPageRoute(builder: (_) => const FriendsPage());
    case Routes.addFriend:
      return MaterialPageRoute(builder: (_) => const AddFriendPage());
    case Routes.friendRequests:
      return MaterialPageRoute(builder: (_) => const FriendRequestsPage());
    case Routes.sharedFolderSettings:
      final args = settings.arguments as Map<String, dynamic>?;
      final folderId = args?['folderId'] as String? ?? '';
      final folder = args?['folder'] as FolderModel?;
      if (folder == null) {
        // Return error page if folder is not provided
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Folder information is required')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) =>
            SharedFolderSettingsPage(folderId: folderId, folder: folder),
      );
    case Routes.convertToSharedFolder:
      final args = settings.arguments as Map<String, dynamic>?;
      final folder = args?['folder'] as FolderModel?;
      if (folder == null) {
        // Return error page if folder is not provided
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Folder information is required')),
          ),
        );
      }
      return MaterialPageRoute(
        builder: (_) => ConvertToSharedFolderPage(folder: folder),
      );
    case Routes.scheduledMessages:
      return MaterialPageRoute(builder: (_) => const ScheduledMessagesPage());
    case Routes.deliveredMessages:
      return MaterialPageRoute(builder: (_) => const DeliveredMessagesPage());
    case Routes.publicFolders:
      return MaterialPageRoute(builder: (_) => const PublicFoldersPage());


    default:
      return MaterialPageRoute(builder: (_) => const LoginPage());
  }
}
