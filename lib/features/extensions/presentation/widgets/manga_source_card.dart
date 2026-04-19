import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extensions_controllers.dart';

/// Cover-dominant discovery card for manga and manhwa sources.
class MangaSourceCard extends ConsumerWidget {
  /// Creates a manga source card.
  const MangaSourceCard({
    super.key,
    required this.item,
    required this.onPressed,
    this.genres = const <String>[],
  });

  /// Extension item to render.
  final ExtensionItem item;

  /// Callback for opening the extension details screen.
  final VoidCallback onPressed;

  /// Optional genre tags shown beneath the title.
  final List<String> genres;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<void> actionState = ref.watch(
      extensionActionControllerProvider,
    );

    final bool isTrusted = item.trustStatus == ExtensionTrustStatus.trusted;
    final bool hasInstallArtifact = item.installArtifact?.isNotEmpty ?? false;
    final bool isBusy = actionState.isLoading;

    return AppCard.featured(
      onTap: onPressed,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SourceCoverArt(name: item.name, imageUrl: item.iconUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _MangaSourceCardBody(
              item: item,
              genres: genres,
              isTrusted: isTrusted,
              hasInstallArtifact: hasInstallArtifact,
              isBusy: isBusy,
              onTrust: () {
                ref
                    .read(extensionActionControllerProvider.notifier)
                    .trust(item.packageName);
              },
              onInstall: () {
                ref
                    .read(extensionActionControllerProvider.notifier)
                    .install(
                      item.packageName,
                      installArtifact: item.installArtifact,
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MangaSourceCardBody extends StatelessWidget {
  const _MangaSourceCardBody({
    required this.item,
    required this.genres,
    required this.isTrusted,
    required this.hasInstallArtifact,
    required this.isBusy,
    required this.onTrust,
    required this.onInstall,
  });

  final ExtensionItem item;
  final List<String> genres;
  final bool isTrusted;
  final bool hasInstallArtifact;
  final bool isBusy;
  final VoidCallback onTrust;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    item.packageName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _TrustMark(
              isTrusted: isTrusted,
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            _GenreTag(label: item.language.toUpperCase()),
            _GenreTag(label: item.versionName),
            ...genres.take(1).map((String genre) => _GenreTag(label: genre)),
            if (item.isNsfw)
              const _GenreTag(
                label: AppStrings.nsfw,
                variant: AppTagVariant.warning,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _SubtleStatusText(item: item, isTrusted: isTrusted),
            TextButton.icon(
              onPressed: isBusy
                  ? null
                  : !isTrusted && hasInstallArtifact
                  ? onInstall
                  : isTrusted
                  ? onInstall
                  : onTrust,
              icon: Icon(
                !isTrusted && hasInstallArtifact
                    ? Ionicons.download_outline
                    : isTrusted
                    ? (item.hasUpdate
                          ? Ionicons.refresh_outline
                          : Ionicons.download_outline)
                    : Ionicons.shield_checkmark_outline,
              ),
              label: Text(
                _actionLabel(
                  isTrusted: isTrusted,
                  hasUpdate: item.hasUpdate,
                  hasInstallArtifact: hasInstallArtifact,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _actionLabel({
    required bool isTrusted,
    required bool hasUpdate,
    required bool hasInstallArtifact,
  }) {
    if (!isTrusted) {
      return hasInstallArtifact
          ? AppStrings.install
          : AppStrings.trustAndEnable;
    }

    return hasUpdate ? AppStrings.update : AppStrings.install;
  }
}

class _SourceCoverArt extends StatelessWidget {
  const _SourceCoverArt({required this.name, required this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl == null || imageUrl!.isEmpty
            ? ColoredBox(
                color: colorScheme.primaryContainer,
                child: _FallbackCover(name: name),
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder:
                    (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return ColoredBox(
                        color: colorScheme.primaryContainer,
                        child: _FallbackCover(name: name),
                      );
                    },
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
                        color: colorScheme.primaryContainer,
                        child: _FallbackCover(name: name),
                      );
                    },
              ),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Text(
        _initial(name),
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  String _initial(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.substring(0, 1).toUpperCase();
  }
}

class _GenreTag extends StatelessWidget {
  const _GenreTag({required this.label, this.variant = AppTagVariant.neutral});

  final String label;
  final AppTagVariant variant;

  @override
  Widget build(BuildContext context) {
    return AppTag(label: label, variant: variant);
  }
}

class _TrustMark extends StatelessWidget {
  const _TrustMark({
    required this.isTrusted,
    required this.colorScheme,
    required this.textTheme,
  });

  final bool isTrusted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isTrusted
                ? Ionicons.shield_checkmark
                : Ionicons.alert_circle_outline,
            size: 12,
            color: isTrusted ? colorScheme.primary : colorScheme.tertiary,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            isTrusted ? AppStrings.trusted : AppStrings.untrusted,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtleStatusText extends StatelessWidget {
  const _SubtleStatusText({required this.item, required this.isTrusted});

  final ExtensionItem item;
  final bool isTrusted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String statusText = !isTrusted
        ? AppStrings.trustAndEnable
        : item.hasUpdate
        ? AppStrings.updateAvailable
        : AppStrings.install;

    return Text(
      statusText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
