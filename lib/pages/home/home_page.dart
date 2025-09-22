import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../diary/digital_diary_page.dart';
import 'home_panel_grid.dart';
import '../memory_album/memory_album_page.dart';
import '../../services/media_service.dart';
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
  
  // Personal diary folder ID - user-specific for privacy
  String get _personalDiaryFolderId {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');
    return 'personal-diary-$userId';
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
    return PopScope(
      canPop: false, // Prevent back navigation to login
      child: Scaffold(
        backgroundColor: AppColors.surfacePrimary,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.pageAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with only profile picture
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                    mediaService: MediaService(),
                    personalDiaryFolderId: _personalDiaryFolderId,
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
      ),
    );
  }
}
