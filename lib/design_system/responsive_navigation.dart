import 'package:flutter/material.dart';
import 'app_responsive.dart';
import 'app_navigation.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// ResponsiveNavigation provides adaptive navigation that automatically
/// switches between bottom navigation, navigation rail, and drawer based on screen size
class ResponsiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<ResponsiveNavigationDestination> destinations;
  final Widget? leading;
  final Widget? trailing;
  final bool showLabels;
  final Color? backgroundColor;

  const ResponsiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.leading,
    this.trailing,
    this.showLabels = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final deviceType = AppResponsive.getDeviceType(screenWidth);
        final navigationType = AppNavigation.getNavigationType(screenWidth);

        switch (navigationType) {
          case NavigationType.rail:
            return _buildNavigationRail(context, screenWidth);
          case NavigationType.bottomExtended:
            return _buildBottomNavigation(context, screenWidth, extended: true);
          case NavigationType.bottom:
            return _buildBottomNavigation(context, screenWidth, extended: false);
        }
      },
    );
  }

  Widget _buildNavigationRail(BuildContext context, double screenWidth) {
    final isExtended = screenWidth >= AppResponsive.breakpointXXLarge;
    final railDestinations = destinations.map((dest) => 
      NavigationRailDestination(
        icon: Icon(
          dest.icon,
          size: AppResponsive.getResponsiveIconSize(screenWidth),
        ),
        selectedIcon: dest.selectedIcon != null 
          ? Icon(
              dest.selectedIcon!,
              size: AppResponsive.getResponsiveIconSize(screenWidth),
            )
          : null,
        label: Text(dest.label),
      ),
    ).toList();

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: railDestinations,
      extended: isExtended,
      leading: leading,
      trailing: trailing,
      backgroundColor: backgroundColor ?? AppColors.surfacePrimary,
      elevation: AppSpacing.elevation1,
      selectedIconTheme: IconThemeData(
        color: AppColors.primaryAccent,
        size: AppResponsive.getResponsiveIconSize(screenWidth),
      ),
      unselectedIconTheme: IconThemeData(
        color: AppColors.textTertiary,
        size: AppResponsive.getResponsiveIconSize(screenWidth),
      ),
      selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.primaryAccent,
        fontWeight: AppTypography.medium,
        fontSize: AppResponsive.getResponsiveFontSize(screenWidth, 14),
      ),
      unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.textTertiary,
        fontWeight: AppTypography.regular,
        fontSize: AppResponsive.getResponsiveFontSize(screenWidth, 14),
      ),
      groupAlignment: -1.0,
      labelType: showLabels ? NavigationRailLabelType.all : NavigationRailLabelType.none,
      useIndicator: true,
      indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.12),
      minWidth: AppResponsive.getResponsiveSpacing(screenWidth) * 4,
      minExtendedWidth: AppResponsive.getResponsiveSpacing(screenWidth) * 12,
    );
  }

  Widget _buildBottomNavigation(BuildContext context, double screenWidth, {required bool extended}) {
    final iconSize = AppResponsive.getResponsiveIconSize(screenWidth);
    final fontSize = AppResponsive.getResponsiveFontSize(screenWidth, 12);
    final height = AppResponsive.getResponsiveAppBarHeight(screenWidth);

    final bottomNavItems = destinations.map((dest) => 
      BottomNavigationBarItem(
        icon: Icon(
          dest.icon,
          size: iconSize,
        ),
        activeIcon: dest.selectedIcon != null 
          ? Icon(
              dest.selectedIcon!,
              size: iconSize,
            )
          : null,
        label: dest.label,
        tooltip: dest.tooltip ?? dest.label,
      ),
    ).toList();

    return SizedBox(
      height: height,
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onDestinationSelected,
        items: bottomNavItems,
        type: extended ? BottomNavigationBarType.fixed : BottomNavigationBarType.shifting,
        backgroundColor: backgroundColor ?? AppColors.surfacePrimary,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.primaryAccent,
          fontWeight: AppTypography.medium,
          fontSize: fontSize,
        ),
        unselectedLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textTertiary,
          fontWeight: AppTypography.regular,
          fontSize: fontSize,
        ),
        elevation: AppSpacing.elevation2,
        enableFeedback: true,
        showSelectedLabels: showLabels,
        showUnselectedLabels: showLabels && extended,
        selectedIconTheme: IconThemeData(
          size: iconSize,
          color: AppColors.primaryAccent,
        ),
        unselectedIconTheme: IconThemeData(
          size: iconSize,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

/// ResponsiveNavigationDestination represents a single navigation destination
/// that can be used across different navigation types
class ResponsiveNavigationDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final String? tooltip;

  const ResponsiveNavigationDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
  });
}

