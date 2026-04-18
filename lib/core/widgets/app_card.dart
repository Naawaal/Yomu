import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Elevation variants for [AppCard].
///
/// Both values produce a zero-shadow tonal card. The enum is retained for
/// backward compatibility; visual distinction comes from the [AppCard.featured]
/// named constructor instead.
enum AppCardElevation {
  /// Flat card — surfaceContainerLow fill, no border.
  flat,

  /// Standard tonal card — same as [flat].
  raised,
}

/// App-standard tonal card surface.
///
/// Uses Material 3 tonal elevation (zero shadow, tonal fill) following the
/// 4-level surface hierarchy from the design system.
///
/// ```dart
/// // Standard content card (surfaceContainerLow, no border)
/// AppCard(child: ListTile(title: Text('Hello')))
///
/// // Featured / highlighted card (surfaceContainerHigh, subtle border)
/// AppCard.featured(child: HeroWidget())
/// ```
class AppCard extends StatelessWidget {
  /// Creates a standard [AppCard].
  const AppCard({
    super.key,
    required this.child,
    this.elevation = AppCardElevation.raised,
    this.padding,
    this.onTap,
  }) : _featured = false;

  /// Creates a featured [AppCard] with elevated surface and subtle border.
  ///
  /// Use for hero content, highlighted items, or emphasized containers.
  const AppCard.featured({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  }) : _featured = true,
       elevation = AppCardElevation.raised;

  /// The widget displayed inside the card.
  final Widget child;

  /// Shadow depth — retained for backward compatibility.
  final AppCardElevation elevation;

  /// Padding applied around [child]. Defaults to `EdgeInsets.all(16)`.
  final EdgeInsetsGeometry? padding;

  /// Optional tap handler — adds ink splash when provided.
  final VoidCallback? onTap;

  final bool _featured;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.all(AppSpacing.md);

    final Color fillColor = _featured
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLow;

    final double radius = _featured ? AppRadius.lg : AppRadius.md;
    final BorderRadius borderRadius = BorderRadius.circular(radius);

    final BorderSide border = _featured
        ? BorderSide(color: colorScheme.outlineVariant, width: 0.5)
        : BorderSide.none;

    return Card(
      elevation: 0,
      color: fillColor,
      shape: RoundedRectangleBorder(borderRadius: borderRadius, side: border),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(padding: effectivePadding, child: child),
      ),
    );
  }
}
