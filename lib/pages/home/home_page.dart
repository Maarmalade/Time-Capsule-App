import 'package:flutter/material.dart';

import '../diary/digital_diary_page.dart';
import 'home_panel_grid.dart';
import '../memory_album/memory_album_page.dart';
import '../../services/diary_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_picture_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/profile_picture_widget.dart';
import '../../routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfilePictureService _profileService = ProfilePictureService();
  UserProfile? _userProfile;

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await _logout(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
        });
      }
    } catch (e) {
      // Handle error silently - profile picture is not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, Routes.profile),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ProfilePictureWidget(
                            userProfile: _userProfile,
                            size: 32.0,
                            showBorder: true,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 32),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _showLogoutConfirmation(context);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Logout', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Home Page',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: HomePanelGrid(
                  diaryService: DiaryService(),
                  navigate: (context, route, pageName) {
                    if (route == '/digital_diary') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DigitalDiaryPage()),
                      );
                    } else if (route == '/memory_album') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MemoryAlbumPage()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text(pageName),
                              leading: BackButton(),
                            ),
                            body: Center(
                              child: Text('You are now in $pageName', style: TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}