import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../domain/entities/extension_item.dart';
import '../controllers/extensions_controllers.dart';
import '../widgets/extension_grid_skeleton.dart';
import '../widgets/manga_source_card.dart';

final _extensionsSearchQueryProvider = StateProvider.autoDispose<String>(
  (Ref ref) => '',
);

final _extensionsLanguageFilterProvider = StateProvider.autoDispose<String?>(
  (Ref ref) => null,
);

const double _extensionsSearchHeaderHeight = AppSpacing.xxxl;
const double _extensionsFilterHeaderHeight = AppSpacing.xxxl;

/// Screen that lists available extensions.
class ExtensionsStoreScreen extends ConsumerWidget {
  /// Creates extensions store screen.
  const ExtensionsStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ExtensionItem>> asyncExtensions = ref.watch(
      extensionsListControllerProvider,
    );
    final String searchQuery = ref.watch(_extensionsSearchQueryProvider);
    final String normalizedQuery = searchQuery.trim().toLowerCase();
    final String? selectedLanguage = ref.watch(
      _extensionsLanguageFilterProvider,
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool isExpanded =
              constraints.maxWidth >= ScreenBreakpoints.medium;
          final int crossAxisCount = isExpanded ? 2 : 1;
          final double childAspectRatio = isExpanded ? 1.9 : 1.7;

          return CustomScrollView(
            slivers: <Widget>[
              SliverAppBar.medium(
                title: const Text(AppStrings.extensionsTitle),
                actions: <Widget>[
                  IconButton(
                    onPressed: () {
                      ref
                          .read(extensionsListControllerProvider.notifier)
                          .refresh();
                    },
                    icon: const Icon(Ionicons.refresh_outline),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                sliver: SliverToBoxAdapter(
                  child: _ExtensionsHeroSection(isExpanded: isExpanded),
                ),
              ),
              const SliverPersistentHeader(
                pinned: true,
                delegate: _ExtensionsPinnedHeaderDelegate(
                  height: _extensionsSearchHeaderHeight,
                  child: _ExtensionsSearchHeader(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _ExtensionsPinnedHeaderDelegate(
                  height: _extensionsFilterHeaderHeight,
                  child: _ExtensionsLanguageFilters(
                    languages: asyncExtensions.maybeWhen(
                      data: _extractLanguages,
                      orElse: () => const <String>[],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: InsetsTokens.page,
                sliver: asyncExtensions.when(
                  loading: () => SliverToBoxAdapter(
                    child: _ExtensionsLoadingState(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                    ),
                  ),
                  error: (Object error, StackTrace stackTrace) =>
                      SliverToBoxAdapter(
                        child: _ExtensionsStateSurface(
                          child: ErrorState(
                            title: AppStrings.unableToLoadApp,
                            message: error.toString(),
                            retryLabel: AppStrings.retry,
                            onRetry: () {
                              ref
                                  .read(
                                    extensionsListControllerProvider.notifier,
                                  )
                                  .refresh();
                            },
                          ),
                        ),
                      ),
                  data: (List<ExtensionItem> items) {
                    final List<ExtensionItem> filteredItems = items
                        .where((ExtensionItem item) {
                          final bool matchesLanguage =
                              selectedLanguage == null ||
                              item.language == selectedLanguage;
                          final bool matchesQuery =
                              normalizedQuery.isEmpty ||
                              item.name.toLowerCase().contains(
                                normalizedQuery,
                              ) ||
                              item.packageName.toLowerCase().contains(
                                normalizedQuery,
                              ) ||
                              item.language.toLowerCase().contains(
                                normalizedQuery,
                              );

                          return matchesLanguage && matchesQuery;
                        })
                        .toList(growable: false);
                    final List<ExtensionItem> updateItems = filteredItems
                        .where((ExtensionItem item) => item.hasUpdate)
                        .toList(growable: false);
                    final Set<String> updatePackages = updateItems
                        .map((ExtensionItem item) => item.packageName)
                        .toSet();
                    final List<ExtensionItem> trustedItems = filteredItems
                        .where((ExtensionItem item) {
                          return item.trustStatus ==
                                  ExtensionTrustStatus.trusted &&
                              !item.hasUpdate;
                        })
                        .toList(growable: false);
                    final List<ExtensionItem> installReadyItems = trustedItems;
                    final List<ExtensionItem> remainingItems = filteredItems
                        .where((ExtensionItem item) {
                          return item.trustStatus !=
                                  ExtensionTrustStatus.trusted &&
                              !updatePackages.contains(item.packageName);
                        })
                        .toList(growable: false);

                    if (items.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _ExtensionsStateSurface(
                          child: EmptyState(
                            title: AppStrings.noExtensionsTitle,
                            description: AppStrings.noExtensionsBody,
                            actionLabel: AppStrings.retry,
                            onAction: () {
                              ref
                                  .read(
                                    extensionsListControllerProvider.notifier,
                                  )
                                  .refresh();
                            },
                            icon: Ionicons.search_outline,
                          ),
                        ),
                      );
                    }

                    if (filteredItems.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: _ExtensionsStateSurface(
                          child: EmptyState(
                            title: AppStrings.noExtensionsTitle,
                            description: AppStrings.noExtensionsBody,
                            icon: Ionicons.search_outline,
                          ),
                        ),
                      );
                    }

                    return _ExtensionCatalogSections(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      sections: <_ExtensionCatalogSectionData>[
                        if (updateItems.isNotEmpty)
                          _ExtensionCatalogSectionData(
                            title: AppStrings.extensionsRecentlyUpdated,
                            items: updateItems,
                          ),
                        if (installReadyItems.isNotEmpty)
                          _ExtensionCatalogSectionData(
                            title: AppStrings.extensionsTrustedRecommendations,
                            items: installReadyItems,
                          ),
                        if (remainingItems.isNotEmpty)
                          _ExtensionCatalogSectionData(
                            title: AppStrings.extensionsMoreSources,
                            items: remainingItems,
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          );
        },
      ),
    );
  }
}

List<String> _extractLanguages(List<ExtensionItem> items) {
  final List<String> languages =
      items
          .map((ExtensionItem item) => item.language)
          .toSet()
          .toList(growable: false)
        ..sort();
  return languages;
}

class _ExtensionsSearchHeader extends ConsumerStatefulWidget {
  const _ExtensionsSearchHeader();

  @override
  ConsumerState<_ExtensionsSearchHeader> createState() =>
      _ExtensionsSearchHeaderState();
}

class _ExtensionsSearchHeaderState
    extends ConsumerState<_ExtensionsSearchHeader> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(_extensionsSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = ref.watch(_extensionsSearchQueryProvider);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AppTextInput(
      controller: _controller,
      hint: AppStrings.extensionsSearchHint,
      leadingIcon: Icon(
        Ionicons.search_outline,
        color: colorScheme.onSurfaceVariant,
      ),
      trailingWidget: query.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                _controller.clear();
                ref.read(_extensionsSearchQueryProvider.notifier).state = '';
              },
              icon: Icon(
                Ionicons.close_circle_outline,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
      onChanged: (String value) {
        ref.read(_extensionsSearchQueryProvider.notifier).state = value;
      },
    );
  }
}

class _ExtensionsLanguageFilters extends ConsumerWidget {
  const _ExtensionsLanguageFilters({required this.languages});

  final List<String> languages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? selectedLanguage = ref.watch(
      _extensionsLanguageFilterProvider,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          FilterChip(
            label: const Text(AppStrings.extensionsAllLanguages),
            selected: selectedLanguage == null,
            showCheckmark: false,
            selectedColor: Theme.of(context).colorScheme.secondaryContainer,
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            onSelected: (_) {
              ref.read(_extensionsLanguageFilterProvider.notifier).state = null;
            },
          ),
          for (final String language in languages) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            FilterChip(
              label: Text(language.toUpperCase()),
              selected: selectedLanguage == language,
              showCheckmark: false,
              selectedColor: Theme.of(context).colorScheme.secondaryContainer,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              onSelected: (bool isSelected) {
                ref.read(_extensionsLanguageFilterProvider.notifier).state =
                    isSelected ? language : null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ExtensionsStateSurface extends StatelessWidget {
  const _ExtensionsStateSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard.featured(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _ExtensionsLoadingState extends StatelessWidget {
  const _ExtensionsLoadingState({
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return LoadingShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppCard.featured(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const SizedBox(height: 20, width: 160),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: const SizedBox(height: 14, width: 240),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const SizedBox(width: 56, height: 56),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: const SizedBox(
                                height: 14,
                                width: double.infinity,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xs,
                                ),
                              ),
                              child: const SizedBox(height: 12, width: 180),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ExtensionsLoadingSectionHeader(),
          const SizedBox(height: AppSpacing.sm),
          ExtensionGridSkeleton(
            crossAxisCount: crossAxisCount,
            itemCount: crossAxisCount == 1 ? 3 : 4,
          ),
          const SizedBox(height: AppSpacing.lg),
          const _ExtensionsLoadingSectionHeader(),
          const SizedBox(height: AppSpacing.sm),
          ExtensionGridSkeleton(
            crossAxisCount: crossAxisCount,
            itemCount: crossAxisCount == 1 ? 2 : 4,
          ),
        ],
      ),
    );
  }
}

class _ExtensionsLoadingSectionHeader extends StatelessWidget {
  const _ExtensionsLoadingSectionHeader();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: const SizedBox(height: 18, width: 128),
        ),
        const SizedBox(width: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: const SizedBox(height: 18, width: 28),
        ),
      ],
    );
  }
}

class _ExtensionCatalogSectionData {
  const _ExtensionCatalogSectionData({
    required this.title,
    required this.items,
  });

  final String title;
  final List<ExtensionItem> items;
}

class _ExtensionCatalogSections extends StatelessWidget {
  const _ExtensionCatalogSections({
    required this.sections,
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  final List<_ExtensionCatalogSectionData> sections;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverMainAxisGroup(
      slivers: <Widget>[
        for (int index = 0; index < sections.length; index++) ...<Widget>[
          _ExtensionCatalogSection(
            title: sections[index].title,
            items: sections[index].items,
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
          ),
          if (index < sections.length - 1)
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        ],
      ],
    );
  }
}

class _ExtensionCatalogSection extends StatelessWidget {
  const _ExtensionCatalogSection({
    required this.title,
    required this.items,
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  final String title;
  final List<ExtensionItem> items;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Row(
            children: <Widget>[
              Text(title, style: textTheme.titleLarge),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  items.length.toString(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: childAspectRatio,
          ),
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            final ExtensionItem item = items[index];
            return MangaSourceCard(
              key: ValueKey<String>(item.packageName),
              item: item,
              onPressed: () {
                ExtensionDetailsRoute.push(context, item.packageName);
              },
              genres: const <String>[],
            );
          }, childCount: items.length),
        ),
      ],
    );
  }
}

class _ExtensionsPinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _ExtensionsPinnedHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final Color backgroundColor = Theme.of(context).colorScheme.surface;

    return ColoredBox(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Align(alignment: Alignment.centerLeft, child: child),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ExtensionsPinnedHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _ExtensionsHeroSection extends StatelessWidget {
  const _ExtensionsHeroSection({required this.isExpanded});

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return AppCard.featured(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: isExpanded
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _ExtensionsHeroCopy(
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                _ExtensionsHeroBadge(colorScheme: colorScheme),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _ExtensionsHeroCopy(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: _ExtensionsHeroBadge(colorScheme: colorScheme),
                ),
              ],
            ),
    );
  }
}

class _ExtensionsHeroCopy extends StatelessWidget {
  const _ExtensionsHeroCopy({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(AppStrings.extensionsTitle, style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.settingsExtensionsSubtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            AppTag(label: AppStrings.extensionsTrustedRecommendations),
            AppTag(label: AppStrings.extensionsInstallReady),
          ],
        ),
      ],
    );
  }
}

class _ExtensionsHeroBadge extends StatelessWidget {
  const _ExtensionsHeroBadge({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Icon(
        Ionicons.search_outline,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