/// ResponsiveAppBar provides an app bar that adapts to different screen sizes
class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double? elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation,
    this.centerTitle = false,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsiveHeight = AppResponsive.getResponsiveAppBarHeight(screenWidth);
        final responsiveFontSize = AppResponsive.getResponsiveFontSize(screenWidth, 20);
        final responsiveIconSize = AppResponsive.getResponsiveIconSize(screenWidth);

        return AppBar(
          title: titleWidget ?? (title != null 
            ? Text(
                title!,
                style: AppTypography.headlineMedium.copyWith(
                  fontSize: responsiveFontSize,
                  color: AppColors.textPrimary,
                ),
              )
            : null),
          actions: actions?.map((action) => _wrapActionWithResponsiveSize(action, responsiveIconSize)).toList(),
          leading: leading != null ? _wrapActionWithResponsiveSize(leading!, responsiveIconSize) : null,
          automaticallyImplyLeading: automaticallyImplyLeading,
          backgroundColor: backgroundColor ?? AppColors.surfacePrimary,
          elevation: elevation ?? 0,
          centerTitle: centerTitle,
          bottom: bottom,
          toolbarHeight: responsiveHeight,
          iconTheme: IconThemeData(
            size: responsiveIconSize,
            color: AppColors.textPrimary,
          ),
          actionsIconTheme: IconThemeData(
            size: responsiveIconSize,
            color: AppColors.textPrimary,
          ),
        );
      },
    );
  }

  Widget _wrapActionWithResponsiveSize(Widget action, double iconSize) {
    if (action is IconButton) {
      return IconButton(
        onPressed: action.onPressed,
        icon: action.icon,
        iconSize: iconSize,
        tooltip: action.tooltip,
        padding: action.padding,
        constraints: action.constraints,
        style: action.style,
      );
    }
    return action;
  }

  @override
  Size get preferredSize {
    // Use a default height that will be overridden by the responsive height
    return Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
  }
}

/// ResponsiveDrawer provides a drawer that adapts to different screen sizes
class ResponsiveDrawer extends StatelessWidget {
  final List<Widget> children;
  final Widget? header;
  final Color? backgroundColor;
  final double? elevation;

