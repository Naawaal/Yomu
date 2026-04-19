import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../feed/domain/entities/feed_item.dart';
import '../../../library/domain/entities/library_entry.dart';

/// Featured hero card for continue-reading context on Home Feed tab.
class HomeContinueReadingHero extends StatelessWidget {
  const HomeContinueReadingHero({
    super.key,
    this.entry,
    this.fallbackItem,
    this.onResume,
  });

  final LibraryEntry? entry;
  final FeedItem? fallbackItem;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String title =
        entry?.title ??
        fallbackItem?.title ??
        AppStrings.homeContinueReadingLabel;
    final String subtitle = _subtitle();
    final String progressLabel = _progressLabel();

    return AppCard.featured(
      child: Row(
        children: <Widget>[
          Container(
            width: 96,
            height: 132,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(
              Ionicons.play_circle,
              color: colorScheme.onPrimaryContainer,
              size: AppSpacing.xxl,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    AppStrings.homeContinueReadingLabel,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
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
                    value: entry?.progress ?? 0.0,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  progressLabel,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: onResume ?? () {},
                  icon: const Icon(Ionicons.play),
                  label: const Text(AppStrings.homeResume),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    if (entry != null) {
      return 'Chapter ${entry!.currentChapter} of ${entry!.latestChapter}';
    }
    return fallbackItem?.subtitle ?? AppStrings.homeContinueReadingFallback;
  }

  String _progressLabel() {
    if (entry == null) {
      return AppStrings.homeProgressUnavailable;
    }

    final int percent = (entry!.progress * 100).round();
    return '$percent% complete';
  }
}
