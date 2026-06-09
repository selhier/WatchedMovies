import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/notifications/data/notification_repository.dart';

/// Adaptive app shell with bottom navigation (mobile) or side navigation rail (web/tablet)
class AppShell extends ConsumerStatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', path: '/'),
    _NavItem(icon: Icons.explore_rounded, label: 'Discover', path: '/search'),
    _NavItem(icon: Icons.list_alt_rounded, label: 'My Lists', path: '/lists'),
    _NavItem(icon: Icons.people_rounded, label: 'Community', path: '/community'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _navItems.length; i++) {
      if (location == _navItems[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;
    final index = _currentIndex(context);

    if (isWide) {
      // Side navigation rail for web/tablet
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: index,
              onDestinationSelected: (i) =>
                  context.go(_navItems[i].path),
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.primarySurface,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: const Icon(
                    Icons.movie_filter_rounded,
                    size: 20,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.icon, color: AppColors.primary),
                      label: Text(
                        item.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Container(width: 1, color: AppColors.divider),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // Bottom navigation for mobile
    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context.go(_navItems[i].path),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySurface,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _navItems
              .map(
                (item) => NavigationDestination(
                  icon: Icon(item.icon, color: AppColors.textTertiary),
                  selectedIcon: Icon(item.icon, color: AppColors.primary),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}
