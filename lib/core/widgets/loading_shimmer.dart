import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Reusable shimmer wrapper for loading skeletons.
class LoadingShimmer extends StatelessWidget {
  /// Creates a [LoadingShimmer].
  const LoadingShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
  });

  /// Skeleton widget tree to animate.
  final Widget child;

  /// Animation period.
  final Duration period;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest,
      highlightColor: colorScheme.surfaceContainer,
      period: period,
      child: child,
    );
  }
}
