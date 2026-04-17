import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Elevation levels for [AppCard].
enum AppCardElevation {
  /// Flat card — no shadow. Relies on border to define bounds.
  flat,

  /// Tonal card with the same treatment as [flat].
  raised,
}

/// App-standard tonal card surface.
///
/// Uses Material 3 tonal surfaces and an outline border instead of shadows.
///
/// ```dart
/// AppCard(
///   child: ListTile(title: Text('Hello')),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// Creates an [AppCard].
  const AppCard({
    super.key,
    required this.child,
    this.elevation = AppCardElevation.raised,
    this.padding,
    this.onTap,
  });

  /// The widget displayed inside the card.
  final Widget child;

  /// Shadow depth of the card.
  final AppCardElevation elevation;

  /// Padding applied around [child]. Defaults to `EdgeInsets.all(16)`.
  final EdgeInsetsGeometry? padding;

  /// Optional tap handler — adds ink splash when provided.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.all(AppSpacing.md);
    final BorderRadius borderRadius = BorderRadius.circular(AppRadius.md);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}
