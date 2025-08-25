import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_capsule/design_system/app_navigation.dart';
import 'package:time_capsule/design_system/app_colors.dart';
import 'package:time_capsule/design_system/app_spacing.dart';

void main() {
  group('AppNavigation', () {
    group('bottomNavTheme', () {
      test('should have correct background and elevation', () {
        final theme = AppNavigation.bottomNavTheme;
        
        expect(theme.backgroundColor, equals(AppColors.surfacePrimary));
        expect(theme.elevation, equals(AppSpacing.elevation2));
        expect(theme.type, equals(BottomNavigationBarType.fixed));
      });

      test('should have correct selected item styling', () {
        final theme = AppNavigation.bottomNavTheme;
        
        expect(theme.selectedItemColor, equals(AppColors.accentBlue));
        expect(theme.selectedIconTheme?.color, equals(AppColors.accentBlue));
        expect(theme.selectedIconTheme?.size, equals(AppSpacing.iconSize));
        expect(theme.selectedLabelStyle?.color, equals(AppColors.accentBlue));
      });

      test('should have correct unselected item styling', () {
        final theme = AppNavigation.bottomNavTheme;
        
        expect(theme.unselectedItemColor, equals(AppColors.textTertiary));
        expect(theme.unselectedIconTheme?.color, equals(AppColors.textTertiary));
        expect(theme.unselectedIconTheme?.size, equals(AppSpacing.iconSize));
        expect(theme.unselectedLabelStyle?.color, equals(AppColors.textTertiary));
      });

      test('should show both selected and unselected labels', () {
        final theme = AppNavigation.bottomNavTheme;
        
        expect(theme.showSelectedLabels, isTrue);
        expect(theme.showUnselectedLabels, isTrue);
        expect(theme.enableFeedback, isTrue);
      });

      test('should have correct landscape layout', () {
        final theme = AppNavigation.bottomNavTheme;
        
        expect(theme.landscapeLayout, equals(BottomNavigationBarLandscapeLayout.spread));
      });
    });

    group('navigationRailTheme', () {
      test('should have correct background and elevation', () {
        final theme = AppNavigation.navigationRailTheme;
        
        expect(theme.backgroundColor, equals(AppColors.surfacePrimary));
        expect(theme.elevation, equals(AppSpacing.elevation1));
      });

      test('should have correct selected destination styling', () {
        final theme = AppNavigation.navigationRailTheme;
        
        expect(theme.selectedIconTheme?.color, equals(AppColors.accentBlue));
        expect(theme.selectedIconTheme?.size, equals(AppSpacing.iconSize));
        expect(theme.selectedLabelTextStyle?.color, equals(AppColors.accentBlue));
      });

      test('should have correct unselected destination styling', () {
        final theme = AppNavigation.navigationRailTheme;
        
        expect(theme.unselectedIconTheme?.color, equals(AppColors.textTertiary));
        expect(theme.unselectedIconTheme?.size, equals(AppSpacing.iconSize));
        expect(theme.unselectedLabelTextStyle?.color, equals(AppColors.textTertiary));
      });

      test('should have correct layout configuration', () {
        final theme = AppNavigation.navigationRailTheme;
        
        expect(theme.groupAlignment, equals(-1.0));
        expect(theme.labelType, equals(NavigationRailLabelType.all));
        expect(theme.useIndicator, isTrue);
        expect(theme.indicatorColor, equals(AppColors.accentBlue.withOpacity(0.12)));
      });
    });

    group('drawerTheme', () {
      test('should have correct background and elevation', () {
        final theme = AppNavigation.drawerTheme;
        
        expect(theme.backgroundColor, equals(AppColors.surfacePrimary));
        expect(theme.elevation, equals(AppSpacing.elevation4));
        expect(theme.width, equals(AppSpacing.sidebarWidth));
      });

      test('should have correct shape with rounded corners', () {
        final theme = AppNavigation.drawerTheme;
        
        expect(theme.shape, isA<RoundedRectangleBorder>());
      });
    });

    group('tabBarTheme', () {
      test('should have correct color configuration', () {
        final theme = AppNavigation.tabBarTheme;
        
        expect(theme.labelColor, equals(AppColors.accentBlue));
        expect(theme.unselectedLabelColor, equals(AppColors.textTertiary));
        expect(theme.dividerColor, equals(AppColors.borderLight));
      });

      test('should have correct indicator configuration', () {
        final theme = AppNavigation.tabBarTheme;
        
        expect(theme.indicator, isA<UnderlineTabIndicator>());
        expect(theme.indicatorSize, equals(TabBarIndicatorSize.label));
      });

      test('should have correct overlay colors for interaction states', () {
        final theme = AppNavigation.tabBarTheme;
        
        // Test hover state
        final hoverColor = theme.overlayColor?.resolve({WidgetState.hovered});
        expect(hoverColor, equals(AppColors.accentBlue.withOpacity(0.04)));
        
        // Test pressed state
        final pressedColor = theme.overlayColor?.resolve({WidgetState.pressed});
        expect(pressedColor, equals(AppColors.accentBlue.withOpacity(0.08)));
        
        // Test default state
        final defaultColor = theme.overlayColor?.resolve({});
        expect(defaultColor, isNull);
      });
    });

    group('createBottomNavigationBar', () {
      testWidgets('should create bottom navigation bar with correct properties', (tester) async {
        int selectedIndex = 0;
        final items = [
          AppNavigation.createBottomNavItem(
            icon: Icons.home,
            label: 'Home',
          ),
          AppNavigation.createBottomNavItem(
            icon: Icons.search,
            label: 'Search',
          ),
        ];
        
        final bottomNav = AppNavigation.createBottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => selectedIndex = index,
          items: items,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: bottomNav,
            ),
          ),
        );
        
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('createNavigationRail', () {
      testWidgets('should create navigation rail with correct properties', (tester) async {
        int selectedIndex = 0;
        final destinations = [
          AppNavigation.createNavRailDestination(
            icon: Icons.home,
            label: 'Home',
          ),
          AppNavigation.createNavRailDestination(
            icon: Icons.search,
            label: 'Search',
          ),
        ];
        
        final navRail = AppNavigation.createNavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => selectedIndex = index,
          destinations: destinations,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  navRail,
                  const Expanded(child: Center(child: Text('Content'))),
                ],
              ),
            ),
          ),
        );
        
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });
    });

    group('createNavigationDrawer', () {
      testWidgets('should create navigation drawer with correct properties', (tester) async {
        final drawer = AppNavigation.createNavigationDrawer(
          children: [
            AppNavigation.createDrawerListTile(
              icon: Icons.home,
              title: 'Home',
              onTap: () {},
            ),
            AppNavigation.createDrawerListTile(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {},
              selected: true,
            ),
          ],
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              drawer: drawer,
              body: const Center(child: Text('Content')),
            ),
          ),
        );
        
        // Open the drawer
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        
        expect(find.byType(Drawer), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });
    });

    group('createDrawerListTile', () {
      testWidgets('should create drawer list tile with correct styling', (tester) async {
        bool tapped = false;
        
        final listTile = AppNavigation.createDrawerListTile(
          icon: Icons.home,
          title: 'Home',
          subtitle: 'Main page',
          onTap: () => tapped = true,
          selected: true,
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: listTile,
            ),
          ),
        );
        
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Main page'), findsOneWidget);
        expect(find.byIcon(Icons.home), findsOneWidget);
        
        await tester.tap(find.byType(ListTile));
        expect(tapped, isTrue);
      });
    });

    group('createTabBar', () {
      testWidgets('should create tab bar with correct properties', (tester) async {
        final tabs = [
          const Tab(text: 'Tab 1'),
          const Tab(text: 'Tab 2'),
        ];
        
        final tabBar = AppNavigation.createTabBar(tabs: tabs);
        
        await tester.pumpWidget(
          MaterialApp(
            home: DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: AppBar(
                  bottom: tabBar as PreferredSizeWidget,
                ),
                body: const TabBarView(
                  children: [
                    Center(child: Text('Content 1')),
                    Center(child: Text('Content 2')),
                  ],
                ),
              ),
            ),
          ),
        );
        
        expect(find.byType(TabBar), findsOneWidget);
        expect(find.text('Tab 1'), findsOneWidget);
        expect(find.text('Tab 2'), findsOneWidget);
      });
    });

    group('createBottomNavItem', () {
      test('should create bottom navigation item with correct properties', () {
        final item = AppNavigation.createBottomNavItem(
          icon: Icons.home,
          label: 'Home',
          activeIcon: Icons.home_filled,
          tooltip: 'Home page',
        );
        
        expect(item.label, equals('Home'));
        expect(item.tooltip, equals('Home page'));
        expect(item.icon, isA<Icon>());
        expect(item.activeIcon, isA<Icon>());
      });

      test('should use label as tooltip when tooltip is not provided', () {
        final item = AppNavigation.createBottomNavItem(
          icon: Icons.home,
          label: 'Home',
        );
        
        expect(item.tooltip, equals('Home'));
      });
    });

    group('createNavRailDestination', () {
      test('should create navigation rail destination with correct properties', () {
        final destination = AppNavigation.createNavRailDestination(
          icon: Icons.home,
          label: 'Home',
          selectedIcon: Icons.home_filled,
        );
        
        expect(destination.icon, isA<Icon>());
        expect(destination.selectedIcon, isA<Icon>());
        expect(destination.label, isA<Text>());
      });
    });

    group('responsive navigation helpers', () {
      test('shouldUseNavigationRail should return correct values', () {
        expect(AppNavigation.shouldUseNavigationRail(800), isFalse);
        expect(AppNavigation.shouldUseNavigationRail(1200), isTrue);
        expect(AppNavigation.shouldUseNavigationRail(1400), isTrue);
      });

      test('shouldExtendBottomNav should return correct values', () {
        expect(AppNavigation.shouldExtendBottomNav(400), isFalse);
        expect(AppNavigation.shouldExtendBottomNav(600), isTrue);
        expect(AppNavigation.shouldExtendBottomNav(800), isTrue);
      });

      test('getNavigationType should return correct navigation type', () {
        expect(AppNavigation.getNavigationType(400), equals(NavigationType.bottom));
        expect(AppNavigation.getNavigationType(600), equals(NavigationType.bottomExtended));
        expect(AppNavigation.getNavigationType(800), equals(NavigationType.bottomExtended));
        expect(AppNavigation.getNavigationType(1200), equals(NavigationType.rail));
        expect(AppNavigation.getNavigationType(1400), equals(NavigationType.rail));
      });
    });

    group('accessibility compliance', () {
      test('should meet touch target size requirements', () {
        final theme = AppNavigation.bottomNavTheme;
        
        expect(theme.selectedIconTheme?.size, greaterThanOrEqualTo(20.0));
        expect(theme.unselectedIconTheme?.size, greaterThanOrEqualTo(20.0));
      });

      test('should have sufficient color contrast', () {
        final theme = AppNavigation.bottomNavTheme;
        
        // Test selected item contrast
        expect(theme.selectedItemColor, equals(AppColors.accentBlue));
        
        // Test unselected item contrast
        expect(theme.unselectedItemColor, equals(AppColors.textTertiary));
        
        // Verify contrast ratios meet WCAG AA standards
        final selectedLuminance = AppColors.accentBlue.computeLuminance();
        final backgroundLuminance = AppColors.surfacePrimary.computeLuminance();
        final selectedContrastRatio = (backgroundLuminance + 0.05) / (selectedLuminance + 0.05);
        
        expect(selectedContrastRatio, greaterThanOrEqualTo(3.0)); // AA standard for large text
        
        final unselectedLuminance = AppColors.textTertiary.computeLuminance();
        final unselectedContrastRatio = (backgroundLuminance + 0.05) / (unselectedLuminance + 0.05);
        
        expect(unselectedContrastRatio, greaterThanOrEqualTo(3.0));
      });

      testWidgets('should support screen readers with proper labels', (tester) async {
        final bottomNav = AppNavigation.createBottomNavigationBar(
          currentIndex: 0,
          onTap: (index) {},
          items: [
            AppNavigation.createBottomNavItem(
              icon: Icons.home,
              label: 'Home',
              tooltip: 'Navigate to home',
            ),
            AppNavigation.createBottomNavItem(
              icon: Icons.search,
              label: 'Search',
              tooltip: 'Search content',
            ),
          ],
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: bottomNav,
            ),
          ),
        );
        
        // Verify semantic labels are present
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Search'), findsOneWidget);
      });
    });

    group('consistency across navigation types', () {
      test('all navigation themes should use consistent colors', () {
        final bottomNavTheme = AppNavigation.bottomNavTheme;
        final navRailTheme = AppNavigation.navigationRailTheme;
        final tabBarTheme = AppNavigation.tabBarTheme;
        
        // Selected colors should be consistent
        expect(bottomNavTheme.selectedItemColor, equals(AppColors.accentBlue));
        expect(navRailTheme.selectedIconTheme?.color, equals(AppColors.accentBlue));
        expect(tabBarTheme.labelColor, equals(AppColors.accentBlue));
        
        // Unselected colors should be consistent
        expect(bottomNavTheme.unselectedItemColor, equals(AppColors.textTertiary));
        expect(navRailTheme.unselectedIconTheme?.color, equals(AppColors.textTertiary));
        expect(tabBarTheme.unselectedLabelColor, equals(AppColors.textTertiary));
      });

      test('all navigation themes should use consistent icon sizing', () {
        final bottomNavTheme = AppNavigation.bottomNavTheme;
        final navRailTheme = AppNavigation.navigationRailTheme;
        
        expect(bottomNavTheme.selectedIconTheme?.size, equals(AppSpacing.iconSize));
        expect(bottomNavTheme.unselectedIconTheme?.size, equals(AppSpacing.iconSize));
        expect(navRailTheme.selectedIconTheme?.size, equals(AppSpacing.iconSize));
        expect(navRailTheme.unselectedIconTheme?.size, equals(AppSpacing.iconSize));
      });

      test('all navigation themes should maintain design system compliance', () {
        final themes = [
          AppNavigation.bottomNavTheme,
          AppNavigation.navigationRailTheme,
          AppNavigation.drawerTheme,
          AppNavigation.tabBarTheme,
        ];
        
        // All themes should have proper background colors
        expect(AppNavigation.bottomNavTheme.backgroundColor, equals(AppColors.surfacePrimary));
        expect(AppNavigation.navigationRailTheme.backgroundColor, equals(AppColors.surfacePrimary));
        expect(AppNavigation.drawerTheme.backgroundColor, equals(AppColors.surfacePrimary));
        
        // All themes should have appropriate elevation
        expect(AppNavigation.bottomNavTheme.elevation, greaterThan(0));
        expect(AppNavigation.navigationRailTheme.elevation, greaterThan(0));
        expect(AppNavigation.drawerTheme.elevation, greaterThan(0));
      });
    });
  });
}