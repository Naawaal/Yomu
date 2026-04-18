import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors_extension.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/entities/feed_item.dart';

/// High-fidelity feed list item card matching design spec.
///
/// Layout:
/// - AppCard (elevation: 0, backgroundColor: surfaceContainerLow, borderRadius: md, padding: md)
///   - Column:
///     - Row (source icon + name + date)
///     - Title (headlineSmall, max 2 lines)
///     - Description (bodyMedium, max 2 lines)
///     - Row (tags left, icon button right)
///
/// Uses all design tokens from theme (no hardcoded colors/spacing).
class FeedCardWidget extends StatelessWidget {
  /// Creates a feed card widget.
  const FeedCardWidget({super.key, required this.item, required this.onTap});

  /// The feed item to display.
  final FeedItem item;

  /// Callback when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AppColorsExtension appColors = Theme.of(
      context,
    ).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: AppSpacing.xl,
                      height: AppSpacing.xl,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.isBookmarked
                            ? Ionicons.checkmark_done_outline
                            : Ionicons.sparkles_outline,
                        size: AppSpacing.md,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.metadata,
                        style: textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppTag(
                      label: item.isBookmarked
                          ? AppStrings.feedStatusRead
                          : AppStrings.feedStatusLive,
                      variant: item.isBookmarked
                          ? AppTagVariant.neutral
                          : AppTagVariant.success,
                      leadingIcon: Icon(
                        item.isBookmarked
                            ? Ionicons.checkmark_outline
                            : Ionicons.flash_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _FeedArtwork(imageUrl: item.imageUrl),
                const SizedBox(height: AppSpacing.md),
                Text(
                  item.title,
                  style: textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Text(
                      item.metadata,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppTag(
                      label: item.metadata,
                      variant: AppTagVariant.warning,
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: appColors.infoContainer,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Ionicons.arrow_forward_outline,
                          color: appColors.onInfoContainer,
                        ),
                        onPressed: onTap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedArtwork extends StatelessWidget {
  const _FeedArtwork({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final BorderRadius borderRadius = BorderRadius.circular(AppRadius.md);
    final double artworkHeight = AppSpacing.xxl * 3;

    if (imageUrl.isEmpty) {
      return Container(
        height: artworkHeight,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: borderRadius,
        ),
        alignment: Alignment.center,
        child: Icon(
          Ionicons.image_outline,
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: artworkHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder:
                  (
                    BuildContext context,
                    Widget child,
                    ImageChunkEvent? loadingProgress,
                  ) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: const Center(
                        child: SizedBox.square(dimension: AppSpacing.lg),
                      ),
                    );
                  },
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                    return ColoredBox(
                      color: colorScheme.surfaceContainerHigh,
                      child: Center(
                        child: Icon(
                          Ionicons.image_outline,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    colorScheme.scrim.withValues(alpha: 0.05),
                    colorScheme.scrim.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
