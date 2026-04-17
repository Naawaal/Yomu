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
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.medium(
            title: asyncItem.maybeWhen(
              data: (ExtensionItem? item) =>
                  Text(item?.name ?? AppStrings.extensionDetailsTitle),
              orElse: () => const Text(AppStrings.extensionDetailsTitle),
            ),
          ),
          SliverPadding(
            padding: InsetsTokens.page,
            sliver: asyncItem.when(
              loading: () =>
                  const SliverFillRemaining(child: _DetailLoadingState()),
              error: (Object error, StackTrace _) => SliverFillRemaining(
                child: ErrorState(
                  title: AppStrings.unableToLoadApp,
                  message: error.toString(),
                  retryLabel: AppStrings.retry,
                  onRetry: () => ref
                      .read(extensionsListControllerProvider.notifier)
                      .refresh(),
                ),
              ),
              data: (ExtensionItem? item) {
                if (item == null) {
                  return const SliverFillRemaining(
                    child: EmptyState(
                      title: AppStrings.extensionNotFound,
                      description: AppStrings.noExtensionsBody,
                      icon: Ionicons.search_outline,
                    ),
                  );
                }
                return _DetailBody(
                  item: item,
                  actionState: actionState,
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
        ],
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
    required this.onTrust,
    required this.onInstall,
  });

  final ExtensionItem item;
  final AsyncValue<void> actionState;
  final VoidCallback onTrust;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    final bool isTrusted = item.trustStatus == ExtensionTrustStatus.trusted;
    final bool isLoading = actionState.isLoading;

    return SliverList.list(
      children: <Widget>[
        const SizedBox(height: AppSpacing.xs),
        // -- Header card --
        _HeaderCard(item: item, isTrusted: isTrusted),
        const SizedBox(height: AppSpacing.md),
        // -- Conditional banners --
        if (item.isNsfw) ...<Widget>[
          const NsfwWarningBanner(),
          const SizedBox(height: AppSpacing.md),
        ],
        if (item.hasUpdate) ...<Widget>[
          UpdateBanner(
            versionName: item.versionName,
            isLoading: isLoading,
            onUpdate: onInstall,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // -- Metadata card --
        _MetadataCard(item: item),
        const SizedBox(height: AppSpacing.md),
        // -- Primary action --
        ExtensionActionButtons(
          item: item,
          isLoading: isLoading,
          onTrust: onTrust,
          onInstall: onInstall,
          fullWidth: true,
          showInstallWhenUpToDate: false,
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item, required this.isTrusted});

  final ExtensionItem item;
  final bool isTrusted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            backgroundColor: colorScheme.tertiaryContainer,
            child: Icon(
              Ionicons.extension_puzzle_outline,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: <Widget>[
                    Chip(
                      label: Text(item.language.toUpperCase()),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      padding: EdgeInsets.zero,
                    ),
                    Chip(
                      label: Text(item.versionName),
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ExtensionTrustChip(trusted: isTrusted),
              ],
            ),
          ),
        ],
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
    return AppCard(
      child: Column(
        children: <Widget>[
          ListTile(
            leading: const Icon(Ionicons.pricetag_outline),
            title: const Text(AppStrings.packageLabel),
            subtitle: SelectableText(
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
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Ionicons.language_outline),
            title: const Text(AppStrings.languageLabel),
            trailing: Text(
              item.language.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Ionicons.information_circle_outline),
            title: const Text(AppStrings.versionLabel),
            trailing: Text(
              item.versionName,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
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

    return Padding(
      padding: InsetsTokens.page,
      child: LoadingShimmer(
        child: Column(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const SizedBox(height: AppSpacing.xxxl),
            ),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const SizedBox(height: AppSpacing.xxxl),
            ),
          ],
        ),
      ),
    );
  }
}
