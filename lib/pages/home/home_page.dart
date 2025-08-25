import 'package:flutter/material.dart';

import '../diary/digital_diary_page.dart';
import 'home_panel_grid.dart';
import '../memory_album/memory_album_page.dart';
import '../../services/diary_service.dart';
import '../../services/auth_service.dart';
import '../../services/profile_picture_service.dart';
import '../../models/user_profile.dart';
import '../../widgets/profile_picture_widget.dart';
import '../../constants/route_constants.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../../design_system/app_spacing.dart';

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
          title: Text(
            'Logout',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Logout',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.errorRed,
                ),
              ),
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
            content: Text(
              'Logout failed: ${e.toString()}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primaryWhite,
              ),
            ),
            backgroundColor: AppColors.errorRed,
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
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.pageAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with navigation and profile
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      size: AppSpacing.iconSizeLarge,
                      color: AppColors.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(
                        AppSpacing.minTouchTarget,
                        AppSpacing.minTouchTarget,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            Navigator.pushNamed(context, Routes.profile),
                        child: Container(
                          padding: AppSpacing.paddingSm,
                          child: ProfilePictureWidget(
                            userProfile: _userProfile,
                            size: AppSpacing.iconSizeLarge,
                            showBorder: true,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: AppSpacing.iconSizeLarge,
                          color: AppColors.textPrimary,
                        ),
                        onSelected: (value) {
                          if (value == 'logout') {
                            _showLogoutConfirmation(context);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.logout,
                                  color: AppColors.errorRed,
                                  size: AppSpacing.iconSize,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Logout',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.errorRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              
              // Page title
              Center(
                child: Text(
                  'Home Page',
                  style: AppTypography.displayMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              
              // Main content grid
              Expanded(
                child: HomePanelGrid(
                  diaryService: DiaryService(),
                  navigate: (context, route, pageName) {
                    if (route == '/digital_diary') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DigitalDiaryPage(),
                        ),
                      );
                    } else if (route == '/memory_album') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MemoryAlbumPage()),
                      );
                    } else if (route == '/friends') {
                      Navigator.pushNamed(context, Routes.friends);
                    } else if (route == '/scheduled_messages') {
                      Navigator.pushNamed(context, Routes.scheduledMessages);
                    } else if (route == '/public_folders') {
                      Navigator.pushNamed(context, Routes.publicFolders);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(
                              title: Text(
                                pageName,
                                style: AppTypography.headlineMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            backgroundColor: AppColors.surfacePrimary,
                            body: Center(
                              child: Text(
                                'You are now in $pageName',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
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
