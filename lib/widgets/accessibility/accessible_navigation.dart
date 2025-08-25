import 'package:flutter/material.dart';
import '../../utils/accessibility_utils.dart';

/// Accessibility-enhanced bottom navigation bar
class AccessibleBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AccessibleBottomNavigationBarItem> items;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  const AccessibleBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Bottom navigation',
      hint: 'Navigate between main sections of the app',
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        type: BottomNavigationBarType.fixed,
        items: items.map((item) => _buildNavigationBarItem(item)).toList(),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(AccessibleBottomNavigationBarItem item) {
    return BottomNavigationBarItem(
      icon: Semantics(
        label: AccessibilityUtils.createSemanticLabel(
          label: item.label,
          hint: item.hint,
          isSelected: items.indexOf(item) == currentIndex,
        ),
        button: true,
        selected: items.indexOf(item) == currentIndex,
        child: ExcludeSemantics(child: item.icon),
      ),
      activeIcon: item.activeIcon != null
          ? Semantics(
              label: AccessibilityUtils.createSemanticLabel(
                label: item.label,
                hint: item.hint,
                isSelected: true,
              ),
              button: true,
              selected: true,
              child: ExcludeSemantics(child: item.activeIcon!),
            )
          : null,
      label: '', // Remove label since we handle semantics above
      tooltip: item.label,
    );
  }
}

/// Accessibility-enhanced bottom navigation bar item
class AccessibleBottomNavigationBarItem {
  final Widget icon;
  final Widget? activeIcon;
  final String label;
  final String? hint;

  const AccessibleBottomNavigationBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.hint,
  });
}

/// Accessibility-enhanced app bar
class AccessibleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Color? backgroundColor;
  final double elevation;

  const AccessibleAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      label: 'App bar, $title${subtitle != null ? ', $subtitle' : ''}',
      child: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(title),
            ),
            if (subtitle != null)
              Semantics(
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
        actions: actions?.map((action) {
          // Ensure actions have proper semantics
          return Semantics(
            container: true,
            child: action,
          );
        }).toList(),
        leading: leading,
        automaticallyImplyLeading: automaticallyImplyLeading,
        backgroundColor: backgroundColor,
        elevation: elevation,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Accessibility-enhanced tab bar
class AccessibleTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<AccessibleTab> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;

  const AccessibleTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Tab navigation',
      hint: 'Swipe left or right to navigate between tabs',
      child: TabBar(
        controller: controller,
        onTap: onTap,
        indicatorColor: indicatorColor,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        tabs: tabs.map((tab) => _buildTab(tab)).toList(),
      ),
    );
  }

  Widget _buildTab(AccessibleTab tab) {
    return Semantics(
      label: AccessibilityUtils.createSemanticLabel(
        label: tab.text,
        hint: tab.hint,
        isButton: true,
      ),
      button: true,
      child: Tab(
        text: tab.text,
        icon: tab.icon,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);
}

/// Accessibility-enhanced tab
class AccessibleTab {
  final String text;
  final Widget? icon;
  final String? hint;

  const AccessibleTab({
    required this.text,
    this.icon,
    this.hint,
  });
}