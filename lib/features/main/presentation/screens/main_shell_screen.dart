import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';

/// Persistent application shell with bottom navigation.
class MainShellScreen extends StatelessWidget {
  /// Creates the main shell screen.
  const MainShellScreen({super.key, required this.navigationShell});

  /// Navigation shell supplied by go_router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: AppStrings.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}
