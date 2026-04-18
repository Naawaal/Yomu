import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer wrapper for loading skeletons.
///
/// Sweeps from [colorScheme.surfaceContainerHighest] (base) to
/// [colorScheme.surface] (highlight) — dark→light direction.
/// Pass a child widget tree whose shape matches the real content.
class LoadingShimmer extends StatelessWidget {
  /// Creates a [LoadingShimmer].
  const LoadingShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
  });

  /// Skeleton widget tree to animate.
  final Widget child;

  /// Animation period — defaults to 1 400 ms per design_system.json.
  final Duration period;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surface,
      period: period,
      child: child,
    );
  }
}
