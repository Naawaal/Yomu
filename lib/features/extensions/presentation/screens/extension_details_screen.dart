import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extension_detail_provider.dart';
import '../controllers/extensions_controllers.dart';
import '../widgets/extension_action_buttons.dart';
import '../widgets/extension_trust_chip.dart';
import '../widgets/nsfw_warning_banner.dart';
import '../widgets/update_banner.dart';

/// Full detail screen for a single extension.
class ExtensionDetailsScreen extends ConsumerWidget {
  /// Creates extension details screen.
  const ExtensionDetailsScreen({super.key, required this.packageName});

  /// Android package name for the extension to display.
  final String packageName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ExtensionItem?> asyncItem = ref.watch(
      extensionDetailProvider(packageName),
    );
    final AsyncValue<void> actionState = ref.watch(
      extensionActionControllerProvider,
    );

    ref.listen<AsyncValue<void>>(extensionActionControllerProvider, (
      _,
      AsyncValue<void> next,
    ) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_actionErrorMessage(next.error!))),
        );
      }
    });

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isExpanded =
              constraints.maxWidth >= ScreenBreakpoints.medium;
          final double maxContentWidth = isExpanded
              ? ScreenBreakpoints.medium + (ScreenBreakpoints.compact / 2)
              : constraints.maxWidth;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: maxContentWidth,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverAppBar.medium(
                    title: asyncItem.maybeWhen(
                      data: (ExtensionItem? item) =>
                          Text(item?.name ?? AppStrings.extensionDetailsTitle),
                      orElse: () =>
                          const Text(AppStrings.extensionDetailsTitle),
                    ),
                  ),
                  SliverPadding(
                    padding: InsetsTokens.page,
                    sliver: asyncItem.when(
                      loading: () => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _DetailLoadingState(),
                      ),
                      error: (Object error, StackTrace _) =>
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _DetailStateSurface(
                              child: ErrorState(
                                title: AppStrings.unableToLoadApp,
                                message: error.toString(),
                                retryLabel: AppStrings.retry,
                                onRetry: () => ref
                                    .read(
                                      extensionsListControllerProvider.notifier,
                                    )
                                    .refresh(),
                              ),
                            ),
                          ),
                      data: (ExtensionItem? item) {
                        if (item == null) {
                          return const SliverFillRemaining(
                            hasScrollBody: false,
                            child: _DetailStateSurface(
                              child: EmptyState(
                                title: AppStrings.extensionNotFound,
                                description: AppStrings.noExtensionsBody,
                                icon: Ionicons.search_outline,
                              ),
                            ),
                          );
                        }
                        return _DetailBody(
                          item: item,
                          actionState: actionState,
                          isExpanded: isExpanded,
                          onTrust: () => ref
                              .read(extensionActionControllerProvider.notifier)
                              .trust(item.packageName),
                          onInstall: () => ref
                              .read(extensionActionControllerProvider.notifier)
                              .install(
                                item.packageName,
                                installArtifact: item.installArtifact,
                              ),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppSpacing.xl),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _actionErrorMessage(Object error) {
  if (error is PlatformException) {
    return error.message ?? 'Action failed.';
  }

  final String raw = error.toString();
  const String exceptionPrefix = 'Exception: ';
  if (raw.startsWith(exceptionPrefix)) {
    return raw.substring(exceptionPrefix.length);
  }
  return raw;
}

// ---------------------------------------------------------------------------
// Detail body
// ---------------------------------------------------------------------------

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.item,
    required this.actionState,
    required this.isExpanded,
    required this.onTrust,
    required this.onInstall,
  });

  final ExtensionItem item;
  final AsyncValue<void> actionState;
  final bool isExpanded;
  final VoidCallback onTrust;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final bool isTrusted = item.trustStatus == ExtensionTrustStatus.trusted;
    final bool isLoading = actionState.isLoading;

    if (!isExpanded) {
      return SliverList.list(
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          _DetailHeroCard(
            item: item,
            isTrusted: isTrusted,
            isLoading: isLoading,
            onTrust: onTrust,
            onInstall: onInstall,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (item.isNsfw) ...<Widget>[
            const NsfwWarningBanner(),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (item.hasUpdate) ...<Widget>[
            UpdateBanner(
              versionName: item.versionName,
              isLoading: isLoading,
              onUpdate: onInstall,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          _MetadataCard(item: item),
          const SizedBox(height: AppSpacing.xxl),
        ],
      );
    }

    return SliverList.list(
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        _DetailHeroCard(
          item: item,
          isTrusted: isTrusted,
          isLoading: isLoading,
          onTrust: onTrust,
          onInstall: onInstall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 7,
              child: _DetailInfoColumn(
                item: item,
                isLoading: isLoading,
                onInstall: onInstall,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(flex: 5, child: _MetadataCard(item: item)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _DetailInfoColumn extends StatelessWidget {
  const _DetailInfoColumn({
    required this.item,
    required this.isLoading,
    required this.onInstall,
  });

  final ExtensionItem item;
  final bool isLoading;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    if (!item.isNsfw && !item.hasUpdate) {
      return const SizedBox.shrink();
    }

    return Column(
      children: <Widget>[
        if (item.isNsfw) ...<Widget>[
          const NsfwWarningBanner(),
          if (item.hasUpdate) const SizedBox(height: AppSpacing.lg),
        ],
        if (item.hasUpdate)
          UpdateBanner(
            versionName: item.versionName,
            isLoading: isLoading,
            onUpdate: onInstall,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card
// ---------------------------------------------------------------------------

class _DetailHeroCard extends StatelessWidget {
  const _DetailHeroCard({
    required this.item,
    required this.isTrusted,
    required this.isLoading,
    required this.onTrust,
    required this.onInstall,
  });

  final ExtensionItem item;
  final bool isTrusted;
  final bool isLoading;
  final VoidCallback onTrust;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard.featured(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ExtensionHeroArtwork(name: item.name, iconUrl: item.iconUrl),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item.name, style: textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.packageName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          ExtensionTrustChip(trusted: isTrusted),
                          _DetailMetaChip(
                            label:
                                '${AppStrings.languageLabel}: ${item.language.toUpperCase()}',
                          ),
                          _DetailMetaChip(
                            label:
                                '${AppStrings.versionLabel}: ${item.versionName}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isTrusted
                          ? AppStrings.trusted
                          : AppStrings.trustAndEnable,
                      style: textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${AppStrings.versionLabel}: ${item.versionName}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ExtensionActionButtons(
                      item: item,
                      isLoading: isLoading,
                      onTrust: onTrust,
                      onInstall: onInstall,
                      fullWidth: true,
                      showInstallWhenUpToDate: false,
                    ),
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

class _DetailMetaChip extends StatelessWidget {
  const _DetailMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ExtensionHeroArtwork extends StatelessWidget {
  const _ExtensionHeroArtwork({required this.name, required this.iconUrl});

  final String name;
  final String? iconUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 88,
        height: 88,
        child: iconUrl == null || iconUrl!.isEmpty
            ? ColoredBox(
                color: colorScheme.primaryContainer,
                child: _HeroArtworkFallback(name: name),
              )
            : Image.network(
                iconUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colorScheme.primaryContainer,
                  child: _HeroArtworkFallback(name: name),
                ),
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
                        child: _HeroArtworkFallback(name: name),
                      );
                    },
              ),
      ),
    );
  }
}

class _HeroArtworkFallback extends StatelessWidget {
  const _HeroArtworkFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().substring(0, 1).toUpperCase(),
        style: textTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Metadata card
// ---------------------------------------------------------------------------

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.item});

  final ExtensionItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard.featured(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              AppStrings.packageLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Ionicons.pricetag_outline),
              title: SelectableText(
                item.packageName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: IconButton(
                icon: const Icon(Ionicons.copy_outline),
                tooltip: 'Copy package name',
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: item.packageName)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Ionicons.language_outline),
              title: const Text(AppStrings.languageLabel),
              trailing: Text(
                item.language.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Ionicons.information_circle_outline),
              title: const Text(AppStrings.versionLabel),
              trailing: Text(
                item.versionName,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState();

  @override
  Widget build(BuildContext context) {
    final Color skeletonColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest;

    return _DetailStateSurface(
      child: LoadingShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const SizedBox(height: AppSpacing.xxxl + AppSpacing.xl),
            ),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const SizedBox(height: AppSpacing.xxxl),
            ),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const SizedBox(height: AppSpacing.xxxl),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStateSurface extends StatelessWidget {
  const _DetailStateSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard.featured(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
