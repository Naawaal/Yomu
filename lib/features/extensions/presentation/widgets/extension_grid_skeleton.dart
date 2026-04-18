import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';

/// Shimmer skeleton grid for extension cards matching ExtensionTile layout.
///
/// Renders a responsive grid skeleton with proper aspect ratio and spacing:
/// - Icon placeholder (64px square)
/// - Name line
/// - Package name line
/// - Tags (language, version, trust status)
/// - Action button placeholder
class ExtensionGridSkeleton extends StatelessWidget {
  /// Creates an extension grid skeleton.
  const ExtensionGridSkeleton({
    super.key,
    this.crossAxisCount = 2,
    this.itemCount = 4,
  });

  /// Number of columns in the grid.
  final int crossAxisCount;

  /// Number of skeleton items to render.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color skeletonColor = colorScheme.surfaceContainerHighest;

    return LoadingShimmer(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.2,
        ),
        itemCount: itemCount,
        itemBuilder: (BuildContext context, int index) {
          return _ExtensionGridSkeletonItem(skeletonColor: skeletonColor);
        },
      ),
    );
  }
}

class _ExtensionGridSkeletonItem extends StatelessWidget {
  const _ExtensionGridSkeletonItem({required this.skeletonColor});

  final Color skeletonColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            // Icon placeholder (64px square)
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const SizedBox(
                width: AppSpacing.xxl,
                height: AppSpacing.xxl,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Name line
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const SizedBox(height: 16, width: double.infinity),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Package name line
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const SizedBox(height: 12, width: 120),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Tags skeleton (3 small tags)
                  Row(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const SizedBox(width: 30, height: 16),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const SizedBox(width: 40, height: 16),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: skeletonColor,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const SizedBox(width: 50, height: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Action button placeholder
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const SizedBox(width: 24, height: 24),
            ),
          ],
        ),
      ),
    );
  }
}
