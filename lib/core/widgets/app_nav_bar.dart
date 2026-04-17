import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Single destination item used by [AppNavBar].
class AppNavDestination {
  /// Creates a destination model.
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Icon displayed when destination is inactive.
  final Widget icon;

  /// Icon displayed when destination is selected.
  final Widget selectedIcon;

  /// Destination label.
  final String label;
}

/// App-standard bottom navigation wrapper.
class AppNavBar extends StatelessWidget {
  /// Creates an [AppNavBar].
  const AppNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  /// Current destination index.
  final int selectedIndex;

  /// Callback invoked when a destination is selected.
  final ValueChanged<int> onDestinationSelected;

  /// Navigation destinations.
  final List<AppNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 80,
      child: NavigationBar(
        selectedIndex: selectedIndex,
        height: 80,
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations
            .map(
              (AppNavDestination destination) => NavigationDestination(
                icon: IconTheme(
                  data: const IconThemeData(size: AppSpacing.lg),
                  child: destination.icon,
                ),
                selectedIcon: IconTheme(
                  data: const IconThemeData(size: AppSpacing.lg),
                  child: destination.selectedIcon,
                ),
                label: destination.label,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
