import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// App-standard list tile with consistent M3 typography and color contracts.
///
/// Applies the design-system text hierarchy automatically:
/// - Title: `textTheme.titleMedium`
/// - Subtitle: `textTheme.bodySmall` + `colorScheme.onSurfaceVariant`
/// - Leading/trailing text: `textTheme.labelMedium`
/// - Leading icon color: `colorScheme.onSurfaceVariant` (unselected)
/// - Selected state: `colorScheme.secondaryContainer` tile,
///   `colorScheme.onSecondaryContainer` text + icons
///
/// No dividers between tiles — use [SizedBox] with [AppSpacing] values between
/// items instead.
///
/// ```dart
/// AppListTile(
///   leading: const Icon(Ionicons.person_outline),
///   title: const Text('Profile'),
///   subtitle: const Text('Manage your account'),
///   trailing: const Icon(Ionicons.chevron_forward_outline),
///   onTap: () {},
/// )
/// ```
class AppListTile extends StatelessWidget {
  /// Creates an [AppListTile].
  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.contentPadding,
  });

  /// Optional leading widget (typically an [Icon]).
  final Widget? leading;

  /// Primary content widget — typically a [Text].
  final Widget title;

  /// Optional secondary content widget — typically a [Text].
  final Widget? subtitle;

  /// Optional trailing widget — typically an [Icon] or [Text].
  final Widget? trailing;

  /// Whether this tile is in the selected state.
  final bool selected;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Overrides the default content padding.
  ///
  /// Defaults to `EdgeInsets.symmetric(horizontal: 16, vertical: 4)`.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final Color effectiveIconColor = selected
        ? colorScheme.onSecondaryContainer
        : colorScheme.onSurfaceVariant;

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      selected: selected,
      onTap: onTap,
      selectedTileColor: colorScheme.secondaryContainer,
      iconColor: effectiveIconColor,
      selectedColor: colorScheme.onSecondaryContainer,
      titleTextStyle: textTheme.titleMedium,
      subtitleTextStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      leadingAndTrailingTextStyle: textTheme.labelMedium,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xxs,
          ),
      minLeadingWidth: AppSpacing.lg,
      splashColor: colorScheme.primary.withValues(alpha: 0.08),
    );
  }
}
