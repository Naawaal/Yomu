import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../feed/domain/entities/feed_item.dart';
import '../../../library/domain/entities/library_entry.dart';

/// Hero section for the Home feed surface.
///
/// Combines a full-width featured banner, a horizontal continue-reading rail,
/// and the handoff header for the latest-from-sources section.
class HomeHeroSection extends StatelessWidget {
  /// Creates a home hero section.
  const HomeHeroSection({
    super.key,
    required this.featuredItem,
    required this.continueReadingEntries,
    this.onResumeEntry,
    this.onOpenFeatured,
  });

  /// Spotlight item used for the featured banner.
  final FeedItem featuredItem;

  /// Continue-reading entries shown in the horizontal rail.
  final List<LibraryEntry> continueReadingEntries;

  /// Optional callback for tapping a continue-reading entry.
  final ValueChanged<LibraryEntry>? onResumeEntry;

  /// Optional callback for opening the featured banner.
  final VoidCallback? onOpenFeatured;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasContinueReading = continueReadingEntries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _FeaturedBanner(
          featuredItem: featuredItem,
          hasContinueReading: hasContinueReading,
          onOpenFeatured: onOpenFeatured,
          onResumeFirst: hasContinueReading && onResumeEntry != null
              ? () => onResumeEntry!(continueReadingEntries.first)
              : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(AppStrings.feedContinueWatchingLabel, style: textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        if (hasContinueReading)
          SizedBox(
            height: 236,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: continueReadingEntries.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (BuildContext context, int index) {
                final LibraryEntry entry = continueReadingEntries[index];
                return SizedBox(
                  width: 154,
                  child: _ContinueReadingCard(
                    entry: entry,
                    onTap: onResumeEntry == null
                        ? null
                        : () => onResumeEntry!(entry),
                  ),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              AppStrings.homeContinueReadingFallback,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                AppStrings.feedLatestFromSourcesLabel,
                style: textTheme.titleLarge,
              ),
            ),
            Icon(
              Ionicons.chevron_forward_outline,
              size: AppSpacing.lg,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({
    required this.featuredItem,
    required this.hasContinueReading,
    this.onOpenFeatured,
    this.onResumeFirst,
  });

  final FeedItem featuredItem;
  final bool hasContinueReading;
  final VoidCallback? onOpenFeatured;
  final VoidCallback? onResumeFirst;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard.featured(
      padding: EdgeInsets.zero,
      onTap: onOpenFeatured,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 246,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              _FeaturedBannerArt(imageUrl: featuredItem.imageUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      colorScheme.scrim.withValues(alpha: 0.04),
                      colorScheme.scrim.withValues(alpha: 0.42),
                      colorScheme.surface.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            AppStrings.feedFeaturedNowLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (hasContinueReading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Text(
                              AppStrings.homeResume,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      featuredItem.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      featuredItem.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            featuredItem.metadata,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (onResumeFirst != null)
                          FilledButton.icon(
                            onPressed: onResumeFirst,
                            icon: const Icon(Ionicons.play),
                            label: const Text(AppStrings.homeResume),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedBannerArt extends StatelessWidget {
  const _FeaturedBannerArt({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return imageUrl.isEmpty
        ? ColoredBox(color: colorScheme.surfaceContainerHighest)
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                ColoredBox(color: colorScheme.surfaceContainerHighest),
          );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.entry, this.onTap});

  final LibraryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int percent = (entry.progress * 100).round();

    return AppCard.featured(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              height: 108,
              width: double.infinity,
              child: entry.coverImageUrl.isEmpty
                  ? ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: Center(
                        child: Text(
                          entry.title.substring(0, 1).toUpperCase(),
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      entry.coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            entry.title.substring(0, 1).toUpperCase(),
                            style: textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Chapter ${entry.currentChapter} of ${entry.latestChapter}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: entry.progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$percent% complete',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