  const ResponsiveDrawer({
    super.key,
    required this.children,
    this.header,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsiveWidth = AppResponsive.getResponsiveDialogWidth(screenWidth) * 0.8;
        final responsivePadding = AppResponsive.getResponsivePadding(screenWidth);

        return Drawer(
          backgroundColor: backgroundColor ?? AppColors.surfacePrimary,
          elevation: elevation ?? AppSpacing.elevation4,
          width: responsiveWidth,
          shape: RoundedRectangleBorder(
            borderRadius: AppResponsive.getResponsiveBorderRadius(screenWidth),
          ),
          child: Column(
            children: [
              if (header != null) 
                Padding(
                  padding: responsivePadding,
                  child: header!,
                ),
              Expanded(
                child: ListView(
                  padding: responsivePadding,
                  children: children,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ResponsiveDrawerListTile provides a drawer list tile that adapts to screen size
class ResponsiveDrawerListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
  final String? subtitle;

  const ResponsiveDrawerListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsiveIconSize = AppResponsive.getResponsiveIconSize(screenWidth);
        final responsiveFontSize = AppResponsive.getResponsiveFontSize(screenWidth, 16);
        final responsiveSubtitleFontSize = AppResponsive.getResponsiveFontSize(screenWidth, 14);
        final minTouchTarget = AppResponsive.getMinTouchTargetSize(screenWidth);

        return ListTile(
          leading: Icon(
            icon,
            color: selected ? AppColors.primaryAccent : AppColors.textTertiary,
            size: responsiveIconSize,
          ),
          title: Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: selected ? AppColors.primaryAccent : AppColors.textPrimary,
              fontWeight: selected ? AppTypography.medium : AppTypography.regular,
              fontSize: responsiveFontSize,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: responsiveSubtitleFontSize,
                  ),
                )
              : null,
          onTap: onTap,
          selected: selected,
          selectedTileColor: AppColors.primaryAccent.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: AppResponsive.getResponsiveBorderRadius(screenWidth),
          ),
          contentPadding: AppResponsive.getResponsivePadding(screenWidth),
          minLeadingWidth: minTouchTarget,
          minVerticalPadding: AppResponsive.getResponsiveSpacing(screenWidth) / 2,
        );
      },
    );
  }
}

/// ResponsiveTabBar provides a tab bar that adapts to different screen sizes
class ResponsiveTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Tab> tabs;
  final TabController? controller;
  final bool isScrollable;
  final ValueChanged<int>? onTap;

  const ResponsiveTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.isScrollable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final responsiveFontSize = AppResponsive.getResponsiveFontSize(screenWidth, 14);
        final shouldBeScrollable = isScrollable || AppResponsive.shouldUseTouchFriendlySizing(screenWidth);

        return TabBar(
          controller: controller,
          tabs: tabs,
          isScrollable: shouldBeScrollable,
          onTap: onTap,
          labelColor: AppColors.primaryAccent,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: AppTypography.medium,
            fontSize: responsiveFontSize,
          ),
          unselectedLabelStyle: AppTypography.labelLarge.copyWith(
            fontWeight: AppTypography.regular,
            fontSize: responsiveFontSize,
          ),
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(
              color: AppColors.primaryAccent,
              width: 2.0,
            ),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.borderLight,
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.hovered)) {
                return AppColors.primaryAccent.withValues(alpha: 0.04);
              }
              if (states.contains(WidgetState.pressed)) {
                return AppColors.primaryAccent.withValues(alpha: 0.08);
              }
              return null;
            },
          ),
          tabAlignment: shouldBeScrollable ? TabAlignment.start : TabAlignment.fill,
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);
}

/// Utility class for responsive navigation helpers
class ResponsiveNavigationUtils {
  ResponsiveNavigationUtils._();

  /// Determines if a drawer should be used instead of navigation rail
  static bool shouldUseDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return AppResponsive.getDeviceType(screenWidth) == DeviceType.mobile;
  }

  /// Gets the appropriate navigation width for the current screen size
  static double getNavigationWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final deviceType = AppResponsive.getDeviceType(screenWidth);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 0; // No persistent navigation on mobile
      case DeviceType.tablet:
        return 80; // Compact navigation rail
      case DeviceType.desktop:
        return screenWidth >= AppResponsive.breakpointXXLarge ? 256 : 80;
    }
  }

  /// Creates responsive navigation destinations from a list of items
  static List<ResponsiveNavigationDestination> createDestinations({
    required List<IconData> icons,
    required List<String> labels,
    List<IconData>? selectedIcons,
    List<String>? tooltips,
  }) {
    assert(icons.length == labels.length);
    assert(selectedIcons == null || selectedIcons.length == icons.length);
    assert(tooltips == null || tooltips.length == icons.length);

    return List.generate(icons.length, (index) => 
      ResponsiveNavigationDestination(
        icon: icons[index],
        selectedIcon: selectedIcons?[index],
        label: labels[index],
        tooltip: tooltips?[index],
      ),
    );
  }
}