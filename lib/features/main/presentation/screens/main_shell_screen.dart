import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/widgets.dart';

/// Persistent application shell with bottom navigation.
class MainShellScreen extends StatelessWidget {
  /// Creates the main shell screen.
  const MainShellScreen({super.key, required this.navigationShell});

  /// Navigation shell supplied by go_router.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const <AppNavDestination>[
          AppNavDestination(
            icon: Icon(Ionicons.home_outline),
            selectedIcon: Icon(Ionicons.home),
            label: AppStrings.home,
          ),
          AppNavDestination(
            icon: Icon(Ionicons.extension_puzzle_outline),
            selectedIcon: Icon(Ionicons.extension_puzzle),
            label: AppStrings.extensionsTitle,
          ),
          AppNavDestination(
            icon: Icon(Ionicons.settings_outline),
            selectedIcon: Icon(Ionicons.settings),
            label: AppStrings.settings,
          ),
        ],
      ),
    );
  }
}
