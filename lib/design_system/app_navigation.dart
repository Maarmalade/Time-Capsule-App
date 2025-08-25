import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// AppNavigation defines the complete navigation styling system for the Time Capsule app
/// following Material 3 principles with professional bottom navigation design
class AppNavigation {
  // Private constructor to prevent instantiation
  AppNavigation._();

  /// Bottom navigation bar theme configuration with professional styling
  static BottomNavigationBarThemeData get bottomNavTheme => BottomNavigationBarThemeData(
        // Background and elevation
        backgroundColor: AppColors.surfacePrimary,
        elevation: AppSpacing.elevation2,
        
        // Item styling
        type: BottomNavigationBarType.fixed,
        
        // Selected item styling
        selectedItemColor: AppColors.primaryAccent,
        selectedLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.primaryAccent,
          fontWeight: AppTypography.medium,
        ),
        selectedIconTheme: const IconThemeData(
          color: AppColors.primaryAccent,
          size: AppSpacing.iconSize,
        ),
        
        // Unselected item styling
        unselectedItemColor: AppColors.textTertiary,
        unselectedLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textTertiary,
          fontWeight: AppTypography.regular,
        ),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textTertiary,
          size: AppSpacing.iconSize,
        ),
        
        // Layout and spacing
        showSelectedLabels: true,
        showUnselectedLabels: true,
        enableFeedback: true,
        
        // Landscape mode configuration
        landscapeLayout: BottomNavigationBarLandscapeLayout.spread,
      );

  /// Navigation rail theme for larger screens
  static NavigationRailThemeData get navigationRailTheme => NavigationRailThemeData(
        backgroundColor: AppColors.surfacePrimary,
        elevation: AppSpacing.elevation1,
        
        // Selected destination styling
        selectedIconTheme: const IconThemeData(
          color: AppColors.primaryAccent,
          size: AppSpacing.iconSize,
        ),
        selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.primaryAccent,
          fontWeight: AppTypography.medium,
        ),
        
        // Unselected destination styling
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textTertiary,
          size: AppSpacing.iconSize,
        ),
        unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textTertiary,
          fontWeight: AppTypography.regular,
        ),
        
        // Layout configuration
        groupAlignment: -1.0, // Align to top
        labelType: NavigationRailLabelType.all,
        useIndicator: true,
        indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.12),
      );

  /// Navigation drawer theme for menu navigation
  static DrawerThemeData get drawerTheme => DrawerThemeData(
        backgroundColor: AppColors.surfacePrimary,
        elevation: AppSpacing.elevation4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSpacing.radiusMd),
            bottomRight: Radius.circular(AppSpacing.radiusMd),
          ),
        ),
        width: AppSpacing.sidebarWidth,
      );

  /// Tab bar theme for tabbed navigation
  static TabBarTheme get tabBarTheme => TabBarTheme(
        labelColor: AppColors.primaryAccent,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: AppTypography.medium,
        ),
        unselectedLabelStyle: AppTypography.labelLarge.copyWith(
          fontWeight: AppTypography.regular,
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
      );

  /// Creates a bottom navigation bar with consistent styling
  static Widget createBottomNavigationBar({
    required int currentIndex,
    required ValueChanged<int> onTap,
    required List<BottomNavigationBarItem> items,
  }) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: items,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surfacePrimary,
      selectedItemColor: AppColors.primaryAccent,
      unselectedItemColor: AppColors.textTertiary,
      selectedLabelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.primaryAccent,
        fontWeight: AppTypography.medium,
      ),
      unselectedLabelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.textTertiary,
        fontWeight: AppTypography.regular,
      ),
      elevation: AppSpacing.elevation2,
      enableFeedback: true,
    );
  }

  /// Creates a navigation rail for larger screens
  static Widget createNavigationRail({
    required int selectedIndex,
    required ValueChanged<int> onDestinationSelected,
    required List<NavigationRailDestination> destinations,
    bool extended = false,
    Widget? leading,
    Widget? trailing,
  }) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      extended: extended,
      leading: leading,
      trailing: trailing,
      backgroundColor: AppColors.surfacePrimary,
      elevation: AppSpacing.elevation1,
      selectedIconTheme: const IconThemeData(
        color: AppColors.primaryAccent,
        size: AppSpacing.iconSize,
      ),
      unselectedIconTheme: const IconThemeData(
        color: AppColors.textTertiary,
        size: AppSpacing.iconSize,
      ),
      selectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.primaryAccent,
        fontWeight: AppTypography.medium,
      ),
      unselectedLabelTextStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.textTertiary,
        fontWeight: AppTypography.regular,
      ),
      groupAlignment: -1.0,
      labelType: NavigationRailLabelType.all,
      useIndicator: true,
      indicatorColor: AppColors.primaryAccent.withValues(alpha: 0.12),
    );
  }

  /// Creates a navigation drawer with consistent styling
  static Widget createNavigationDrawer({
    required List<Widget> children,
    Widget? header,
  }) {
    return Drawer(
      backgroundColor: AppColors.surfacePrimary,
      elevation: AppSpacing.elevation4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppSpacing.radiusMd),
          bottomRight: Radius.circular(AppSpacing.radiusMd),
        ),
      ),
      width: AppSpacing.sidebarWidth,
      child: Column(
        children: [
          if (header != null) header,
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a drawer list tile with consistent styling
  static Widget createDrawerListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.primaryAccent : AppColors.textTertiary,
        size: AppSpacing.iconSize,
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: selected ? AppColors.primaryAccent : AppColors.textPrimary,
          fontWeight: selected ? AppTypography.medium : AppTypography.regular,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : null,
      onTap: onTap,
      selected: selected,
      selectedTileColor: AppColors.primaryAccent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      minLeadingWidth: AppSpacing.minTouchTarget,
      minVerticalPadding: AppSpacing.xs,
    );
  }

  /// Creates a tab bar with consistent styling
  static Widget createTabBar({
    required List<Tab> tabs,
    TabController? controller,
    bool isScrollable = false,
  }) {
    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
      labelColor: AppColors.primaryAccent,
      unselectedLabelColor: AppColors.textTertiary,
      labelStyle: AppTypography.labelLarge.copyWith(
        fontWeight: AppTypography.medium,
      ),
      unselectedLabelStyle: AppTypography.labelLarge.copyWith(
        fontWeight: AppTypography.regular,
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
    );
  }

  /// Creates a bottom navigation bar item with consistent styling
  static BottomNavigationBarItem createBottomNavItem({
    required IconData icon,
    required String label,
    IconData? activeIcon,
    String? tooltip,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: AppSpacing.iconSize,
      ),
      activeIcon: activeIcon != null
          ? Icon(
              activeIcon,
              size: AppSpacing.iconSize,
            )
          : null,
      label: label,
      tooltip: tooltip ?? label,
    );
  }

  /// Creates a navigation rail destination with consistent styling
  static NavigationRailDestination createNavRailDestination({
    required IconData icon,
    required String label,
    IconData? selectedIcon,
  }) {
    return NavigationRailDestination(
      icon: Icon(
        icon,
        size: AppSpacing.iconSize,
      ),
      selectedIcon: selectedIcon != null
          ? Icon(
              selectedIcon,
              size: AppSpacing.iconSize,
            )
          : null,
      label: Text(label),
    );
  }

  /// Helper method to determine if navigation rail should be used based on screen width
  static bool shouldUseNavigationRail(double screenWidth) {
    return screenWidth >= 1200; // Desktop breakpoint
  }

  /// Helper method to determine if bottom navigation should be extended based on screen width
  static bool shouldExtendBottomNav(double screenWidth) {
    return screenWidth >= 600; // Tablet breakpoint
  }

  /// Helper method to get responsive navigation type based on screen width
  static NavigationType getNavigationType(double screenWidth) {
    if (screenWidth >= 1200) {
      return NavigationType.rail;
    } else if (screenWidth >= 600) {
      return NavigationType.bottomExtended;
    } else {
      return NavigationType.bottom;
    }
  }
}

/// Enum for different navigation types based on screen size
enum NavigationType {
  bottom,
  bottomExtended,
  rail,
}