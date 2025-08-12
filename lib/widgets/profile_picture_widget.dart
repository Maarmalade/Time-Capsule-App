import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_profile.dart';

class ProfilePictureWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderColor = borderColor ?? theme.primaryColor;

    Widget avatar;

    if (userProfile?.profilePictureUrl != null && userProfile!.profilePictureUrl!.isNotEmpty) {
      // Show profile picture with caching and loading states
      avatar = CachedNetworkImage(
        imageUrl: userProfile!.profilePictureUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: size / 2,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: size / 2,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          child: SizedBox(
            width: size * 0.5,
            height: size * 0.5,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(theme),
      );
    } else {
      // Show default avatar with initials or icon
      avatar = _buildDefaultAvatar(theme);
    }

    if (showBorder) {
      return Container(
        width: size + (borderWidth * 2),
        height: size + (borderWidth * 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: effectiveBorderColor,
            width: borderWidth,
          ),
        ),
        child: Center(child: avatar),
      );
    }

    return avatar;
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.primary,
      child: _buildAvatarContent(theme),
    );
  }

  Widget _buildAvatarContent(ThemeData theme) {
    if (userProfile?.username != null && userProfile!.username.isNotEmpty) {
      // Show initials based on username
      final initials = _getInitials(userProfile!.username);
      return Text(
        initials,
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // Show default person icon
      return Icon(
        Icons.person,
        color: theme.colorScheme.onPrimary,
        size: size * 0.6,
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