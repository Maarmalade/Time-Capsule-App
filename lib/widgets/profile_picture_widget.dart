import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_profile.dart';
import '../services/profile_picture_service.dart';
import '../utils/comprehensive_error_handler.dart';

class ProfilePictureWidget extends StatefulWidget {
  final UserProfile? userProfile;
  final double size;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const ProfilePictureWidget({
    super.key,
    required this.userProfile,
    this.size = 40.0,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  late StreamSubscription<Map<String, String?>> _profilePictureSubscription;
  String? _currentProfilePictureUrl;

  @override
  void initState() {
    super.initState();
    _initializeProfilePicture();
    _subscribeToProfilePictureUpdates();
  }

  @override
  void didUpdateWidget(ProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile?.id != widget.userProfile?.id) {
      _initializeProfilePicture();
    }
  }

  @override
  void dispose() {
    _profilePictureSubscription.cancel();
    super.dispose();
  }

  void _initializeProfilePicture() {
    if (widget.userProfile?.id != null) {
      // Check global cache first
      final cachedUrl = ProfilePictureService.getProfilePictureFromCache(widget.userProfile!.id);
      if (cachedUrl != null) {
        _currentProfilePictureUrl = cachedUrl;
      } else {
        // Fall back to userProfile's URL
        _currentProfilePictureUrl = widget.userProfile?.profilePictureUrl;
      }
    } else {
      _currentProfilePictureUrl = widget.userProfile?.profilePictureUrl;
    }
  }

  void _subscribeToProfilePictureUpdates() {
    _profilePictureSubscription = ProfilePictureService.profilePictureUpdates.listen((cacheMap) {
      if (widget.userProfile?.id != null && mounted) {
        final newUrl = cacheMap[widget.userProfile!.id];
        if (newUrl != _currentProfilePictureUrl) {
          setState(() {
            _currentProfilePictureUrl = newUrl;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = widget.borderColor ?? theme.primaryColor;

    Widget avatar;

    try {
      if (_currentProfilePictureUrl != null && _currentProfilePictureUrl!.isNotEmpty) {
        // Show profile picture with enhanced caching and error handling
        avatar = CachedNetworkImage(
          imageUrl: _currentProfilePictureUrl!,
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: widget.size / 2,
            backgroundImage: imageProvider,
          ),
          placeholder: (context, url) => CircleAvatar(
            radius: widget.size / 2,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: SizedBox(
              width: widget.size * 0.5,
              height: widget.size * 0.5,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            // Enhanced error handling for profile picture loading
            debugPrint('Profile picture loading error for ${widget.userProfile?.id}: ${ComprehensiveErrorHandler.getProfilePictureErrorMessage(error)}');
            
            // Try to get cached version as fallback
            if (widget.userProfile?.id != null) {
              final cachedUrl = ProfilePictureService.getProfilePictureFromCache(widget.userProfile!.id);
              if (cachedUrl != null && cachedUrl != _currentProfilePictureUrl) {
                // Try the cached URL as a fallback
                return CachedNetworkImage(
                  imageUrl: cachedUrl,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: widget.size / 2,
                    backgroundImage: imageProvider,
                  ),
                  errorWidget: (context, url, error) => _buildDefaultAvatarWithErrorIndicator(theme),
                );
              }
            }
            
            return _buildDefaultAvatarWithErrorIndicator(theme);
          },
          // Enhanced cache configuration
          cacheManager: null, // Use default cache manager
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
        );
      } else {
        // Show default avatar with initials or icon
        avatar = _buildDefaultAvatar(theme);
      }
    } catch (e) {
      // Enhanced error handling for widget-level errors
      debugPrint('Profile picture widget error for ${widget.userProfile?.id}: ${ComprehensiveErrorHandler.getProfilePictureErrorMessage(e)}');
      avatar = _buildDefaultAvatarWithErrorIndicator(theme);
    }

    if (widget.showBorder) {
      return Container(
        width: widget.size + (widget.borderWidth * 2),
        height: widget.size + (widget.borderWidth * 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveBorderColor,
            width: widget.borderWidth,
          ),
        ),
        child: Center(child: avatar),
      );
    }

    return avatar;
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: theme.colorScheme.primary,
      child: _buildAvatarContent(theme),
    );
  }

  Widget _buildDefaultAvatarWithErrorIndicator(ThemeData theme) {
    return Stack(
      children: [
        CircleAvatar(
          radius: widget.size / 2,
          backgroundColor: theme.colorScheme.primary,
          child: _buildAvatarContent(theme),
        ),
        if (widget.size > 32) // Only show error indicator on larger avatars
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: widget.size * 0.25,
              height: widget.size * 0.25,
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.error_outline,
                color: theme.colorScheme.onError,
                size: widget.size * 0.15,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarContent(ThemeData theme) {
    if (widget.userProfile?.username != null && widget.userProfile!.username.isNotEmpty) {
      // Show initials based on username
      final initials = _getInitials(widget.userProfile!.username);
      return Text(
        initials,
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // Show default person icon
      return Icon(
        Icons.person,
        color: theme.colorScheme.onPrimary,
        size: widget.size * 0.6,
      );
    }
  }

  String _getInitials(String username) {
    if (username.isEmpty) return '';
    
    // For usernames, just take the first character and make it uppercase
    // If username has underscores or numbers, try to get meaningful initials
    final parts = username.split(RegExp(r'[_\d]'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    
    // Otherwise just use first character
    return username[0].toUpperCase();
  }
}

/// A smaller variant for use in app bars and navigation
class ProfilePictureIcon extends StatelessWidget {
  final UserProfile? userProfile;
  final VoidCallback? onTap;

  const ProfilePictureIcon({
    super.key,
    required this.userProfile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ProfilePictureWidget(
        userProfile: userProfile,
        size: 32.0,
      ),
    );
  }
}