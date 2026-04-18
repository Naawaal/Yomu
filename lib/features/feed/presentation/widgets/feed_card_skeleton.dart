import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// Shimmer skeleton matching FeedCardWidget layout for loading states.
///
/// Renders a skeleton with the same structure as FeedCardWidget:
/// - Header row (icon + name + date)
/// - Title (2-line shimmer)
/// - Description (2-line shimmer)
/// - Footer (icon button placeholder)
class FeedCardSkeleton extends StatelessWidget {
  /// Creates a feed card skeleton.
  const FeedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color skeletonColor = colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header row skeleton
              Row(
                children: <Widget>[
                  // Icon container
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const SizedBox(
                      width: AppSpacing.xl,
                      height: AppSpacing.xl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Source name line
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const SizedBox(height: AppSpacing.md),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Status tag line
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const SizedBox(
                      width: AppSpacing.xxl,
                      height: AppSpacing.md,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  height: AppSpacing.xxl,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Title skeleton (2 lines)
              Column(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const SizedBox(
                      height: AppSpacing.lg,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const FractionallySizedBox(
                      widthFactor: 0.65,
                      child: SizedBox(height: AppSpacing.lg),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              // Description skeleton (2 lines)
              Column(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const SizedBox(
                      height: AppSpacing.md,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const FractionallySizedBox(
                      widthFactor: 0.45,
                      child: SizedBox(height: AppSpacing.md),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const SizedBox(
                      width: AppSpacing.xxl,
                      height: AppSpacing.md,
                    ),
                  ),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const SizedBox(
                      width: AppSpacing.xl,
                      height: AppSpacing.xl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
