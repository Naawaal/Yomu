import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/feed_item.dart';
import '../providers/feed_notifier.dart';

/// Content card for individual feed items.
///
/// Layout:
/// - Image: 64x64, rounded corners (AppRadius.sm)
/// - Title: titleMedium, 2 lines max
/// - Subtitle: bodySmall, 2 lines max
/// - Metadata: labelSmall, onSurfaceVariant color
/// - Bookmark action: icon button, toggles on tap
///
/// Uses design system tokens exclusively (colorScheme, textTheme, AppSpacing, AppRadius).
class FeedContentCard extends ConsumerWidget {
  const FeedContentCard({super.key, required this.item, this.onTap});

  final FeedItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 64,
                height: 64,
                child: item.imageUrl.isEmpty
                    ? ColoredBox(
                        color: colorScheme.surfaceContainerHigh,
                        child: Icon(
                          Ionicons.image_outline,
                          color: colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      )
                    : Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (
                              BuildContext context,
                              Object error,
                              StackTrace? stackTrace,
                            ) => ColoredBox(
                              color: colorScheme.surfaceContainerHigh,
                            ),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Bookmark action
            Column(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    if (item.isBookmarked) {
                      ref
                          .read(feedNotifierProvider.notifier)
                          .unbookmark(item.id);
                    } else {
                      ref.read(feedNotifierProvider.notifier).bookmark(item.id);
                    }
                  },
                  icon: Icon(
                    item.isBookmarked
                        ? Ionicons.bookmark
                        : Ionicons.bookmark_outline,
                    color: item.isBookmarked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
