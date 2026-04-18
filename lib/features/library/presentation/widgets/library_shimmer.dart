import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';

/// Shimmer skeleton for Library list loading state.
class LibraryShimmer extends StatelessWidget {
  const LibraryShimmer({super.key, required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return LoadingShimmer(
      child: Padding(
        padding: InsetsTokens.page,
        child: Column(
          children: List<Widget>.generate(itemCount, (int index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == itemCount - 1 ? 0 : AppSpacing.md,
              ),
              child: Container(
                height: 136,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
