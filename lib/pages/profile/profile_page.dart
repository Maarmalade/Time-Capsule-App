import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_profile.dart';
import '../../services/user_profile_service.dart';
import '../../services/profile_picture_service.dart';
import '../../services/auth_state_manager.dart';
import '../../widgets/profile_picture_widget.dart';
import '../../constants/route_constants.dart';
import '../../design_system/app_colors.dart';
import '../../utils/error_handler.dart';
import '../auth/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileService _userProfileService = UserProfileService();
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await _userProfileService.getCurrentUserProfile();

      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfilePicture() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingImage = true;
        _errorMessage = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      await _userProfileService.updateProfilePicture(
        user.uid,
        File(image.path),
      );

      // Clear the profile cache to force refresh throughout the app
      _profilePictureService.clearCache();

      // Reload profile to get updated picture URL
      await _loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile picture: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show logout confirmation dialog
  Future<void> _showLogoutConfirmation() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancel logout',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            Semantics(
              button: true,
              label: 'Confirm logout',
              hint: 'This will sign you out of your account',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.errorRed,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _performLogout();
    }
  }

  /// Perform logout using AuthStateManager
  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Signing out...'),
                ],
              ),
            );
          },
        );
      }

      // Use AuthStateManager to sign out with retry logic
      await ErrorHandler.retryOperation(
        () => AuthStateManager.signOut(),
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Force navigation to login page after successful logout
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // Close loading dialog if it's showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Handle authentication-specific errors
      if (mounted) {
        ErrorHandler.showErrorDialog(
          context,
          title: 'Logout Failed',
          message: ErrorHandler.getAuthErrorMessage(e),
          onRetry: _performLogout,
        );
      }
    } catch (e) {
      // Close loading dialog if it's showing
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Handle generic errors
      if (mounted) {
        if (ErrorHandler.isNetworkError(e)) {
          ErrorHandler.showErrorSnackBar(
            context,
            message: 'Network error during logout. Please check your connection and try again.',
            onRetry: _performLogout,
          );
        } else {
          ErrorHandler.showErrorDialog(
            context,
            title: 'Logout Error',
            message: 'An unexpected error occurred during logout. Please try again.',
            onRetry: _performLogout,
          );
        }
      }
      
      ErrorHandler.logError('ProfilePage._performLogout', e);
    }
  }

  Widget _buildProfilePicture() {
    const double size = 120;

    return Stack(
      children: [
        ProfilePictureWidget(
          userProfile: _userProfile,
          size: size,
          showBorder: true,
          borderColor: Colors.grey.shade300,
          borderWidth: 2,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: IconButton(
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: _isUploadingImage ? null : _updateProfilePicture,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage ?? 'Failed to load profile',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        // Back Navigation
                        Row(
                          children: [
                            Semantics(
                              button: true,
                              label: 'Go back to home page',
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back),
                                iconSize: 28,
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Page Title
                        const Text(
                          'User Profile',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Profile Picture Section
                        _buildProfilePicture(),
                        const SizedBox(height: 24),

                        // Username
                        Text(
                          '@${_userProfile!.username}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Email
                        Text(
                          _userProfile!.email,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 32),

                        // Profile Actions
                        _buildProfileActions(),

                        // Error Message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red.shade600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileActions() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.edit,
          title: 'Change Username',
          subtitle: 'Update your display name',
          onTap: () async {
            final result = await Navigator.of(context).pushNamed(
              Routes.editUsername,
              arguments: {'currentUsername': _userProfile!.username},
            );

            // If username was updated, reload the profile
            if (result == true) {
              await _loadUserProfile();
            }
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.lock,
          title: 'Change Password',
          subtitle: 'Update your account password',
          onTap: () {
            Navigator.of(context).pushNamed(Routes.changePassword);
          },
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.photo_camera,
          title: 'Change Profile Picture',
          subtitle: 'Update your profile photo',
          onTap: _updateProfilePicture,
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: _showLogoutConfirmation,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? AppColors.errorRed : Theme.of(context).primaryColor;
    final titleColor = isDestructive ? AppColors.errorRed : null;
    final backgroundColor = isDestructive 
        ? AppColors.errorRedLight 
        : Theme.of(context).primaryColor.withValues(alpha: 0.1);

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      hint: isDestructive ? 'This action will sign you out of your account' : null,
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title, 
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: Icon(
            Icons.arrow_forward_ios, 
            size: 16,
            color: isDestructive ? AppColors.errorRed : null,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
