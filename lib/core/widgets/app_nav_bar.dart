import 'dart:ui';

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
///
/// Uses a floating, blurred pill container so the nav reads as an ambient
/// control layer instead of a fixed system bar.
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

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.60),
              ),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              height: 80,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              indicatorColor: colorScheme.secondaryContainer,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: destinations
                  .map(
                    (AppNavDestination destination) => NavigationDestination(
                      icon: IconTheme(
                        data: const IconThemeData(size: 24),
                        child: destination.icon,
                      ),
                      selectedIcon: IconTheme(
                        data: const IconThemeData(size: 24),
                        child: destination.selectedIcon,
                      ),
                      label: destination.label,
                      tooltip: destination.label,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}
