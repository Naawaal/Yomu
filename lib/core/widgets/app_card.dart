import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

/// Elevation levels for [AppCard].
enum AppCardElevation {
  /// Flat card — no shadow. Relies on border to define bounds.
  flat,

  /// Standard card with a subtle drop shadow.
  raised,
}

/// App-standard card surface built on Moon Design tokens.
///
/// Uses [MoonColors.gohan] as its background (the "surface" semantic
/// colour in Moon) and [MoonBorders.surfaceMd] squircle radius. Shadow
/// is sourced from [MoonShadows] when [elevation] is [AppCardElevation.raised].
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
    final MoonTheme? moon = Theme.of(context).extension<MoonTheme>();
    final Color surface = moon?.tokens.colors.gohan ?? Colors.white;
    final BorderRadiusGeometry radius =
        moon?.tokens.borders.surfaceMd ?? BorderRadius.circular(12);
    final List<BoxShadow> shadows = elevation == AppCardElevation.raised
        ? (moon?.tokens.shadows.sm ?? <BoxShadow>[])
        : <BoxShadow>[];

    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.all(16);

    final Widget content = ClipRRect(
      borderRadius: radius.resolve(Directionality.of(context)),
      child: ColoredBox(
        color: surface,
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );

    if (shadows.isEmpty && onTap == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius.resolve(Directionality.of(context)),
          color: surface,
        ),
        child: ClipRRect(
          borderRadius: radius.resolve(Directionality.of(context)),
          child: Padding(padding: effectivePadding, child: child),
        ),
      );
    }

    final decoration = BoxDecoration(
      color: surface,
      borderRadius: radius.resolve(Directionality.of(context)),
      boxShadow: shadows,
    );

    if (onTap != null) {
      return DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius.resolve(Directionality.of(context)),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius.resolve(Directionality.of(context)),
            child: Padding(padding: effectivePadding, child: child),
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: decoration,
      child: content,
    );
  }
}
